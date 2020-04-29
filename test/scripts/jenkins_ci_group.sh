#!/usr/bin/env bash

source test/scripts/jenkins_test_setup_oss.sh

if [[ -z "$CODE_COVERAGE" ]]; then
  checks-reporter-with-killswitch "Functional tests / Group ${CI_GROUP}" yarn run grunt "run:functionalTests_ciGroup${CI_GROUP}";

  if [ "$CI_GROUP" == "1" ]; then
    source test/scripts/jenkins_build_kbn_sample_panel_action.sh
    yarn run grunt run:pluginFunctionalTestsRelease --from=source;
    yarn run grunt run:exampleFunctionalTestsRelease --from=source;
    yarn run grunt run:interpreterFunctionalTestsRelease;
  fi
else
  echo " -> Running Functional tests with code coverage"
  export NODE_OPTIONS=--max_old_space_size=8192

  echo " -> making hard link clones"
  cd ..
  cp -RlP kibana "kibana${CI_GROUP}"
  cd "kibana${CI_GROUP}"

  echo " -> running tests from the clone folder"
  #yarn run grunt "run:functionalTests_ciGroup${CI_GROUP}";
  node scripts/functional_tests --debug --include-tag "ciGroup$CI_GROUP"  --exclude-tag "skipCoverage" || true;

  if [[ -d target/kibana-coverage/functional ]]; then
    echo " -> copying coverage to the original folder"
    mkdir -p ../kibana/target/kibana-coverage/functional
    mv target/kibana-coverage/functional/* ../kibana/target/kibana-coverage/functional/
  fi

  echo " -> moving junit output, silently fail in case of no report"
  mkdir -p ../kibana/target/junit
  mv target/junit/* ../kibana/target/junit/ || echo "copying junit failed"

  echo " -> copying screenshots folder"
  cp -r test/functional/screenshots/* ../kibana/test/functional/screenshots/ || echo "copying screenshots failed"
fi