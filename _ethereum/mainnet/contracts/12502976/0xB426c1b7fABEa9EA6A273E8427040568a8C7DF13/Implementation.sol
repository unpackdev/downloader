/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

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

import "./SafeMath.sol";
import "./Market.sol";
import "./Regulator.sol";
import "./Bonding.sol";
import "./Govern.sol";
import "./Bootstrapper.sol";
import "./Constants.sol";
import "./IImplementation.sol";
import "./IVault.sol";
import "./IYearnVault.sol";
import "./RewardsDistribution.sol";

contract Implementation is IImplementation, State, Bonding, Market, Regulator, Govern, Bootstrapper {
    using SafeMath for uint256;

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);

    function initialize() initializer public {
        address yearnVault = 0x19D3364A399d251E894aC732651be8B0E4e85001;
        address rewardsDistribution = 0x772918d032cFd4Ff09Ea7Af623e56E2D8D96bB65;
        //Withdraw from the vault to RewardsDistribution
        IVault(Constants.getMultisigAddress()).submitTransaction(
            yearnVault,
            0,
            abi.encodeWithSignature("withdraw(uint256,address)",
                IYearnVault(yearnVault).balanceOf(Constants.getMultisigAddress()),
                rewardsDistribution)
        );
    }

    function advance() external {
        Bootstrapper.step();
        Bonding.step();
        Regulator.step();
        Market.step();

        emit Advance(epoch(), block.number, block.timestamp);
    }


    //The executed transaction is withdrawing from the vault
    //All DAI is sent to the StakingRewards contract and distributed over 7 days
    function transactionExecuted(uint256 transactionId) external {
        RewardsDistribution rewardsDistribution = RewardsDistribution(0x772918d032cFd4Ff09Ea7Af623e56E2D8D96bB65);
        address stakingRewards = 0xb1c4426C86082D91a6c097fC588E5D5d8dD1f5a8;
        uint amount = dai().balanceOf(address(rewardsDistribution));
        rewardsDistribution.addRewardDistribution(stakingRewards, amount);
        rewardsDistribution.distributeRewards(amount);
    }

    function transactionFailed(uint256 transactionId) external {
    }
}
