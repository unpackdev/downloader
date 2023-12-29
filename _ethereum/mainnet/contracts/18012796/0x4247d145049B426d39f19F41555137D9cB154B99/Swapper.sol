// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Owned2Step.sol";
import "./SafeTransferLib.sol";
import "./Errors.sol";
import "./Allowance.sol";

/// @author 0xtekgrinder
/// @title Swapper contract
/// @notice Contract to manage swaps using a router/aggregator
contract Swapper is Owned2Step {
    using SafeTransferLib for ERC20;

    /**
     *  @notice Event emitted when the swap router is updated
     */
    event SwapRouterUpdated(address oldSwapRouter, address newSwapRouter);
    /**
     *  @notice Event emitted when the token proxy is updated
     */
    event TokenTransferAddressUpdated(address oldTokenTransferAddress, address newTokenTransferAddress);
    /**
     *  @notice Event emitted when the vault is updated
     */
    event VaultUpdated(address oldVault, address newVault);

    /*//////////////////////////////////////////////////////////////
                            MUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Dex/aggregaor router to call to perform swaps
     */
    address public swapRouter;
    /**
     * @notice Address to allow to swap tokens
     */
    address public tokenTransferAddress;
    /**
     * @notice Address of the ERC4626 vault
     */
    address public vault;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyVault() {
        if (msg.sender != vault) revert Errors.NotVault();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address initialOwner, address initialSwapRouter, address initialTokenTransferAddress)
        Owned2Step(initialOwner)
    {
        if (initialSwapRouter == address(0) || initialTokenTransferAddress == address(0)) revert Errors.ZeroAddress();

        swapRouter = initialSwapRouter;
        tokenTransferAddress = initialTokenTransferAddress;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the dex/aggregator router to call to perform swaps
     * @param newSwapRouter address of the router
     * @custom:requires owner
     */
    function setSwapRouter(address newSwapRouter) external onlyOwner {
        if (newSwapRouter == address(0)) revert Errors.ZeroAddress();

        address oldSwapRouter = swapRouter;
        swapRouter = newSwapRouter;

        emit SwapRouterUpdated(oldSwapRouter, newSwapRouter);
    }

    /**
     * @notice Set the token proxy address to allow to swap tokens
     * @param newTokenTransferAddress address of the token proxy
     * @custom:requires owner
     */
    function setTokenTransferAddress(address newTokenTransferAddress) external onlyOwner {
        if (newTokenTransferAddress == address(0)) revert Errors.ZeroAddress();

        address oldtokenTransferAddress = tokenTransferAddress;
        tokenTransferAddress = newTokenTransferAddress;

        emit TokenTransferAddressUpdated(oldtokenTransferAddress, newTokenTransferAddress);
    }

    /**
     * @notice Set the vault address
     * @param newVault address of the vault
     * @custom:requires owner
     */
    function setVault(address newVault) external onlyOwner {
        if (newVault == address(0)) revert Errors.ZeroAddress();

        address oldVault = vault;
        vault = newVault;

        emit VaultUpdated(oldVault, newVault);
    }

    /**
     * @notice Recover ERC2O tokens in the contract
     * @dev Recover ERC2O tokens in the contract
     * @param token Address of the ERC2O token
     * @return bool: success
     * @custom:requires owner
     */
    function recoverERC20(address token) external onlyOwner returns (bool) {
        if (token == address(0)) revert Errors.ZeroAddress();

        uint256 amount = ERC20(token).balanceOf(address(this));
        if (amount == 0) revert Errors.ZeroValue();

        ERC20(token).safeTransfer(owner, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            SWAP LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Swap tokens using the router/aggregator
     * @dev The calldatas should set the recipient of the tokens to the vault
     * @param tokens array of tokens to swap
     * @param callDatas array of bytes to call the router/aggregator
     */
    function swap(address[] calldata tokens, bytes[] calldata callDatas) external onlyVault {
        uint256 length = tokens.length;

        for (uint256 i; i < length;) {
            address token = tokens[i];
            Allowance._approveTokenIfNeeded(token, tokenTransferAddress);
            _performRouterSwap(callDatas[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Perform the swap using the router/aggregator
     * @param callData bytes to call the router/aggregator
     */
    function _performRouterSwap(bytes calldata callData) internal {
        (bool success, bytes memory retData) = swapRouter.call(callData);

        if (!success) {
            if (retData.length != 0) {
                assembly {
                    revert(add(32, retData), mload(retData))
                }
            }
            revert Errors.SwapError();
        }
    }
}
