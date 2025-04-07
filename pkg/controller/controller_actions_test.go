/*
Copyright 2017 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controller

import (
	"fmt"
	"reflect"

	"k8s.io/client-go/testing"
)

type kubeClientAction struct {
	verb         string
	resourceName string
	checkType    func(testing.Action) error
}

// checkGetActionType can be used as a param for kubeClientAction.checkType. It's intended
// to ensure an action is a testing.GetAction
func checkGetActionType(a testing.Action) error {
	if _, ok := a.(testing.GetAction); !ok {
		return fmt.Errorf("expected a GetAction, got %s", reflect.TypeOf(a))
	}
	return nil
}

// checkKubeClientActions is the utility function for checking actions returned by the generic
// kubernetes client
func checkKubeClientActions(actual []testing.Action, expected []kubeClientAction) error {
	if len(actual) != len(expected) {
		return fmt.Errorf("expected %d kube client actions, got %d; full action list: %v", len(expected), len(actual), actual)
	}
	for i, actualAction := range actual {
		expectedAction := expected[i]
		if actualAction.GetVerb() != expectedAction.verb {
			return fmt.Errorf(
				"action %d: expected verb '%s', got '%s'",
				i,
				expectedAction.verb,
				actualAction.GetVerb(),
			)
		}
		getAction, ok := actualAction.(testing.GetAction)
		if !ok {
			return fmt.Errorf(
				"action %d: expected a GetAction, got %s",
				i,
				reflect.TypeOf(actualAction),
			)
		}
		if expectedAction.resourceName != getAction.GetResource().Resource {
			return fmt.Errorf(
				"expected resource name '%s', got '%s'",
				expectedAction.resourceName,
				getAction.GetResource().Resource,
			)
		}
	}
	return nil
}
