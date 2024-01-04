/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

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

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./Pool.sol";
import "./Liquidity.sol";

contract PoolLP is Pool, Liquidity {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Pool Liquidity";

    constructor(
        IDAO _dao,
        IERC20 _stakingToken,
        IERC20 _rewardsToken
    ) public Pool(_dao, _stakingToken, _rewardsToken) {}
}
