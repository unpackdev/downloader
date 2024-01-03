//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts

// Libraries
import "./Address.sol";

// Interfaces
import "./IRewardsMinter.sol";

abstract contract RewardsCalculatorBase {
    using Address for address;

    /* Constant Variables */

    /* State Variables */

    address private rewardsMinter;

    /* Modifiers */

    modifier onlyRewardsMinter(address account) {
        _requireOnlyRewardsMinter(account);
        _;
    }

    /* Constructor */

    /** View Functions */

    function _rewardsMinter() internal view returns (IRewardsMinter) {
        return IRewardsMinter(rewardsMinter);
    }

    function _requireOnlyRewardsMinter(address account) internal view {
        require(
            rewardsMinter != address(0x0) && account == rewardsMinter,
            "ACCOUNT_ISNT_REWARDS_MINTER"
        );
    }

    /* Internal Funtions */

    function _setRewardsMinter(address rewardsMinterAddress) internal {
        require(rewardsMinterAddress.isContract(), "REWARDS_MINTER_MUST_BE_CONTRACT");
        rewardsMinter = rewardsMinterAddress;
    }
}
