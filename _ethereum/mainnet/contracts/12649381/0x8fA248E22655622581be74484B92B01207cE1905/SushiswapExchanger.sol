// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.4;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IUniswapV2Router02.sol";

import "./FeeExchanger.sol";
import "./IFeeDistributor.sol";

/**
 * @author Asaf Silman
 * @title FeeExchanger using Sushiswap
 * @dev This contract is upgradable and should be deployed using Openzeppelin upgrades
 * @notice Exchanges fees for `outputToken` and forwards to `outputAddress`
 */
contract SushiswapExchanger is FeeExchanger {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    // Sushiswap router is implmenented using the uniswap interface
    IUniswapV2Router02 private _sushiswapRouter;
    address[] private _path;

    string constant _name = "Sushiswap Exchanger";

    /**
     * @notice Initialises the Sushiswap Exchanger contract.
     * @dev Most of the initialisation is done as part of the `FeeExchanger` initialisation.
     * @dev This method sets the internal sushiswap router address.
     * @dev This method also initialises the router path.
     * @param routerAddress The address of the sushiswap router.
     * @param inputToken The token which the protocol fees are generated in. This should set to the WETH address.
     * @param outputToken The token which this contract will exchange fees into.
     * @param outputAddress The address where fees will be redirected to.
     */
    function initialize(IUniswapV2Router02 routerAddress, IERC20Upgradeable inputToken, IERC20Upgradeable outputToken, address outputAddress) public initializer {
        FeeExchanger.__FeeExchanger_init(inputToken, outputToken, outputAddress);

        _sushiswapRouter = routerAddress;

        _path = new address[](2);
        _path[0] = address(inputToken);
        _path[1] = address(outputToken);
    }

    /**
     * @notice Exchanges fees on sushiswap
     * @dev This method validates the minAmountOut was transfered to the output address.
     * @dev The expiration time is hardcoded to 1800 seconds, or 30 minutes.
     * @dev This method can only be called by an approved exchanger, see FeeExchanger.sol for more info.
     * @dev This method can be static called to analyse the output amount of tokens at a given time.
     * @param amountIn The input amount of fees to swap.
     * @param minAmountOut The minimum output amount of tokens to receive after the swap has executed.
     * @return The amount of output token which was exchanged
     */
    function exchange(uint256 amountIn, uint256 minAmountOut) nonReentrant onlyExchanger external override returns (uint256) {
        require(FeeExchanger._inputToken.balanceOf(address(this)) >= amountIn, "FE: AMOUNT IN");

        // Approve input token for swapping
        FeeExchanger._inputToken.safeIncreaseAllowance(address(_sushiswapRouter), amountIn);
        
        uint256 balance0 = FeeExchanger._outputToken.balanceOf(address(this));
        
        // Swap tokens using sushi
        _sushiswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          amountIn,
          minAmountOut, 
          _path,
          address(this),
          block.timestamp + 1800
        );

        uint256 balance1 = FeeExchanger._outputToken.balanceOf(address(this));
        uint256 amountOut = balance1 - balance0;

        // Approve output token to call `burn` on feeDistributor
        // Note, burn will transfer the entire balance of outputToken
        FeeExchanger._outputToken.safeIncreaseAllowance(address(FeeExchanger._outputAddress), balance1);
        // Deposit output token via `burn`
        IFeeDistributor(FeeExchanger._outputAddress).burn(address(FeeExchanger._outputToken));

        emit TokenExchanged(amountIn, amountOut, _name);

        return amountOut;
    }

    /**
     * @notice Updates the swapping path for the router.
     * @dev The first element of the path must be the input token.
     * @dev The last element of the path must be the output token.
     * @dev This method is only callable by an exchanger.
     * @param newPath The new router path.
     */
    function updatePath(address[] memory newPath) onlyExchanger external {
        require(newPath[0]==address(FeeExchanger._inputToken), "FE: PATH INPUT");
        require(newPath[newPath.length-1]==address(FeeExchanger._outputToken), "FE: PATH OUTPUT");

        _path = newPath;
    }

    /**
     * @notice View function to return the router path.
     * @return The router path.
     */
    function getPath() external view returns (address[] memory) {
        return _path;
    }
}
