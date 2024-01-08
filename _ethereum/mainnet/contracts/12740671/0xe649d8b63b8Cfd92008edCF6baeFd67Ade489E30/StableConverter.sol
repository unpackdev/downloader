// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IWeth.sol";

contract StableConverter {
    using SafeERC20 for IERC20;

    /**
     * @notice admin
     */
    address public admin;

    /**
     * @notice WETH token
     */
    address public immutable weth;

    /*** Events ***/

    /**
     * @notice Emitted when a conversion occured
     */
    event Convert(address indexed server, address indexed fromToken, address indexed toToken, uint fromAmount, uint toAmount);

    /**
     * @notice Emitted when a new admin is set
     */
    event AdminSet(address indexed admin);

    /**
     * @notice Emitted when admin seize tokens
     */
    event Seize(address indexed token, uint indexed amount);

    constructor(
        address _admin,
        address _weth
    ) {
        admin = _admin;
        weth = _weth;
    }

    modifier isAdmin() {
        require(msg.sender == admin, "only admin could perform the action");
        _;
    }

    /**
     * @notice Execute a series of tokens conversion according to the specified contract address.
     * @param token The token address list
     * @param token The contract address list
     * @param amount The conversion amount list
     */
    function convertMultiple(address[] calldata token, address[] calldata pair, uint[] calldata amount) external isAdmin() {
        require(token.length == amount.length, "invalid data");
        require(token.length == pair.length, "invalid data");

        for (uint i = 0; i < token.length; i++) {
             // if contract address not specified, no conversion
            if (pair[i] == address(0)) continue;
            // if contract is WETH and token is ETH, then convert to WETH
            if (pair[i] == weth && token[i] == address(0)) {
                convertEthToWeth(amount[i]);
            }
            convertWithPair(token[i], pair[i], amount[i]);
        }
    }

    /*** Internal functions ***/

    /**
     * @notice Convert token with the specified Swap V2 (Uni/Sushi) contract
     * @param token The input token address
     * @param pair The conversion contract address
     * @param amount The amount needs to be converted
     */
    function convertWithPair(address token, address pair, uint amount) internal {
        uint convertAmount = amount;
        // if maximum amount is specified, swap the balance only
        if (amount == type(uint).max) {
            convertAmount = IERC20(token).balanceOf(address(this));
        }
        swap(token, pair, convertAmount, address(this));
    }

    /**
     * @notice Calculate swap output amount based on input amount and reserves
     * @param amountIn The token amount to swap
     * @param reserveIn Reserve of input token in the pair
     * @param reserveOut Reserve of output token in the pair
     * @return amountOut Calculated swap output token amount
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @notice Convert ETH to WETH
     * @param amount The amount of ETH to be converted
     */
    function convertEthToWeth(uint amount) internal {
        IWeth(weth).deposit{value: amount}();
        emit Convert(msg.sender, address(0), weth, amount, amount);
    }

    /**
     * @notice Swap fromToken using the given pairAddress
     * @param fromToken The from token
     * @param pairAddress The swap contract address to swap with
     * @param amountIn The amount of fromToken needs to be swapped
     * @param to The receiver after the swap
     * @return amountOut The amount of toToken that will be sent to the receiver
     */
    function swap(address fromToken, address pairAddress, uint amountIn, address to) internal returns (uint amountOut) {
        address toToken;
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        require(address(pair) != address(0), "invalid pair");

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        if (fromToken == pair.token0()) {
            toToken = pair.token1();
            amountOut = getAmountOut(amountIn, reserve0, reserve1);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, address(this), new bytes(0));
        } else {
            toToken = pair.token0();
            amountOut = getAmountOut(amountIn, reserve1, reserve0);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, address(this), new bytes(0));
        }
        emit Convert(msg.sender, fromToken, toToken, amountIn, amountOut);
    }

    /*** Admin functions ***/

    /**
     * @notice Set the new admin.
     * @param newAdmin The new admin
     */
    function setAdmin(address newAdmin) external isAdmin() {
        admin = newAdmin;
        emit AdminSet(admin);
    }

    /**
     * @notice Seize token to admin.
     * @param token The token address. Empty address for Ether.
     * @param amount The amount to seize
     */
    function seize(address token, uint amount) external isAdmin() {
        if (token == address(0)) {
            payable(admin).transfer(amount);
        } else {
            IERC20(token).safeTransfer(admin, amount);
        }
        emit Seize(token, amount);
    }

    receive() external payable {}
}
