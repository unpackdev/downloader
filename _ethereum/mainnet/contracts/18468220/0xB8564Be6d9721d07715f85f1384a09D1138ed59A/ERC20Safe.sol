// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import "./IERC20.sol";
import "./ERC20Burnable.sol";

/**
    @title Manages deposited ERC20s.
    @author Stafi Protocol.
    @notice This contract is intended to be used with ERC20Handler contract.
 */
contract ERC20Safe {

    /**
        @notice Used to gain custody of deposited token.
        @param tokenAddress Address of ERC20 to transfer.
        @param owner Address of current token owner.
        @param recipient Address to transfer tokens to.
        @param amount Amount of tokens to transfer.
     */
    function lockERC20(address tokenAddress, address owner, address recipient, uint256 amount) internal {
        IERC20 erc20 = IERC20(tokenAddress);
        _safeTransferFrom(erc20, owner, recipient, amount);
    }

    /**
        @notice Transfers custody of token to recipient.
        @param tokenAddress Address of ERC20 to transfer.
        @param recipient Address to transfer tokens to.
        @param amount Amount of tokens to transfer.
     */
    function releaseERC20(address tokenAddress, address recipient, uint256 amount) internal {
        IERC20 erc20 = IERC20(tokenAddress);
        _safeTransfer(erc20, recipient, amount);
    }

    /**
        @notice Used to create new ERC20s.
        @param tokenAddress Address of ERC20 to transfer.
        @param recipient Address to mint token to.
        @param amount Amount of token to mint.
     */
    function mintERC20(address tokenAddress, address recipient, uint256 amount) internal {
        IERC20 erc20 = IERC20(tokenAddress);
        _safeTransferFrom(erc20, address(0), recipient, amount);
    }

    /**
        @notice Used to burn ERC20s.
        @param tokenAddress Address of ERC20 to burn.
        @param owner Current owner of tokens.
        @param amount Amount of tokens to burn.
     */
    function burnERC20(address tokenAddress, address owner, uint256 amount) internal {
        ERC20Burnable erc20 = ERC20Burnable(tokenAddress);
        erc20.burnFrom(owner, amount);
    }

    /**
        @notice used to transfer ERC20s safely
        @param token Token instance to transfer
        @param to Address to transfer token to
        @param value Amount of token to transfer
     */
    function _safeTransfer(IERC20 token, address to, uint256 value) private {
        require(token.transfer(to, value), "ERC20: transfer failed");
    }

    /**
        @notice used to transfer ERC20s safely
        @param token Token instance to transfer
        @param from Address to transfer token from
        @param to Address to transfer token to
        @param value Amount of token to transfer
     */
    function _safeTransferFrom(IERC20 token, address from, address to, uint256 value) private {
        require(token.transferFrom(from, to, value), "ERC20: transferFrom failed");
    }
}
