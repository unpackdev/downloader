// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

import "./IGenericMintableTo.sol";
import "./IGenericBurnableFrom.sol";

/**
 * @dev Interface of the IMintableTokenUpgradeable standard
 */
interface IMintableTokenUpgradeable is IGenericMintableTo, IERC20Upgradeable {

}

/**
 * @dev Interface of the IMintableBurnableTokenUpgradeable standard
 */
interface IMintableBurnableTokenUpgradeable is IMintableTokenUpgradeable, IGenericBurnableFrom {

}
