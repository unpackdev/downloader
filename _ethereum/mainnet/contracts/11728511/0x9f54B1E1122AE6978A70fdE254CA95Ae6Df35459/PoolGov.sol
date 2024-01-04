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

import "./Decimal.sol";
import "./Pool.sol";
import "./Liquidity.sol";

contract PoolGov is Pool {
    // Staking for governance token

    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Pool Gov";

    mapping(address => uint256) public lockedUntil;

    constructor(
        IDAO _dao,
        IERC20 _stakingToken,
        IERC20 _rewardsToken
    ) public Pool(_dao, _stakingToken, _rewardsToken) {}

    // Locks token in place i.e. they can't unbond it
    function placeLock(address account, uint256 newLock) external onlyDao {
        if (newLock > lockedUntil[account]) {
            lockedUntil[account] = newLock;
        }
    }

    function withdraw(uint256 value) public {
        // When voting, dao can place a lock on the contract
        Require.that(epoch() > lockedUntil[msg.sender], FILE, "Locked till gov passes");

        Pool.withdraw(value);
    }

    function statusOf(address user) public view returns (PoolAccount.Status) {
        if (epoch() <= lockedUntil[user]) {
            return PoolAccount.Status.Locked;
        }

        return PoolGetters.statusOf(user);
    }
}
