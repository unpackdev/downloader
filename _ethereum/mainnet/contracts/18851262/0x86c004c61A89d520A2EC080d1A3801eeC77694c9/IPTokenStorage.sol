// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IERC20MetadataUpgradeable.sol";

import "./IBucket.sol";
import "./IFeeExecutor.sol";
import "./IActivityRewardDistributor.sol";

interface IPTokenStorage is IERC20MetadataUpgradeable {
    struct Deposit {
        uint256 lockedBalance;
        uint256 deadline;
        uint256 id;
    }

    struct LockedBalance {
        uint256 totalLockedBalance;
        Deposit[] deposits;
    }

    function bucket() external view returns (IBucket);

    function interestIncreaser() external view returns (IFeeExecutor);

    function lenderRewardDistributor() external view returns (IActivityRewardDistributor);
}
