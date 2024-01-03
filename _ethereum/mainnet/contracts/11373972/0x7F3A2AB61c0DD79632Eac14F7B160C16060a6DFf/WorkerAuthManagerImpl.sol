// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title WorkerAuthManagerImpl
/// @author Danilo Tuler
pragma solidity ^0.7.0;

import "./WorkerManager.sol";
import "./WorkerAuthManager.sol";

contract WorkerAuthManagerImpl is WorkerAuthManager {
    WorkerManager workerManager;

    /// @dev permissions keyed by hash(user, worker, dapp)
    mapping(bytes32 => bool) private permissions;

    constructor(address _workerManager) {
        workerManager = WorkerManager(_workerManager);
    }

    modifier onlyByOwner(address _workerAddress) {
        require(
            workerManager.getOwner(_workerAddress) == msg.sender,
            "worker not hired by sender"
        );
        _;
    }

    function getAuthorizationKey(
        address _user,
        address _worker,
        address _dapp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _worker, _dapp));
    }

    function authorize(address _workerAddress, address _dappAddress)
        public
        override
        onlyByOwner(_workerAddress)
    {
        bytes32 key = getAuthorizationKey(
            msg.sender,
            _workerAddress,
            _dappAddress
        );
        require(permissions[key] == false, "dapp already authorized");

        // record authorization from that user
        permissions[key] = true;

        // emit event
        emit Authorization(msg.sender, _workerAddress, _dappAddress);
    }

    function deauthorize(address _workerAddress, address _dappAddress)
        public
        override
        onlyByOwner(_workerAddress)
    {
        bytes32 key = getAuthorizationKey(
            msg.sender,
            _workerAddress,
            _dappAddress
        );
        require(permissions[key] == true, "dapp not authorized");

        // record deauthorization from that user
        permissions[key] = false;

        // emit event
        emit Deauthorization(msg.sender, _workerAddress, _dappAddress);
    }

    function isAuthorized(address _workerAddress, address _dappAddress)
        public
        override
        view
        returns (bool)
    {
        return
            permissions[getAuthorizationKey(
                workerManager.getOwner(_workerAddress),
                _workerAddress,
                _dappAddress
            )];
    }

    function getOwner(address _workerAddress)
        public
        override
        view
        returns (address)
    {
        return workerManager.getOwner(_workerAddress);
    }

    /*
    // XXX: we can't do this because the worker need to accept the job before receiving an authorization
    function hireAndAuthorize(
        address payable _workerAddress,
        address _dappAddress
    ) public override payable {
        workerManager.hire(_workerAddress);
        authorize(_workerAddress, _dappAddress);
    }
    */
}
