//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Libraries
import "./SafeMath.sol";
import "./EnumerableSet.sol";

library UserInfoLib {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    uint256 private constant AMOUNT_SCALE = 1e12;

    // Info of each user.
    struct UserInfo {
        EnumerableSet.UintSet tokenIds;
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of TOKENs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    function hasTokenId(UserInfo storage self, uint256 tokenId) internal view returns (bool) {
        return self.tokenIds.contains(tokenId);
    }

    function getTotalTokens(UserInfo storage self) internal view returns (uint256) {
        return self.tokenIds.length();
    }

    function getTokenIdAt(UserInfo storage self, uint256 index) internal view returns (uint256) {
        return self.tokenIds.at(index);
    }

    function getTokenIds(UserInfo storage self) internal view returns (uint256[] memory tokenIDs) {
        tokenIDs = new uint256[](self.tokenIds.length());
        for (uint256 indexAt = 0; indexAt < self.tokenIds.length(); indexAt++) {
            tokenIDs[indexAt] = self.tokenIds.at(indexAt);
        }
        return tokenIDs;
    }

    function requireHasTokenId(UserInfo storage self, uint256 tokenId) internal view {
        require(hasTokenId(self, tokenId), "ACCOUNT_DIDNT_STAKE_TOKEN_ID");
    }

    function addTokenId(UserInfo storage self, uint256 tokenId) internal {
        self.tokenIds.add(tokenId);
    }

    function removeTokenId(UserInfo storage self, uint256 tokenId) internal {
        self.tokenIds.remove(tokenId);
    }

    function stake(
        UserInfo storage self,
        uint256 valuedAmountOrId,
        uint256 accTokenPerShare
    ) internal {
        self.amount = self.amount.add(valuedAmountOrId);
        self.rewardDebt = self.amount.mul(accTokenPerShare).div(AMOUNT_SCALE);
    }

    function unstake(
        UserInfo storage self,
        uint256 valuedAmountOrId,
        uint256 accTokenPerShare
    ) internal {
        self.amount = self.amount.sub(valuedAmountOrId);
        self.rewardDebt = self.amount.mul(accTokenPerShare).div(AMOUNT_SCALE);
    }

    function emergencyUnstakeAll(UserInfo storage self) internal {
        self.amount = 0;
        self.rewardDebt = 0;
    }

    function cleanTokenIDs(UserInfo storage self) internal {
        delete self.tokenIds;
    }
}
