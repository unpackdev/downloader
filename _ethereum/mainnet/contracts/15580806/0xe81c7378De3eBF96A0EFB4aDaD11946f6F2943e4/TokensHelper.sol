// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TokensHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransferFrom: transfer failed");
    }

    function safeTransferNativeTokens(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "safeTransferNativeTokens: transfer failed");
    }

    function safeMint(
        address token,
        address to,
        uint256 amount
    ) internal {
        // bytes4(keccak256(bytes("mint(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x40c10f19, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeMint: mint failed");
    }

    function safeBurn(address token, uint256 amount) internal {
        // bytes4(keccak256(bytes("burn(uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x42966c68, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeBurn: burn failed");
    }

    function safeBurnFrom(
        address token,
        address from,
        uint256 amount
    ) internal {
        // bytes4(keccak256(bytes("burnFrom(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x79cc6790, from, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeBurnFrom: burn failed");
    }
}
