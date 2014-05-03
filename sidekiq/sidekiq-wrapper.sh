#!/usr/bin/env bash

###########################################################
RVM=true
RVM_RUBY=2.0.0-p247@rails32
###########################################################

if $RVM; then
  # Load RVM into a shell session *as a function*
  if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
    source "$HOME/.rvm/scripts/rvm"
  elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
    source "/usr/local/rvm/scripts/rvm"
  else
    printf "ERROR: An RVM installation was not found.\n" && exit 1
  fi

  rvm use $RVM_RUBY
fi

app=$1; command=$2;
cd $app && exec bundle exec $command
