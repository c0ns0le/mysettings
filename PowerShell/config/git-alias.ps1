############################################
############# Creating Array of all commands

$myCommands = New-Object System.Collections.ArrayList

function AddGitAlias([string] $alias,
    [string] $commandText,
    [string] $command,
    [string] $description){
    $myCommands.Add([pscustomobject] @{
        alias="$alias";
        commandText="$commandText";
        command=$command;
        description=$description}) `
    > $null
}


function git-execCommand([string] $command, [string] $description){
    if($description){
        Write-Info $description
    }
    Write-Command $command
    iex $command
}

############################################
########### Defining commands ############

$gitStatusCmd =  ' git status --short'
function git-status {
    git-execCommand $gitStatusCmd
}
AddGitAlias "ggst" "$gitStatusCmd" "git-status"


$gitDiffCmd = 'git diff'
function git-diff {
    Write-Info "git diff"
    iex $gitDiffCmd
    git diff --staged
}
AddGitAlias "ggdf" $gitDiffCmd "git-diff" "show changes in files"


$gitBranchNameCmd = ' git rev-parse --abbrev-ref HEAD '
function git-branchName { iex $gitBranchNameCmd }


$gitAddCmd = 'git add -A'
$gitCommitCmd = 'git commit -m "{0}"'
$gitAddAndCommitDesc = "Adding all unstaged files to stage,  Commiting staged files... "
function git-commit ([string] $message){
    if(!$message){
        Write-Err "Please provide a message for the commit !!!"
        return
    }
    git-execCommand $gitAddCmd $gitAddAndCommitDesc
    git-execCommand ($gitCommitCmd -f $message)
}
AddGitAlias "ggcommit" $gitCommitCmd  "git-commit" $gitAddAndCommitDesc


$gitResetCmd = 'git reset HEAD --hard'
$gitResetDesc =  "Unstaging all staged changes "
Function git-reset {
    git-execCommand $gitResetCmd $gitResetDesc
}
AddGitAlias "ggreset" $gitResetCmd "git-reset" $gitResetDesc

#######################################
#####  CHECKOUT

$gitCheckoutCmd = 'git checkout {0}'
$gitCheckoutDesc = "Switching to branch {0}"
function git-checkout([string] $branchName) {
    IF(!$branchName){
        $branchName = git-branchName
    }
    git-execCommand ($gitCheckoutCmd -f $branchName) ($gitCheckoutDesc -f $branchName)
    git-pull
}
AddGitAlias "ggch"  $gitCheckoutCmd  "git-checkout" $gitCheckoutDesc


function git-checkoutStar {
    git-checkout "*"
}
AddGitAlias "ggcs"  $gitCheckoutCmd  "git-checkoutStar" $gitCheckoutDesc


function git-checkoutWork {
    git-checkout "work"
}
AddGitAlias "ggwork" $gitCheckoutCmd "git-checkoutWork" $gitCheckoutDesc


function git-checkoutMaster {
    git-checkout "master"
}
AddGitAlias "ggcm" $gitCheckoutCmd "git-checkoutMaster" $gitCheckoutDesc

################################################

$gitCleanCmd = 'git clean -fd'
$gitCleanDescription =  "Cleaning all untracked changes in files / directories / ignored."
function git-clean {
    git-execCommand $gitCleanCmd $gitCleanDescription
}
AddGitAlias "ggcln" $gitCleanCmd "git-clean" $gitCleanDescription


$gitRevertAllDesc = "Reverting all changes in current working directory (staged, unstaged, tracked, untracked, ignored)"
function git-revertAll {
    param ([switch] $clean)

    Write-Info $gitRevertAllDesc
    git-reset
    git-checkout
    if($clean){
        git-clean
    }
}
AddGitAlias "ggrevert" "$gitResetCmd ; $gitCheckoutStarCmd ; $gitCleanCmd " "git-revertAll" $gitRevertAllDesc


$gitUndoLastCommitCmd = "git reset HEAD^"
$gitUndoLastCommitDesc = "Undoing last commit, moving HEAD to previous commit."
function git-undoLastCommit {
    git-execCommand $gitUndoLastCommitCmd $gitUndoLastCommitDesc
}
AddGitAlias "ggundo" $gitUndoLastCommitCmd  "git-undoLastCommit" $gitUndoLastCommitDesc

#
# http://stackoverflow.com/questions/6934752/combining-multiple-commits-before-pushing-in-git
$gitSquashCmd = "git rebase -i origin/{0}"
function git-squash {
    $currentBranch = git-branchName
    git-execCommand ($gitSquashCmd -f $currentBranch )
}


$gitPushCmd = "git push origin {0}"
$gitPushDesc =  "Pushing changes from current branch to origin."
function git-push {
    $branchName = git-branchName
    git-execCommand ($gitPushCmd -f $branchName) $gitPushDesc
}
AddGitAlias "ggph" $gitPushCmd  "git-push" $gitPushDesc


$gitPullCmd = "git pull origin {0}"
$gitPullDesc =  "Pulling changes from origin to current branch. This will update code from origin. Eqivalent to SVN update."
function git-pull {
    $branchName = git-branchName
    git-execCommand ($gitPullCmd -f $branchName) $gitPullDesc
}
AddGitAlias "ggpl" $gitPullCmd  "git-pull" $gitPullDesc


$gitSaveDesc = "Save current work with generic message"
Function git-save {
    $time = Get-Date -format u
    git-commit "Save at $time"
}
AddGitAlias "ggsave" $gitCommitCmd "git-save" $gitSaveDesc


$gitSavePushDesc = "Save current changes and push them into otigin"
Function git-savePush {
    git-save
    git-push
}
AddGitAlias "ggsave" $gitCommitCmd "git-savePush" $gitSavePushDesc


$gitMergeDesc = "Merge branch '{0}' to current branch '{1}'"
$gitMergeCmd = "git merge {0}"
function git-merge([string] $mergeFromBranch){
    if(! $mergeFromBranch){
        Write-Err "Please provide source branch for merge"
        return
    }
    git-execCommand ($gitMergeCmd -f $mergeFromBranch)
    git-push
}
AddGitAlias "ggmerge" $gitMergeCmd "git-merge" $gitMergeDesc


$gitGrepCmd = "git grep --ignore-case --line-number -B {0} -A {1} '{2}' -- './{3}' "
function git-grep () {
    param(
        [string] $pattern,
        [int] $before = 0,
        [int] $after = 0,
        [string] $include = "*",
        [string] $exclude = $null,
        [switch] $excludeRB
    )
    $gitGrepCmdResult = $gitGrepCmd
    if($excludeRB){
        $exclude = "*.css,rbdotcom*.js,dist/**"
    }
    if($exclude){
        "$exclude".Split("{,}") | % { $gitGrepCmdResult += (" ':(exclude)*/{0}'" -f $_ ) }
    }
    git-execCommand ($gitGrepCmdResult -f $before, $after, $pattern, $include )
}
AddGitAlias "ggfind" $gitGrepCmd "git-grep"  "search for a string in repository"



$gitRefreshDesc = "Refresh master and work branches by pulling all changes from them"
Function git-refresh {
    $currentBranch = git-branchName
    git-checkoutMaster
    git-checkoutWork
    git-checkout $currentBranch
}
AddGitAlias "ggrefresh" $gitPushCmd "git-refresh" $gitResetDesc


$gitRefreshAllDesc = "Refresh master and work branches by pulling all changes from them"
Function git-refreshAll {
    $allRemoteBranches = git-execCommand "git branch --remote --list"

    $allRemoteBranches | %{ git-checkout $_ }
}
AddGitAlias "ggrefreshAll" $gitPushCmd "git-refresh" $gitResetDesc


# git log man : https://git-scm.com/docs/git-log
# Format options :
# %d: ref names, like the --decorate option of git-log[1] - branch names
# %ar: author date, relative
# %h: abbreviated commit hash
# %s: subject - commit message
# %an: author name - of a commit
$gitLogGraphCmd = "git log --graph " +
    "--abbrev-commit " +
    "--decorate "+
    "--format=format:'" +
        "%C(bold yellow)%d%C(reset) " +       # branch name
        "%n      " +                          # new line
        "%C(bold green)(%ar)%C(reset) " +     # date of commit
        "%C(dim white) [%an]%C(reset) - " +   # author name
        "%C(white)%s%C(reset) " +             # commit message
        "%C(bold blue)[%h]%C(reset)" +        # short hash of commit
        "' --all" +
        " --since='{0}'"
$gitLogGraphDesc = "Getting branch tree "
function git-logGraph{
    param($fromLastDays = 14)

    $sinceDate = "{0:yyyy-MM-dd}" -f (Get-Date).AddDays(-1 * $fromLastDays)
    git-execCommand ($gitLogGraphCmd -f $sinceDate) $gitLogGraphDesc
}
AddGitAlias "ggbranchlog" $gitLogGraphCmd "git-logGraph" $gitLogGraphDesc


$gitHistoryCmd = "git log " +
    " --pretty=format:'" +
    "%C(bold blue)%h%C(reset)" +        # short hash of commit
    "%C(bold yellow)%d%C(reset) \\ " +
    "%C(dim white) [%an]%C(reset) - " +   # author name
    "%C(white)%s%C(reset) " +             # commit message
    "' --since='{0}'" +
    " --decorate "
$gitHistoryDesc =  "Getting commit history of current branch."
Function git-history{
    param($sinceDays = 30)

    $sinceDate = "{0:yyyy-MM-dd}" -f (Get-Date).AddDays(-1 * $sinceDays)
    git-execCommand ($gitHistoryCmd -f $sinceDate) $gitHistoryDesc
}
AddGitAlias "gghist" $gitHistoryCmd "git-history" $gitHistoryDesc


$gitTortoiseResolveCmd =  "TortoiseGitProc.exe /command:resolve"
Function git-resolve{
    Invoke-Expression "$gitTortoiseResolveCmd"
}
AddGitAlias "ggresolve" $gitTortoiseResolveCmd "git-resolve"


$gitTortoiseStatusCmd =  "TortoiseGitProc.exe /command:repostatus"
Function git-tgStatus{
    Invoke-Expression "$gitTortoiseStatusCmd"
}
AddGitAlias "ggvst" $gitTortoiseStatusCmd "git-tgStatus"

####### Import Cogworks specific commands  ####
. ($PScriptConfig + "\cogworks-git-alias.ps1")
################################################


# Help function
function MyGitHelp([string] $filter){
    Write-Info "My git commands"
    $filteredCommands = $myCommands

    if($filter){
        $likeFilter =  "*$filter*"
        $filteredCommands = $filteredCommands | Where {
            ($_.alias -like $likeFilter) `
            -or ($_.commandText -like $likeFilter) `
            -or ($_.description -like $likeFilter)
        }
    }

    $filteredCommands `
        | Sort-Object Alias `
        | ForEach {
        "`t" + $_.alias +
        "`t- " + $_.description +
        "`n`t`t" + $_.commandText +
        "`n"}
}
AddGitAlias "gghelp" "Displays this help text" "MyGitHelp"


# Setting Aliases
$myCommands | ForEach { Set-Alias -Name $_.alias -Value $_.command }


