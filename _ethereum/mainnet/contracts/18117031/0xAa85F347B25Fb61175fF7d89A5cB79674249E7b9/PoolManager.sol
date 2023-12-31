// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IDittoPool.sol";
import "./OwnerTwoStep.sol";
import "./IPoolManager.sol";
import "./SafeTransferLib.sol";
import "./ERC20.sol";
import { ReentrancyGuard } from
    "../../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./IERC721.sol";

/**
 * @title PoolManager
 * @notice Base contract providing common functionality for all pool managers
 */
abstract contract PoolManager is IPoolManager, OwnerTwoStep, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    bool internal _initialized;

    IDittoPool public _dittoPool;

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error PoolManagerInitialized();
    error PoolManagerUnsupportedOperation();

    // ============================================================
    // =================== UTILITY FUNCTIONS ======================
    // ============================================================

    ///@inheritdoc IPoolManager
    function initialized() external view returns (bool) {
        return _initialized;
    }

    /**
     * @notice Extract tokens that may have been sent to this pool manager as fees
     * @param token ERC20 token contract address
     * @param recipient Address to send the tokens to
     * @param amount Value of tokens to send
     */
    function withdrawErc20(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner nonReentrant {
        ERC20(token).safeTransfer(recipient, amount);
    }

    /**
     * Convenience function to withdraw ERC721 tokens from the contract
     * @param tokenContract ERC721 token contract address
     * @param recipient Address to send the tokens to
     * @param tokenId ID of the token to send
     */
    function withdrawErc721(
        address tokenContract,
        address recipient,
        uint256 tokenId
    ) external onlyOwner nonReentrant {
        IERC721(tokenContract).safeTransferFrom(address(this), recipient, tokenId);
    }
}
