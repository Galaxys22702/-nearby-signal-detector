import { execFileSync } from "node:child_process";

const repository = process.env.GITHUB_REPOSITORY;
const token = process.env.GITHUB_TOKEN;
const minAgeDays = 7;
const minAgeMs = minAgeDays * 24 * 60 * 60 * 1000;

if (!repository || !token) throw new Error("GitHub repository/token unavailable.");

const apiBase = `https://api.github.com/repos/${repository}`;

async function api(path) {
  const response = await fetch(`${apiBase}/${path}`, {
    headers: {
      accept: "application/vnd.github+json",
      authorization: `Bearer ${token}`,
      "X-GitHub-Api-Version": "2022-11-28"
    },
    signal: AbortSignal.timeout(15000)
  });
  if (!response.ok) throw new Error(`GitHub API failed: ${response.status}`);
  return response.json();
}

async function list(path) {
  const all = [];
  for (let page = 1; ; page++) {
    const sep = path.includes("?") ? "&" : "?";
    const batch = await api(`${path}${sep}per_page=100&page=${page}`);
    all.push(...batch);
    if (batch.length < 100) return all;
  }
}

const meta = await api("");
if (process.env.GITHUB_REF !== `refs/heads/${meta.default_branch}`) {
  throw new Error("Cleanup must run from the default branch.");
}

const [branches, pulls] = await Promise.all([
  list("branches"),
  list("pulls?state=all")
]);

const candidates = branches.filter(branch => {
  if (branch.name === meta.default_branch || branch.protected) return false;

  const own = pulls.filter(pr =>
    pr.head?.repo?.full_name === repository &&
    pr.head.ref === branch.name
  );
  if (own.some(pr => pr.state === "open")) return false;

  if (pulls.some(pr =>
    pr.state === "open" &&
    pr.base?.repo?.full_name === repository &&
    pr.base.ref === branch.name
  )) return false;

  return own.some(pr => {
    if (
      pr.state !== "closed" ||
      !pr.merged_at ||
      pr.base?.repo?.full_name !== repository ||
      pr.base.ref !== meta.default_branch ||
      pr.head.sha !== branch.commit.sha
    ) return false;

    const mergedAt = Date.parse(pr.merged_at);
    return Number.isFinite(mergedAt) && Date.now() - mergedAt >= minAgeMs;
  });
});

for (const branch of candidates) {
  const current = await api(`branches/${encodeURIComponent(branch.name)}`);
  if (current.protected || current.commit.sha !== branch.commit.sha) continue;

  const ref = `refs/heads/${branch.name}`;
  execFileSync("git", ["check-ref-format", ref], { stdio: "pipe" });
  execFileSync(
    "git",
    ["push", `--force-with-lease=${ref}:${branch.commit.sha}`, "--delete", "origin", ref],
    { stdio: "inherit" }
  );
  console.log(`Deleted merged branch: ${branch.name}`);
}

console.log(`Cleanup complete. Deleted ${candidates.length} eligible merged branch(es).`);
