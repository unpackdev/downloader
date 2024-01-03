// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IUniswapV2Pair.sol";

contract UniswapAware {
    address public uniswapEthPair;
    IUniswapV2Pair public uniswapPairImpl;

    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    constructor() public {
        uniswapEthPair = pairFor(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            address(this)
        );
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) public pure returns (address pair) {
        (address token0, address token1) =
            tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                    )
                )
            )
        );
    }

    modifier onlyAfterUniswap() {
        require(
            isContract(uniswapEthPair),
            "You can't perform this action until the Uniswap listing"
        );
        _;
    }

    modifier onlyBeforeUniswap() {
        require(
            !isContract(uniswapEthPair),
            "You can't perform this action after the Uniswap listing"
        );
        _;
    }
}
