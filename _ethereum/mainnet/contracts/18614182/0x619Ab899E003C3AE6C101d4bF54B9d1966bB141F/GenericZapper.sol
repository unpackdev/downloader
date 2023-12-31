// SPDX-License-Identifier: CC BY-NC-ND 4.0
pragma solidity ^0.8.19;

import "./IGenericZapper.sol";
import "./MultiPoolStrategy.sol";
import "./Context.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

/**
 * @title GenericZapper
 * @dev This contract allows users to deposit and redeem into a MultiPoolStrategy contract using any ERC-20 token.
 * It swaps the given token using Li.Fi (given data) to the underliying asset
 * and interacts with the MultiPoolStrategy contract to perform the operations.
 */
contract GenericZapper is Context, IGenericZapper {
    error SwapFailed();
    error AmountBelowMinimum();
    
    /// @notice Address of the LIFI diamond
    address public constant LIFI_DIAMOND = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;

    event Deposited(address sender, address receiver, address underlyingAsset, uint256 underlyingAmount);
    event Redeemed(address sender, address receiver, address underlyingAsset, uint256 underlyingAmount);

    /**
     * @inheritdoc IGenericZapper
     */
    function deposit(
        uint256 amount,
        address token,
        uint256 toAmountMin,
        address receiver,
        address strategyAddress,
        bytes calldata swapTx
    )
        external
        returns (uint256 shares)
    {
        MultiPoolStrategy multiPoolStrategy = MultiPoolStrategy(strategyAddress);

        // check if the reciever is not zero address
        if (receiver == address(0)) revert ZeroAddress();
        // check if the amount is not zero
        if (amount == 0) revert EmptyInput();

        address underlyingAsset = multiPoolStrategy.asset();

        // transfer tokens to this contract
        uint256 underlyingBalanceBefore = IERC20(underlyingAsset).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(token), _msgSender(), address(this), amount);

        // swap for the underlying asset
        if(token != underlyingAsset) {
            SafeERC20.safeApprove(IERC20(token), LIFI_DIAMOND, 0);
            SafeERC20.safeApprove(IERC20(token), LIFI_DIAMOND, amount);
            (bool success,) = LIFI_DIAMOND.call(swapTx);
            if (!success) revert SwapFailed();
        }

        uint256 underlyingBalanceAfter = IERC20(underlyingAsset).balanceOf(address(this));
        uint256 underlyingAmount = underlyingBalanceAfter - underlyingBalanceBefore;

        if (underlyingAmount == 0) revert EmptyInput();
        if (underlyingAmount < toAmountMin) revert AmountBelowMinimum();

        // we need to approve the strategy to spend underlying asset
        SafeERC20.safeApprove(IERC20(underlyingAsset), strategyAddress, 0);
        SafeERC20.safeApprove(IERC20(underlyingAsset), strategyAddress, underlyingAmount);

        // deposit
        shares = multiPoolStrategy.deposit(underlyingAmount, address(this));
        emit Deposited(_msgSender(), receiver, underlyingAsset, underlyingAmount);

        // transfer shares to receiver
        SafeERC20.safeTransfer(IERC20(strategyAddress), receiver, shares);

        return shares;
    }

    /**
     * @inheritdoc IGenericZapper
     */
    function redeem(
        uint256 sharesAmount,
        uint256 toAmountMin,
        address receiver,
        address strategyAddress
    )
        external
        returns (uint256 underlyingAmount)
    {
        MultiPoolStrategy multiPoolStrategy = MultiPoolStrategy(strategyAddress);
        
        // check if the reciever is not zero address
        if (receiver == address(0)) revert ZeroAddress();
        // check if the amount is not zero
        if (sharesAmount == 0) revert EmptyInput();

        address underlyingAsset = multiPoolStrategy.asset();

        underlyingAmount = multiPoolStrategy.redeem(sharesAmount, address(this), _msgSender(), toAmountMin);

        SafeERC20.safeTransfer(IERC20(underlyingAsset), receiver, underlyingAmount);

        emit Redeemed(_msgSender(), receiver, underlyingAsset, underlyingAmount);
    }
}