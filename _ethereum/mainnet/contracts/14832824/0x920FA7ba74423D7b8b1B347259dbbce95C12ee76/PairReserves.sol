// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./ERC165.sol";
import "./IUniswapV2Pair.sol";

import "./IPairReserves.sol";

/// @title Pair Reserves
/// @author Phuture Labs
/// @notice UniswapV2Router02 swap path helper
contract PairReserves is IPairReserves, ERC165 {
    /// @inheritdoc IPairReserves
    function getReserves(address[] calldata _pairs) external view override returns (Reserves[] memory reserves) {
        uint pairsCount = _pairs.length;
        reserves = new Reserves[](pairsCount);

        for (uint i; i < pairsCount; ) {
            if (_pairs[i].code.length != 0) {
                IUniswapV2Pair pair = IUniswapV2Pair(_pairs[i]);
                (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

                reserves[i] = Reserves({ token0: pair.token0(), reserve0: reserve0, reserve1: reserve1 });
            } else {
                reserves[i] = Reserves({ token0: address(0), reserve0: 0, reserve1: 0 });
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IPairReserves).interfaceId || super.supportsInterface(_interfaceId);
    }
}
