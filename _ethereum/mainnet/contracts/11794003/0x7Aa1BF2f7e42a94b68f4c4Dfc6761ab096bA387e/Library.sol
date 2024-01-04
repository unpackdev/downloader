// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./SafeMath.sol";

struct RewardLocalVars {
    uint256 newReward;
    uint256 accountReward;
    uint256 accountBalance;
    uint256 rewardBlockNumber;
    uint256 blockNumber;
    uint256 diffBlock;
    uint256 rewardPerBlock;
    uint256 totalSupply;
}

struct SpentLocalVars {
    uint amount;
    uint256 currencyPrice;
    uint256 assetTokenPrice;
}

struct AmountLocalVars {
    uint256 spent;
    uint256 currencyPrice;
    uint256 assetTokenPrice;
}

library AssetTokenLibrary {
    using SafeMath for uint256;

    function getReward(RewardLocalVars memory self)
        internal
        pure
        returns (uint256)
    {
        if (
            self.rewardBlockNumber != 0 &&
            self.blockNumber > self.rewardBlockNumber
        ) {
            self.diffBlock = self.blockNumber.sub(self.rewardBlockNumber);
            self.newReward = self
                .accountBalance
                .mul(self.diffBlock)
                .mul(self.rewardPerBlock)
                .div(self.totalSupply);
        }
        return self.accountReward.add(self.newReward);
    }

    function getSpent(SpentLocalVars memory self)
        internal
        pure
        returns (uint)
    {
        return self.amount.mul(self.assetTokenPrice).div(self.currencyPrice);
    }

    function getAmount(AmountLocalVars memory self)
        internal
        pure
        returns (uint)
    {
        return self.spent.mul(self.currencyPrice).div(self.assetTokenPrice);
    }
}
