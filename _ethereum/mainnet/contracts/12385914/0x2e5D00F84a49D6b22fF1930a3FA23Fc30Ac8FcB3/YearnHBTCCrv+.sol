// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IYearnV2Vault.sol";
import "./SinglePlus.sol";

/**
 * @dev Single Plus for Yearn HBTCCrv vault.
 */
contract YearnHBTCCrvPlus is SinglePlus {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    address public constant YEARN_HBTCCRV = address(0x625b7DF2fa8aBe21B0A976736CDa4775523aeD1E);

    /**
     * @dev Initializes yHBTCCrv+.
     */
    function initialize() public initializer {
        SinglePlus.initialize(YEARN_HBTCCRV, "", "");
    }

    /**
     * @dev Returns the amount of single plus token is worth for one underlying token, expressed in WAD.
     */
    function _conversionRate() internal view virtual override returns (uint256) {
        return IYearnV2Vault(YEARN_HBTCCRV).pricePerShare();
    }
}