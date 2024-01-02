// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC20Upgradeable.sol";
import "./ERC165Upgradeable.sol";

import "./Errors.sol";

import "./IDebtTokenStorage.sol";

abstract contract DebtTokenStorage is IDebtTokenStorage, ERC20Upgradeable, ERC165Upgradeable {
    IBucket public override bucket;
    IFeeExecutor public override feeDecreaser;
    IActivityRewardDistributor public override traderRewardDistributor;
    address internal bucketsFactory;
    uint8 internal _tokenDecimals;
}
