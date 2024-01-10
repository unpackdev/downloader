// SPDX-License-Identifier: NONE
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IVault.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IBalancerTrader.sol";
import "./console.sol";

interface IPoolV1 {
    function swapExactAmountIn(address tokenIn, uint256 tokenAmountIn, address tokenOut, uint256 minAmountOut, uint256 maxPrice) external returns (uint256 tokensOut, uint256 newPrice);
}

interface IWETH9 is IERC20 {
    function withdraw(uint256 wad) external;
    function deposit() external payable;
}

contract BalancerTrader is IBalancerTrader {

    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT = type(uint256).max;

    IERC20 public constant amplToken = IERC20(0xD46bA6D942050d489DBd938a2C909A5d5039A161);
    IWETH9 public constant wethToken = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IPoolV1 public constant amplEth = IPoolV1(0xa751A143f8fe0a108800Bfb915585E4255C2FE80);
    IVault public constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    
    IERC20 public immutable eefiToken;
    bytes32 public immutable eefiethPoolID;

    constructor(IERC20 _eefiToken, bytes32 _eefiethPoolID) {
        require(address(_eefiToken) != address(0), "BalancerTrader: Invalid eefi token address");
        eefiToken = IERC20(_eefiToken);
        eefiethPoolID = _eefiethPoolID;
        require(amplToken.approve(address(amplEth), MAX_UINT), 'BalancerTrader: Approval failed');
    }

    receive() external payable {
        // make sure we accept only eth coming from unwrapping weth
        require(msg.sender == address(wethToken),"BalancerTrader: Not accepting ETH");
    }

    /**
    * @dev Caller must transfer the right amount of tokens to the trader
    * @param amount Amount of AMPL to sell
    * @param minimalExpectedAmount The minimal expected amount of eth
     */
    function sellAMPLForEth(uint256 amount, uint256 minimalExpectedAmount) external override returns (uint256 ethAmount) {
        require(amplToken.transferFrom(msg.sender, address(this), amount),"BalancerTrader: transferFrom failed");
        (ethAmount,) = amplEth.swapExactAmountIn(address(amplToken), amount, address(wethToken), minimalExpectedAmount, MAX_UINT);
        wethToken.withdraw(ethAmount);
        Address.sendValue(msg.sender, ethAmount);
        emit Sale_ETH(amount, ethAmount);
    }

    /**
    * @dev Caller must transfer the right amount of tokens to the trader (USDC will be replaced with ETH)
    * @param amount Amount of AMPL to sell
    * @param minimalExpectedAmount The minimal expected amount of EEFI
     */
    function sellAMPLForEEFI(uint256 amount, uint256 minimalExpectedAmount) external override returns (uint256 eefiAmount) {
        require(amplToken.transferFrom(msg.sender, address(this), amount),"BalancerTrader: transferFrom failed");
        (uint256 ethAmount,) = amplEth.swapExactAmountIn(address(amplToken), amount, address(wethToken), 0, MAX_UINT);
        wethToken.approve(address(vault), ethAmount);
        eefiAmount = vault.swap(
        IVault.SingleSwap(
            eefiethPoolID,
            IVault.SwapKind.GIVEN_IN,
            IAsset(address(wethToken)),
            IAsset(address(eefiToken)),
            ethAmount,
            "0x"
        ),
        IVault.FundManagement(
            address(this),
            false,
            msg.sender,
            false),
            0, block.timestamp);
        if(eefiAmount < minimalExpectedAmount) {
            revert("BalancerTrader: minimalExpectedAmount not acquired");
        }
        emit Sale_EEFI(amount, eefiAmount);
    }
}
