// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./BFacetOwner.sol";
import "./LibUniswapV2Swap.sol";
import "./GelatoString.sol";
import "./IUniswapV2Router02.sol";

contract UniswapV2SwapFacet is BFacetOwner {
    function uniswapV2TokenForETH(
        address inputToken,
        uint256 inputAmount,
        uint256 minReturn,
        address receiver
    ) external onlyOwner returns (uint256 bought) {
        bought = LibUniswapV2Swap.uniswapV2TokenForETH(
            inputToken,
            inputAmount,
            minReturn,
            receiver,
            true // should revert on failure
        );
    }

    function uniswapV2TokenForToken(
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 minReturn,
        address receiver
    ) external onlyOwner returns (uint256 bought) {
        bought = LibUniswapV2Swap.uniswapV2TokenForToken(
            inputToken,
            inputAmount,
            outputToken,
            minReturn,
            receiver,
            true // should revert on failure
        );
    }

    function setRouterAddress(address _newRouterAddress) external onlyOwner {
        LibUniswapV2Swap.setRouterAddress(_newRouterAddress);
    }

    function routerAddress() public view returns (address) {
        return LibUniswapV2Swap.routerAddress();
    }
}
