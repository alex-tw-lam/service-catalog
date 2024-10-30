#!/bin/bash

# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

REPO_ROOT=$(realpath $(dirname "${BASH_SOURCE}")/..)
BINDIR=${REPO_ROOT}/bin
SC_PKG='github.com/drycc-addons/service-catalog'

# Generate deep copies
${BINDIR}/deepcopy-gen "$@" \
	 --v 1 --logtostderr \
	 --go-header-file "contrib/hack/boilerplate.go.txt" \
	 --bounding-dirs "github.com/drycc-addons/service-catalog" \
	 --output-file zz_generated.deepcopy.go \
	 "${SC_PKG}/pkg/apis/servicecatalog/v1beta1"

#
# Generate auto-generated code (defaults, deepcopy and conversion) for Settings group
#

# Generate defaults
${BINDIR}/defaulter-gen "$@" \
	--v 1 --logtostderr \
	--go-header-file "contrib/hack/boilerplate.go.txt" \
	--extra-peer-dirs "${SC_PKG}/pkg/apis/settings" \
	--extra-peer-dirs "${SC_PKG}/pkg/apis/settings/v1alpha1" \
	--output-file "zz_generated.defaults.go" \
	"${SC_PKG}/pkg/apis/settings" \
	"${SC_PKG}/pkg/apis/settings/v1alpha1"

# Generate deep copies
${BINDIR}/deepcopy-gen "$@" \
	--v 1 --logtostderr \
	--go-header-file "contrib/hack/boilerplate.go.txt" \
	--bounding-dirs "github.com/drycc-addons/service-catalog" \
	--output-file zz_generated.deepcopy.go \
	"${SC_PKG}/pkg/apis/settings" \
	"${SC_PKG}/pkg/apis/settings/v1alpha1"
# Generate conversions
${BINDIR}/conversion-gen "$@" \
	--v 1 --logtostderr \
	--extra-peer-dirs k8s.io/api/core/v1,k8s.io/apimachinery/pkg/apis/meta/v1,k8s.io/apimachinery/pkg/conversion,k8s.io/apimachinery/pkg/runtime \
	--go-header-file "contrib/hack/boilerplate.go.txt" \
	--output-file zz_generated.conversion.go \
	"${SC_PKG}/pkg/apis/settings" \
	"${SC_PKG}/pkg/apis/settings/v1alpha1"

# generate openapi for servicecatalog and settings group
REPORT_FILENAME=./api_violations.txt
KNOWN_VIOLATION_FILENAME=./contrib/build/violation_exceptions.txt
API_RULE_CHECK_FAILURE_MESSAGE="Error: API rules check failed. Reported violations \"${REPORT_FILENAME}\" differ from known violations \"${KNOWN_VIOLATION_FILENAME}\". Please fix API source file if new violation is detected, or update known violations \"${KNOWN_VIOLATION_FILENAME}\" if existing violation is being fixed. Please refer to k8s.io/kubernetes/api/api-rules/README.md and https://github.com/kubernetes/kube-openapi/tree/master/pkg/generators/rules for more information about the API rules being enforced."

${BINDIR}/openapi-gen \
	--v 3 --logtostderr \
	--go-header-file "contrib/hack/boilerplate.go.txt" \
	--output-pkg "${SC_PKG}/pkg/openapi" \
	--output-dir pkg/openapi \
	--output-file openapi_generated.go \
	--report-filename "${REPORT_FILENAME}" \
	"k8s.io/api/core/v1" \
	"k8s.io/apimachinery/pkg/api/resource" \
	"k8s.io/apimachinery/pkg/apis/meta/v1" \
	"k8s.io/apimachinery/pkg/version" \
	"k8s.io/apimachinery/pkg/runtime" \
	"${SC_PKG}/pkg/apis/servicecatalog/v1beta1" \
	"${SC_PKG}/pkg/apis/settings/v1alpha1" || true

diff -u "${REPORT_FILENAME}" "${KNOWN_VIOLATION_FILENAME}" || (echo ${API_RULE_CHECK_FAILURE_MESSAGE}; exit 1)
