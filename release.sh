#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

relDir=./release/build
relNoteDir=./release/notes
whatsNew="./WHATSNEW.md"
whatsNewTemplate="./release/WHATSNEW-template.md"

function fatal {
	echo "Fatal: $1" 1>&2
	kill 0		# Ensures that script stops on fatal independent of subshell nesting
}

function checkForUnsavedChanges {
	# Check for unsaved changes if running locally
 	git diff-index --quiet --exit-code HEAD || fatal "Unsaved changes"
}

# Checks that the PR raised by updateReleaseNotesPullRequest during the
# previous release has been merged
function checkPreviousReleaseNoteUpdateMerged {
	local note="$relNoteDir/$1.md"
	[ -f $note ] || fatal "Did not find release note $note - check PR merged"
}

# Check that WHATSNEW.md has been updated
function checkWhatsNew {
	[ -f $whatsNew ] || fatal "Did not find $whatsNew"
	diff -w $whatsNew $whatsNewTemplate > /dev/null && fatal "$whatsNew has not been updated"
}

function deriveVersion {

	local branch=$(git rev-parse --abbrev-ref HEAD)
	local lastTag=$(git describe --tags --match "v*")

	# Format should be v<semver>-<#commits>-<hash> is the tag is not for the current branch (e.g. v0.1.0-9-g8b97749)
	case $lastTag in
		v*.*.*-*-*)	
			lastSemVer=($(echo $lastTag | sed -e 's/^v//' -e 's/-.*//' -e 's/\./ /g'))		
			;;
		*)
			fatal "Verions is already tagged with $lastTag"
			;;
	esac

	checkPreviousReleaseNoteUpdateMerged "${lastSemVer[0]}.${lastSemVer[1]}.${lastSemVer[2]}"

	case $branch in

		main)
			typeset -i minor=${lastSemVer[1]}+1
			semVer="${lastSemVer[0]}.$minor.0"
			;;

		hotfix-*)
			typeset -i patch=${lastSemVer[2]}+1
			semVer="${lastSemVer[0]}.${lastSemVer[1]}.$patch"
			;;

		*)
			fatal "Can only release from main or hotfix branch, not $branch"
			;;

	esac

	echo $semVer
	
}

# Push packages/images
function buildRelease {
	local version=$1
	git tag "v$version"
	git push --tags
}

# Push packages/images
function applyTag {
	local version=$1
	echo "Applying tag for $version"
	git tag "v$version"
	git push --tags
}

# Push packages/images
function publishRelease {
	local version=$1
	echo "Publishing artifacts for $version"
}

# Update release notes
function updateReleaseNotesPullRequest {
	local version=$1
	echo "Updating release notes following $version"
}

function main {
	# checkForUnsavedChanges
	# local version=$(deriveVersion)
	version=0.2.0
	echo "Releasing version: $version"
	checkPreviousReleaseNoteUpdateMerged $version
	checkWhatsNew
	buildRelease $version
	# applyTag $version
	# publishRelease $version
	# updateReleaseNotes $version
}

main



