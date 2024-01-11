// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

// solhint-disable  avoid-low-level-calls

/// @title TransferHelpers library
/// @author UNIFARM
/// @notice handles token transfers and ethereum transfers for protocol
/// @dev all the functions are internally used in the protocol

library TransferHelpers {
    /**
     * @dev make sure about approval before use this function
     * @param target A ERC20 token address
     * @param sender sender wallet address
     * @param recipient receiver wallet Address
     * @param amount number of tokens to transfer
     */

    function safeTransferFrom(
        address target,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = target.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, amount));
        require(success && data.length > 0, 'STFF');
    }

    /**
     * @notice transfer any erc20 token
     * @param target ERC20 token address
     * @param to receiver wallet address
     * @param amount number of tokens to transfer
     */

    function safeTransfer(
        address target,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = target.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && data.length > 0, 'STF');
    }

    /**
     * @notice transfer parent chain token
     * @param to receiver wallet address
     * @param value of eth to transfer
     */

    function safeTransferParentChainToken(address to, uint256 value) internal {
        (bool success, ) = to.call{value: uint128(value)}(new bytes(0));
        require(success, 'STPCF');
    }
}
