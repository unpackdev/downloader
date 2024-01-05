// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./SinglePlus.sol";
import "./ICToken.sol";
import "./IForTubeReward.sol";
import "./IForTubeBank.sol";
import "./IUniswapRouter.sol";

/**
 * @dev Single Plus for Aave v2 WBTC.
 */
contract AaveWBTCPlus is SinglePlus {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    address public constant AAVE_WBTC = address(0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656);

    /**
     * @dev Initializes aWBTC+.
     */
    function initialize() public initializer {
        SinglePlus.initialize(AAVE_WBTC, "", "");
    }

    /**
     * @dev Checks whether a token can be salvaged via salvageToken(). Only aWBTC is not salvagable.
     * @param _token Token to check salvageability.
     */
    function _salvageable(address _token) internal view virtual override returns (bool) {
        return _token != AAVE_WBTC;
    }
}