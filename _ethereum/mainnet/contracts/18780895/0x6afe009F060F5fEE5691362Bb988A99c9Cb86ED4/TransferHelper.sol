// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./INativeToken.sol";
import "./TransferHelperStorage.sol";

library TransferHelper {
    function initialize(address _nativeToken) internal {
        require(Storage.slot().nativeToken == address(0), "TransferHelper: Already initialized");
        Storage.slot().nativeToken = _nativeToken;
    }

    function nativeToken() internal view returns (address) {
        return Storage.slot().nativeToken;
    }

    function isNative(address _token) internal view returns (bool) {
        return _token == Storage.slot().nativeToken;
    }

    function depositAssets(
        address _token,
        address _payer,
        address _receiver,
        uint256 _amount
    ) internal {
        if (address(_token) == Storage.slot().nativeToken) {
            convertToWrappedToken(_receiver, _amount);
        } else {
            safeTransferFrom(_token, _payer, _receiver, _amount);
        }
    }

    function withdrawAssets(address _token, address _receiver, uint256 _amount) internal {
        if (address(_token) == Storage.slot().nativeToken) {
            convertFromWrappedToken(_receiver, _amount);
        } else {
            safeTransfer(_token, _receiver, _amount);
        }
    }

    function convertToWrappedToken(address _receiver, uint256 _amount) internal {
        require(address(this).balance >= _amount, "TransferHelper: Insufficient balance");

        INativeToken(Storage.slot().nativeToken).deposit{value: _amount}();
        safeTransfer(Storage.slot().nativeToken, _receiver, _amount);
    }

    function convertFromWrappedToken(address _receiver, uint256 _amount) internal {
        uint256 balance = INativeToken(Storage.slot().nativeToken).balanceOf(address(this));
        require(balance >= _amount, "TransferHelper: Insufficient balance");

        if (balance > 0) {
            INativeToken(Storage.slot().nativeToken).withdraw(_amount);
            safeTransferETH(_receiver, _amount);
        }
    }

    /// @dev Transfer helper from UniswapV2 Router
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    /**
     * There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
     * Im trying to make it a habit to put external calls last (reentrancy)
     * You can put this in an internal function if you like.
     */
    function safeTransfer(address token, address to, uint256 amount) internal {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) = token.call(
            // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        ); // ERC20 Transfer failed
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}
