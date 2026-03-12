import z from "zod"
import { Tool } from "./tool"
import { Instance } from "../project/instance"
import { $ } from "bun"
import DESCRIPTION_COMMIT from "./git-commit.txt"
import DESCRIPTION_PUSH from "./git-push.txt"

export const GitCommitTool = Tool.define("git_commit", {
  description: DESCRIPTION_COMMIT,
  parameters: z.object({
    message: z.string().describe("The commit message"),
    add: z.array(z.string()).optional().describe("Specific files to add (defaults to all changes)"),
    amend: z.boolean().optional().describe(" Amend the previous commit instead of creating a new one"),
    allowEmpty: z.boolean().optional().describe("Allow creating a commit with no changes"),
  }),
  async execute(params, ctx) {
    const cwd = Instance.directory

    await ctx.ask({
      permission: "write",
      patterns: [cwd],
      always: ["*"],
      metadata: {},
    })

    try {
      // Stage files
      if (params.add && params.add.length > 0) {
        await $`git add ${params.add}`.cwd(cwd)
      }

      // Create commit
      const args = ["commit", "-m", params.message]
      if (params.amend) args.unshift("--amend")
      if (params.allowEmpty) args.push("--allow-empty")

      const result = await $`git ${args}`.cwd(cwd).quiet()

      return {
        title: "git commit",
        output: result.stdout?.toString() || "Commit created successfully",
        metadata: {},
      }
    } catch (error: any) {
      throw new Error(`Git commit failed: ${error.stderr?.toString() || error.message}`)
    }
  },
})

export const GitPushTool = Tool.define("git_push", {
  description: DESCRIPTION_PUSH,
  parameters: z.object({
    remote: z.string().optional().describe("The remote name (defaults to 'origin')"),
    branch: z.string().optional().describe("The branch name (defaults to current branch)"),
    force: z.boolean().optional().describe("Use force push"),
    forceWithLease: z.boolean().optional().describe("Use force push with lease (safer)"),
    setUpstream: z.boolean().optional().describe("Set upstream branch"),
  }),
  async execute(params, ctx) {
    const cwd = Instance.directory

    await ctx.ask({
      permission: "write",
      patterns: [cwd],
      always: ["*"],
      metadata: {},
    })

    try {
      const args = ["push"]
      if (params.force) args.push("--force")
      if (params.forceWithLease) args.push("--force-with-lease")
      if (params.setUpstream) args.push("--set-upstream")

      const remote = params.remote || "origin"
      const branch = params.branch || await $`git branch --show-current`.cwd(cwd).quiet().then(r => r.stdout?.toString().trim())

      if (!branch) throw new Error("Could not determine branch name")
      args.push(remote, branch)

      const result = await $`git ${args}`.cwd(cwd).quiet()

      return {
        title: "git push",
        output: result.stdout?.toString() || `Pushed ${branch} to ${remote}`,
        metadata: {},
      }
    } catch (error: any) {
      throw new Error(`Git push failed: ${error.stderr?.toString() || error.message}`)
    }
  },
})

export const GitStatusTool = Tool.define("git_status", {
  description: "Show the working tree status. Use this to see what files have been modified, added, or deleted before committing.",
  parameters: z.object({
    short: z.boolean().optional().describe("Use short format"),
  }),
  async execute(params, ctx) {
    const cwd = Instance.directory

    try {
      const args = params.short ? ["status", "-s"] : ["status"]
      const result = await $`git ${args}`.cwd(cwd).quiet()

      return {
        title: "git status",
        output: result.stdout?.toString() || "No changes",
        metadata: {},
      }
    } catch (error: any) {
      throw new Error(`Git status failed: ${error.stderr?.toString() || error.message}`)
    }
  },
})
