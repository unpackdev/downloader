//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";

/**
 * @title Myobu Shrine Contract (V2)
 * @author Myobu Devs
 */
contract ShrineV2 {
    /**
     * @dev
     * WETH: Wrapped ether contract
     * PAIR: The Uniswap V2 Pair for Myobu - WETH
     */
    IWETH private constant WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    IUniswapV2Pair private constant PAIR =
        IUniswapV2Pair(0xF2FBafE0fB235F80b6551918f8dF505A5dBD4d5e);

    /**
     * @dev Swaps all ETH in the contract to WETH and then sends it to the pair contract
     * then calls sync() to the pair contract
     */
    function sendWETHToPair() external {
        WETH.deposit{value: address(this).balance}();
        WETH.transfer(address(PAIR), WETH.balanceOf(address(this)));
        PAIR.sync();
    }

    /**
     * @dev Function so that the contract can recieve Ether
     */
    // solhint-disable-next-line
    receive() external payable {}
}