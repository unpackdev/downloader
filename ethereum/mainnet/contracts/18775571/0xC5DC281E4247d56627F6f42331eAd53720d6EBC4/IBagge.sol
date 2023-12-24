// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Local Imports
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

// NPM Imports
import "./Ownable.sol";
import "./Context.sol";
import "./IERC20.sol";

/**
 * @title IBaggeToken ~ Bagge interface, containing imports, error types custom events.
 * @author LTL & M2xM ~ Your trust worthy devs.
 * @notice
 */
interface IBAGGE is IERC20 {
    /**
     * triggered when wallet limits are revised.
     * @param value New limits.
     */
    event WalletLimitsRevised(uint value);

    /**
     * triggered when wallet limits are revised.
     * @param value New limits.
     */
    event TaxLimitsRevised(uint value);
}
