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

import "./SafeMath.sol";
import "./Setters.sol";
import "./IERC20Mintable.sol";
import "./Require.sol";

contract Comptroller is Setters {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Comptroller";

    function mintToAccount(address account, uint256 amount) internal {
        dollar().mint(account, amount);
        balanceCheck();
    }

    function increaseSupply(uint256 newSupply) internal returns (uint256, uint256) {
        // QSD #7
        // If we're still bootstrapping
        if (bootstrappingAt(epoch().sub(1))) {
            uint256 rewards = newSupply.div(2);

            // 50% to Bonding (auto-compounding)
            mintToPoolLP(rewards);

            // 50% to Liquidity
            mintToDAO(rewards);

            // Redeemable always 0 since we don't have any coupon mechanism
            // Bonded will always be the new supply as well
            return (0, newSupply);
        } else {
            // QSD #B

            // 0-a. Pay out to Pool (LP)
            uint256 poolLPReward = newSupply.mul(Constants.getPoolLPRatio()).div(100);
            mintToPoolLP(poolLPReward);

            // 0-b. Pay out to Pool (Bonding)
            uint256 poolBondingReward = newSupply.mul(Constants.getPoolBondingRatio()).div(100);
            mintToPoolBonding(poolBondingReward);

            // 0-c. Pay out to Treasury
            uint256 treasuryReward = newSupply.mul(Constants.getTreasuryRatio()).div(100);
            mintToTreasury(treasuryReward);

            // 0-d. Pay out to Gov Stakers
            uint256 govStakerReward = newSupply.mul(Constants.getGovStakingRatio()).div(100);
            mintToPoolGov(govStakerReward);

            balanceCheck();
            return (0, newSupply);
        }
    }

    function distributeGovernanceTokens() internal {
        // Assume blocktime is 15 seconds
        uint256 blocksPerEpoch = Constants.getCurrentEpochStrategy().period.div(15);
        uint256 govTokenToMint = blocksPerEpoch.mul(Constants.getGovernanceTokenPerBlock());

        uint256 maxSupply = Constants.getGovernanceTokenMaxSupply();
        uint256 totalSupply = governance().totalSupply();

        // Maximum of 999,999,999 tokens
        if (totalSupply.add(govTokenToMint) >= maxSupply) {
            govTokenToMint = maxSupply.sub(totalSupply);
        }

        // Mint Governance token to pool bonding
        mintGovTokensToPoolBonding(govTokenToMint);
    }

    function balanceCheck() private {
        Require.that(
            dollar().balanceOf(address(this)) >= totalBonded().add(totalStaged()),
            FILE,
            "Inconsistent balances"
        );
    }

    /**
     * Dollar functions
     */

    function mintToDAO(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(address(this), amount);
            incrementTotalBonded(amount);
        }
    }

    function mintToPoolLP(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(poolLP(), amount);
        }
    }

    function mintToPoolBonding(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(poolBonding(), amount);
        }
    }

    function mintToPoolGov(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(poolGov(), amount);
        }
    }

    function mintToTreasury(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(Constants.getTreasuryAddress(), amount);
        }
    }

    /**
     * Governance token functions
     */

    function mintGovTokensToPoolBonding(uint256 amount) private {
        if (amount > 0) {
            IERC20Mintable(address(governance())).mint(poolBonding(), amount);
        }
    }
}
