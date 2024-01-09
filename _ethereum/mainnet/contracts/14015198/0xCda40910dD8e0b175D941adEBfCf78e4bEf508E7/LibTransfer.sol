// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";

/// @title LibTransfer
/// @notice Contains helper methods for interacting with ETH,
/// ERC-20 and ERC-721 transfers. Serves as a wrapper for all
/// transfers.
library LibTransfer {
    using SafeERC20 for IERC20;

    address constant ETHEREUM_PAYMENT_TOKEN = address(1);

    /// @notice Transfers tokens from contract to a recipient
    /// @dev If token is 0x0000000000000000000000000000000000000001, an ETH transfer is done
    /// @param _token The target token
    /// @param _recipient The recipient of the transfer
    /// @param _amount The amount of the transfer
    function safeTransfer(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal {
        if (_token == ETHEREUM_PAYMENT_TOKEN) {
            payable(_recipient).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_recipient, _amount);
        }
    }

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    function erc721SafeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
    }
}
