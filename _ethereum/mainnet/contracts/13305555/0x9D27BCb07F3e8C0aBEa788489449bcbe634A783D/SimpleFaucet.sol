// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.5.0;

import "./IERC20.sol";

contract SimpleFaucet {
    uint256 public constant tokenAmount = 100000000000000000000000; // 100k CTSI
    uint256 public constant waitTime = 4 weeks; // can request every 4 weeks

    IERC20 public tokenInstance;

    mapping(address => uint256) lastAccessTime;

    constructor(address _tokenInstance) public {
        require(_tokenInstance != address(0));
        tokenInstance = IERC20(_tokenInstance);
    }

    function requestTokens() public {
        require(allowedToWithdraw(msg.sender));
        tokenInstance.transfer(msg.sender, tokenAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if (lastAccessTime[_address] == 0) {
            return true;
        } else if (block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}
