/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>
    Copyright 2023 Lucky8 Lottery

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

pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./Bonding.sol";
import "./Govern.sol";

contract Lucky8DAO is State, Bonding, Govern {
    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);
    event Incentivization(address indexed account, uint256 amount);

    // perform state migrations, always have initializer
    function initialize() initializer override public {
        
    }

    function advance() external {
        // initiate draw and reward distribution
        initiateDrawAndRewards();

        // increase bonding epoch
        step();

        emit Advance(epoch(), block.number, blockTimestamp());
    }
}
