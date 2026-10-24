const admin = require('firebase-admin');

const {
    FIREBASE_SERVICE_ACCOUNT,
    JOOBLE_API_KEY,
    DRY_RUN = 'false',
    MIN_SCORE = '50',
    MAX_PER_USER = '3',
} = process.env;

const dryRun = DRY_RUN === 'true';
const minScore = Number(MIN_SCORE);
const maxPerUser = Number(MAX_PER_USER);

if (!FIREBASE_SERVICE_ACCOUNT || !JOOBLE_API_KEY) {
    console.error('Missing FIREBASE_SERVICE_ACCOUNT or JOOBLE_API_KEY');
    process.exit(1);
}

admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(FIREBASE_SERVICE_ACCOUNT)),
});
const db = admin.firestore();

// ── Job normalization (same logic as JobModel.fromJooble) ──────────────────
const KNOWN_SKILLS = [
    'flutter', 'dart', 'firebase', 'react', 'node.js', 'java', 'python',
    'php', 'android', 'ios', 'kotlin', 'swift', 'ui/ux', 'figma',
    'machine learning', 'data science', 'artificial intelligence',
    'javascript', 'typescript', 'sql', 'aws', 'docker',
];

function extractSkills(text) {
    return KNOWN_SKILLS.filter((skill) => text.includes(skill));
}

function parseDate(value) {
    if (!value) return new Date();
    // Jooble sends 7 fractional digits; trim to 3 so Date parses reliably
    const d = new Date(String(value).replace(/(\.\d{3})\d+/, '$1'));
    return isNaN(d.getTime()) ? new Date() : d;
}

function normalizeJob(json) {
    const title = String(json.title ?? '').trim();
    const snippet = String(json.snippet ?? '').trim();
    const text = `${title} ${snippet}`.toLowerCase();
    const company = String(json.company ?? '').trim();

    return {
        id: `jooble_${json.id}`,
        title,
        description: snippet,
        source: 'Jooble',
        company: company || 'Unknown Company',
        location: json.location ?? 'Pakistan',
        type: json.type ?? 'Full-time',
        url: json.link ?? '',
        postedAt: parseDate(json.updated),
        skills: extractSkills(text),
        isRemote: text.includes('remote'),
    };
}

// ── Scoring (same weights as MatchingEngine.score) ─────────────────────────
function scoreJob(job, prefs) {
    let points = 0;

    const prefSkills = new Set((prefs.skills ?? []).map((s) => s.toLowerCase()));
    if (prefSkills.size > 0) {
        const jobSkills = new Set(job.skills.map((s) => s.toLowerCase()));
        let overlap = 0;
        for (const s of prefSkills) if (jobSkills.has(s)) overlap++;
        points += 50 * Math.min(overlap / prefSkills.size, 1);
    }

    const types = prefs.opportunityTypes ?? [];
    if (types.some((t) => job.type.toLowerCase().includes(t.toLowerCase()))) {
        points += 20;
    }

    const cities = prefs.cities ?? [];
    if (prefs.remote && job.isRemote) {
        points += 20;
    } else if (cities.some((c) => job.location.toLowerCase().includes(c.toLowerCase()))) {
        points += 20;
    }

    const daysOld = Math.floor((Date.now() - job.postedAt.getTime()) / 86400000);
    if (daysOld <= 1) points += 10;
    else if (daysOld <= 7) points += 6;
    else if (daysOld <= 30) points += 3;

    return Math.round(points);
}

// ── Jooble fetch with per-run cache (users with the same query share a call) ─
const cache = new Map();
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function fetchJobs(keywords, location) {
    const key = `${keywords}|${location ?? ''}`;
    if (cache.has(key)) return cache.get(key);

    const res = await fetch(`https://jooble.org/api/${JOOBLE_API_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            keywords,
            ...(location ? { location } : {}),
            page: '1',
        }),
    });
    if (!res.ok) throw new Error(`Jooble responded ${res.status}`);

    const data = await res.json();
    const jobs = (data.jobs ?? []).map(normalizeJob);
    cache.set(key, jobs);
    await sleep(500); // be gentle with the free tier
    return jobs;
}

// ── Per-user pipeline ──────────────────────────────────────────────────────
async function processUser(doc) {
    const uid = doc.id;
    const user = doc.data();
    const tag = uid.slice(0, 6); // keep logs free of full ids/emails

    if (!user.fcmToken) {
        console.log(`[${tag}] no FCM token, skipping`);
        return 'skipped';
    }
    if (!user.skills?.length) {
        console.log(`[${tag}] no skills saved, skipping`);
        return 'skipped';
    }

    const keywords = user.skills.slice(0, 3).join(' ');
    const city = user.remote ? null : (user.cities?.[0] ?? user.country ?? null);

    let jobs = await fetchJobs(keywords, city);
    if (!jobs.length && city) jobs = await fetchJobs(keywords, null);

    const ranked = jobs
        .map((job) => ({ job, score: scoreJob(job, user) }))
        .filter((s) => s.score >= minScore)
        .sort((a, b) => b.score - a.score)
        .slice(0, 10);

    if (!ranked.length) {
        console.log(`[${tag}] no jobs above ${minScore}%`);
        return 'no-matches';
    }

    // Drop anything this user was already alerted about
    const sentCol = db.collection('users').doc(uid).collection('sentJobs');
    const sentSnaps = await db.getAll(...ranked.map((r) => sentCol.doc(r.job.id)));
    const fresh = ranked.filter((_, i) => !sentSnaps[i].exists).slice(0, maxPerUser);

    if (!fresh.length) {
        console.log(`[${tag}] nothing new since last alert`);
        return 'nothing-new';
    }

    const top = fresh[0];
    const title =
        fresh.length === 1
            ? `${top.score}% match: ${top.job.title}`
            : `${fresh.length} new job matches for you`;
    const body =
        fresh.length === 1
            ? `${top.job.company} · ${top.job.location}`
            : fresh.map((f) => f.job.title).join(' • ');

    if (dryRun) {
        console.log(`[${tag}] DRY RUN would send: "${title}" — ${body}`);
        return 'dry-run';
    }

    try {
        await admin.messaging().send({
            token: user.fcmToken,
            notification: { title, body },
            data: { jobId: top.job.id, url: top.job.url ?? '' },
            android: { priority: 'high' },
        });
    } catch (err) {
        const stale = [
            'messaging/registration-token-not-registered',
            'messaging/invalid-registration-token',
        ];
        if (stale.includes(err.code)) {
            await doc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
            console.log(`[${tag}] stale token removed`);
            return 'stale-token';
        }
        throw err;
    }

    const batch = db.batch();
    for (const f of fresh) {
        batch.set(sentCol.doc(f.job.id), {
            // Same field names as JobModel.fromMap in the app
            id: f.job.id,
            title: f.job.title,
            company: f.job.company,
            location: f.job.location,
            type: f.job.type,
            description: f.job.description,
            url: f.job.url,
            postedAt: f.job.postedAt.toISOString(),
            source: f.job.source,
            skills: f.job.skills,
            isRemote: f.job.isRemote,
            score: f.score,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    await batch.commit();

    console.log(`[${tag}] sent "${title}"`);
    return 'sent';
}

async function main() {
    console.log(`Job alerts run: dryRun=${dryRun}, minScore=${minScore}, maxPerUser=${maxPerUser}`);

    const users = await db.collection('users').where('preferencesSet', '==', true).get();
    console.log(`Users with preferences: ${users.size}`);

    const tally = {};
    for (const doc of users.docs) {
        try {
            const result = await processUser(doc);
            tally[result] = (tally[result] ?? 0) + 1;
        } catch (err) {
            console.error(`[${doc.id.slice(0, 6)}] failed: ${err.message}`);
            tally.failed = (tally.failed ?? 0) + 1;
        }
    }
    console.log('Summary:', JSON.stringify(tally));
}

main().then(() => process.exit(0)).catch((err) => {
    console.error(err);
    process.exit(1);
});