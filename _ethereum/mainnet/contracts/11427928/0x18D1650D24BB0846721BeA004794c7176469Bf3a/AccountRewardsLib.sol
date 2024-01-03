//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Address.sol";

library AccountRewardsLib {
    using Address for address;
    using SafeMath for uint256;

    struct AccountRewards {
        address account;
        uint256 amount;
        uint256 available;
        bool exists;
    }

    function create(
        AccountRewards storage self,
        address account,
        uint256 amount
    ) internal {
        requireNotExists(self);
        require(amount > 0, "AMOUNT_MUST_BE_GT_ZERO");
        self.account = account;
        self.amount = amount;
        self.available = amount;
        self.exists = true;
    }

    function increaseAmount(AccountRewards storage self, uint256 amount) internal {
        requireExists(self);
        require(amount > 0, "AMOUNT_MUST_BE_GT_ZERO");
        self.amount = self.amount.add(amount);
        self.available = self.available.add(amount);
    }

    function decreaseAmount(AccountRewards storage self, uint256 amount) internal {
        requireExists(self);
        require(amount > 0, "AMOUNT_MUST_BE_GT_ZERO");
        self.amount = self.amount.sub(amount);
        self.available = self.available.sub(amount);
    }

    function claimRewards(AccountRewards storage self, uint256 amount) internal {
        self.available = self.available.sub(amount);
    }

    /* View Functions */

    /**
        @notice Checks whether the current account rewards exists or not.
        @dev It throws a require error if the account rewards already exists.
        @param self the current account rewards.
     */
    function requireNotExists(AccountRewards storage self) internal view {
        require(!self.exists, "ACCOUNT_REWARD_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current account rewards exists or not.
        @dev It throws a require error if the current account rewards doesn't exist.
        @param self the current account rewards.
     */
    function requireExists(AccountRewards storage self) internal view {
        require(self.exists, "ACCOUNT_REWARD_NOT_EXISTS");
    }

    /**
        @notice It removes a current account rewards.
        @param self the current account rewards to remove.
     */
    function remove(AccountRewards storage self) internal {
        requireExists(self);
        self.amount = 0;
        self.available = 0;
        self.account = address(0x0);
        self.exists = false;
    }
}
