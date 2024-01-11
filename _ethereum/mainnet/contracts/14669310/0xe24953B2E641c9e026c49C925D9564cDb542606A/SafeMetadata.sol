//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

library SafeMetadata {
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) =
            address(token).staticcall(
                abi.encodeWithSelector(IERC20Metadata.name.selector)
            );
        if (success) return abi.decode(data, (string));
        return "Token";
    }

    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) =
            address(token).staticcall(
                abi.encodeWithSelector(IERC20Metadata.symbol.selector)
            );
        if (success) return abi.decode(data, (string));
        return "TKN";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) =
            address(token).staticcall(
                abi.encodeWithSelector(IERC20Metadata.decimals.selector)
            );
        if (success && data.length >= 32) return abi.decode(data, (uint8));
        return 18;
    }
}
