#!/bin/bash
#
#
#  ██████╗ ██╗ ██████╗ ██████╗
# ██╔════╝ ██║██╔════╝██╔═══██╗
# ██║  ███╗██║██║     ██║   ██║
# ██║   ██║██║██║     ██║   ██║
# ╚██████╔╝██║╚██████╗╚██████╔╝
#  ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝
#
# Authored by: Shane Breining
# Date Published: 2022, January 20th
#
# Gico (for `git checkout`, and pronounced 'jee-ko')  is a shell script for
# simplifying the git checkout process. This includes checking out a branch
# from remote, checking out a branch that is only local, or even creating a
# new  branch given  that one does  not exist matching  the provided  regex
#
# The intended use as suggested by the presences of regular expressions, is
# to take  advantage of unique  branch names. Generally,  if an agile board
# like JIRA is being used, then simply the ticket number should suffice for
# checking out the branch.
# However, the few conditions that will need more information when using
# ticket numbers:
#     Overlapping Numbers: In the event that DEV-X and SRE-X both exist
#                          where X is the same number value, you should
#                          specify the prefix of the ticket.
#
#       Multiple Branches: When there are multiple branches for a given
#                          ticket and each of the branches share similar
#                          prefixes and ticket numbers, then enough of the
#                          branch must be present to make the regex unique.
#
# Example Usage:
#
#   `gico
#

function usage {
  cat << EOF

  Usage: $0 [flags] <regex>

  Availble flags:
       -f  Will call 'git fetch' before looking for the
           branch

       -n  Forces the creation of a new branch,
           will exit on <regex> conflict.

       -h  Shows this usage message.

  Purpose:
       Intended to expidite the process of checking out
       and creating a new branch in git. If '-n' flag is
       not passed in, it will attempt to find the branch
       in the remote repository, followed by looking at
       local branches. If no regex pattern is matched in
       repo or local, it will prompt you to create a new
       branch, followed by asking for the full branch
       name.

EOF
}

function conflict {
  cat << EOF

  Conflict found with branch regex.
  Please use an identifier other than:
    "$1"

  Exiting...

EOF
}

function get_branch_name {
  if [[ "$1" =~ ^(main|master|develop)$ ]]; then
    BRANCH=$1;
  else
    # Check the remote branches and filter on user input.
    BRANCH=$(git branch -r | grep "$1");
    if [ ! -z "$BRANCH" ]; then
      # Cut the 'origin/' from the beginning of the string returned.
      BRANCH=$(echo ${BRANCH:9});
    else
      # If no branchs were found in remote, attempt to find local branch.
      BRANCH=$(git branch | grep "$1");
      [ ! -z "$BRANCH" ] && BRANCH=$(echo ${BRANCH});
    fi
  fi

  echo $BRANCH;
}

function create_new {
  if [ ! -z $(get_branch_name $1) ]; then
    conflict $1;
    return;
  fi

  read -p "Is '$1' the full branch name? [Y/n] " yes;

  if [ "$yes" = "Y" ]; then
    git checkout -b $1;
  else
    echo "Please provide the full branch name.";
    read -p "Name: " name;

    git checkout -b $name;
  fi
}

CREATE_NEW=
FETCH=

if [ $# -lt 1 ]; then
  echo "  Must provide the required <regex>";
  usage;
  exit 2;
fi

while getopts ":fhn" opt; do
  case $opt in
    f)
      FETCH=1;
      ;;
    n)
      CREATE_NEW=1;
      ;;
    h)
      usage;
      exit 1;
      ;;
    ?)
      echo "  Invalid option: -$OPTARG" >&2;
      usage;
      exit 2;
  esac
done

shift $(( $OPTIND - 1 ));

[ ! -z "$FETCH" ] && git fetch;

[ ! -z "$CREATE_NEW" ] && create_new $1 && exit 1;

B=$(get_branch_name $1);

[ ! -z "$B" ] && git checkout $B && exit 1;

echo "No branch contains '$1'";

read -p "Would you like to create it? [Y/n] " create;
[ "$create" = "Y" ] && create_new $1;

exit 1;

