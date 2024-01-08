//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;
import "./IERC2612.sol";
import "./IDAI.sol";

/// @title TransferHelper
/// @dev Helper methods for interacting with ERC20 tokens and sending ETH
library TransferHelper {
    address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    struct Permit {
        uint256 value;
        uint256 nonce;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @dev Approval method with revert in case of failure
    /// @param token address of the token to approve
    /// @param to address to approve
    /// @param value amount to approve
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "APPROVE_FAILED"
        );
    }

    /// @dev Transfer method with revert in case of failure
    /// @param token address of the token to transfer
    /// @param to address to receive the tokens
    /// @param value amount to transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    /// @dev TransferFrom method with revert in case of failure
    /// @param token address of the token to transfer
    /// @param from address to move the tokens from
    /// @param to address to receive the tokens
    /// @param value amount to transfer
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FROM_FAILED"
        );
    }

    /// @dev transfer eth method with revert in case of failure
    /// @param to address that will receive ETH
    /// @param value amount of ETH to transfer
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    /// @dev permit method helper that will handle both known implementations
    // DAI vs ERC2612 tokens
    /// @param permitSignature bytes containing the encoded permit signature
    /// @param tokenAddress address of the token that will be permitted
    /// @param holder address that holds the tokens to be permitted
    /// @param spender address that will be permitted to spend the tokens
    function permit(
        Permit memory permitSignature,
        address tokenAddress,
        address holder,
        address spender
    ) internal {
        if (tokenAddress == DAI_ADDRESS) {
            IDAI(tokenAddress).permit(
                holder,
                spender,
                permitSignature.nonce,
                permitSignature.deadline,
                true,
                permitSignature.v,
                permitSignature.r,
                permitSignature.s
            );
        } else {
            IERC2612(tokenAddress).permit(
                holder,
                spender,
                permitSignature.value,
                permitSignature.deadline,
                permitSignature.v,
                permitSignature.r,
                permitSignature.s
            );
        }
    }
}
