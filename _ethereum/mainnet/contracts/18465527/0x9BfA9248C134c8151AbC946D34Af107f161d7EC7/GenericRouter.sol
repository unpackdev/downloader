// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct Hop {
    address router;
    bytes data;
}

contract GenericRouter {
    function multihop(address _token, Hop[] calldata hops) public view returns (address token, uint256 amountOut) {
        uint256 length = hops.length;

        for (uint32 i; i < length; ++i) {
            Hop memory hop = hops[i];

            // Each payload consists of the amountIn + the path, thus
            // we need to replace the amountIn with the previous result.
            bytes memory data = i == 0 ? hop.data : replaceAmountsIn(hop.data, amountOut);

            // Call the router with the payload.
            (bool success, bytes memory callResult) = hop.router.staticcall(data);
            require(success, "Multihop failed");

            // Decode the result.
            uint256[] memory amounts = abi.decode(callResult, (uint256[]));
            require(amounts.length > 0, "Invalid result");
            amountOut = amounts[amounts.length - 1];
        }

        // We return the token to make it easier to flag results when using multicall.
        return (_token, amountOut);
    }

    function replaceAmountsIn(bytes memory data, uint256 amountIn) internal pure returns (bytes memory) {
        // 0xd06ca61f
        // 0000000000000000000000000000000000000000000000000de0b6b3a7640000 -> 1 ether
        // 0000000000000000000000000000000000000000000000000000000000000040
        // 0000000000000000000000000000000000000000000000000000000000000002
        // 000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
        // 000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

        bytes memory result;
        assembly {
            result := data
            mstore(add(result, 36), amountIn)
        }
        return result;
    }
}
