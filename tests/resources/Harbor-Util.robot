# Copyright 2016-2017 VMware, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

*** Settings ***
Documentation  This resource provides any keywords related to the Harbor private registry appliance
Library  Selenium2Library
Library  OperatingSystem

*** Variables ***
${HARBOR_VERSION}  v1.1.1

*** Keywords ***
Install Harbor to Test Server
		Log To Console  \nStart Docker Daemon
		Start Docker Daemon Locally
		Sleep  5s
		${rc}  ${output}=  Run And Return Rc And Output  docker ps
    Should Be Equal As Integers  ${rc}  0
    Log To Console  \n${output}
    Log To Console  \nconfig harbor cfg
    Run Keywords  Config Harbor cfg
		Run Keywords  Prepare Cert
    Log To Console  \ncomplile and up harbor now
    Run Keywords  Compile and Up Harbor With Source Code
    ${rc}  ${output}=  Run And Return Rc And Output  docker ps
    Should Be Equal As Integers  ${rc}  0
    Log To Console  \n${output}

Up Harbor
		[Arguments]  ${with_notary}=true
		${rc}  ${output}=  Run And Return Rc And Output  make start -e NOTARYFLAG=${with_notary}
		Log To Console  ${rc}
		Should Be Equal As Integers  ${rc}  0

Down Harbor
		[Arguments]  ${with_notary}=true
		${rc}  ${output}=  Run And Return Rc And Output  make down -e NOTARYFLAG=${with_notary}
		Log To Console  ${rc}
		Should Be Equal As Integers  ${rc}  0

Package Harbor Offline
		[Arguments]  ${golang_image}=golang:1.7.3  ${clarity_image}=vmware/harbor-clarity-ui-builder:1.1.1  ${with_notary}=false
		Log To Console  \nStart Docker Daemon
		Start Docker Daemon Locally
		${rc}  ${output}=  Run And Return Rc And Output  make package_offline GOBUILDIMAGE=${golang_image} COMPILETAG=compile_golangimage CLARITYIMAGE=${clarity_image} NOTARYFLAG=${with_notary} HTTPPROXY=
		Log To Console  ${rc}
		Log  ${output}
		Should Be Equal As Integers  ${rc}  0

Config Harbor cfg
    # Will change the IP and Protocol in the harbor.cfg
    [Arguments]  ${http_proxy}=http
    ${rc}  ${output}=  Run And Return Rc And Output  ip addr s eth0 |grep "inet "|awk '{print $2}' |awk -F "/" '{print $1}'
    Log  ${output}
    ${rc}=  Run And Return Rc  sed "s/reg.mydomain.com/${output}/" -i ./make/harbor.cfg
    Log  ${rc}
    Should Be Equal As Integers  ${rc}  0
    ${rc}=  Run And Return Rc  sed "s/^ui_url_protocol = .*/ui_url_protocol = ${http_proxy}/g" -i ./make/harbor.cfg
    Log  ${rc}
    Should Be Equal As Integers  ${rc}  0

Prepare Cert
    # Will change the IP and Protocol in the harbor.cfg
		${rc}=  Run And Return Rc  ./tests/generateCerts.sh
		Log  ${rc}
		Should Be Equal As Integers  ${rc}  0

Compile and Up Harbor With Source Code
    [Arguments]  ${golang_image}=golang:1.7.3  ${clarity_image}=vmware/harbor-clarity-ui-builder:1.1.1  ${with_notary}=false
		${rc}  ${output}=  Run And Return Rc And Output  docker pull ${clarity_image}
    Log  ${output}
		Should Be Equal As Integers  ${rc}  0
		${rc}  ${output}=  Run And Return Rc And Output  docker pull ${golang_image}
    Log  ${output}
		Should Be Equal As Integers  ${rc}  0
    ${rc}  ${output}=  Run And Return Rc And Output  make install GOBUILDIMAGE=${golang_image} COMPILETAG=compile_golangimage CLARITYIMAGE=${clarity_image} NOTARYFLAG=${with_notary} HTTPPROXY=
		Log  ${output}
		Should Be Equal As Integers  ${rc}  0
    Sleep  20
