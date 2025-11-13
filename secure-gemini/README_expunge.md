Expunge sensitive blob from remote history

This document explains how to safely remove a tracked blob (for example: secrets accidentally committed) from a repository and coordinate with GitHub support or repository admins to allow the rewritten history to be accepted.

Offending blob SHA: 23ef0d0af42e0a296096c22121ad99a52f00d237

Steps (local):

1. Install prerequisites:
   - Python (3.8+)
   - pip install git-filter-repo

2. Create a bare mirror of the remote repository:
   git clone --mirror <repo-url> repo-mirror.git

3. Run the provided PowerShell helper (from this repo) or run git-filter-repo manually:
   # Example using the helper script from Windows PowerShell:
   .\expunge_blob.ps1 -BlobId 23ef0d0af42e0a296096c22121ad99a52f00d237 -RepoUrl <repo-url>

4. Verify that the blob is no longer referenced:
   git rev-list --objects --all | Select-String 23ef0d0af42e0a296096c22121ad99a52f00d237

5. Coordinate with repository administrators. Because this rewrites history, you must either:
   - Have admins push the rewritten refs to the central remote, OR
   - If you have permission, force-push the rewritten refs:
       git push --force --all origin
       git push --force --tags origin

Support request template (use if push-protection blocks pushes):

Subject: Request to purge blob 23ef0d0af42e0a296096c22121ad99a52f00d237 from repository history

Body:
Hello GitHub Support / Repo Admins,

I have a sensitive blob (SHA: 23ef0d0af42e0a296096c22121ad99a52f00d237) present in the repository history which contains credentials and must be removed. I have created a local rewritten mirror that removes the blob using git-filter-repo. The rewritten refs are available and a force-push is required to replace the remote history.

Please either assist with a server-side purge of the blob or advise the appropriate steps for safely replacing the remote history. I can provide the rewritten mirror or coordinate a time to perform the force-push.

Repository: <repo-url>
Blob SHA: 23ef0d0af42e0a296096c22121ad99a52f00d237
Local mirror: (available upon request)

Thank you,
<your name>
