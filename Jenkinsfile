#!groovy

node {
  // Notify stash that the build is in progress
  step([$class: 'StashNotifier'])

  try{
    stage 'Build'
    checkout scm
    sh "mkdir -p log"
    using_mri "bundle install --quiet"

    stage 'Rubocop'
    using_mri "bundle exec rake rubocop"

    for(ruby_version in ["ruby-2.3.1", "jruby-9.1.5.0"]) {
      test_with_ruby(ruby_version)
    }

    stage 'Bundle Audit'
    using_mri """
      bundle-audit update
      bundle-audit
    """

    currentBuild.result = 'SUCCESS'
  }catch(err){
    currentBuild.result = 'FAILED'
  }

  // Notify stash again
  step([$class: 'StashNotifier'])
}

// In order for RVM to be loaded properly, we need to run scripts
// with bash instead of the default shell --sh
def bash(command) {
  sh """#!/bin/bash -l
    ${command}
  """
}

def using_mri(command) {
  bash """
    rvm use ruby-2.3.1
    ${command}
  """
}

// Select a particular ruby version, and run tests on it
def test_with_ruby(version) {
  stage "Bundle using ${version}"
  bash """
    rvm use ${version}
    ruby -v
    bundle install --quiet
  """
  stage "Test using ${version}"
  bash """
    rvm use ${version}
    ruby -v
    bundle exec rspec spec
  """
}
