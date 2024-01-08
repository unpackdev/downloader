// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***************************************************************************************************************************************\
|********************************************* Welcome to the DYNAMICS ETH Reflector code **********************************************|
|***************************************************************************************************************************************|
|* This project supports the following:                                                                                                 |
|***************************************************************************************************************************************|
|* 1. A good cause, a portion of fees are sent to charity as outlined on the Dynamics Webpage.                                          |
|* 2. Token reflections.                                                                                                                |
|* 3. Automatic Liquidity reflections.                                                                                                  |
|* 4. Automated reflections of Ethereum to hodlers.                                                                                     |
|* 5. Token Buybacks.                                                                                                                   |
|* 6. A Token airdrop system where tokens can be injected directly back into pools for Liquidity, Ethereum reflections and Buybacks.    |
|* 7. Burning Functions.                                                                                                                |
|* 7. An airdrop system that feeds directly into the contract.                                                                          |
|* 8. Multi-Tiered sell fees that encourage hodling and discourage whales/dumping.                                                      |
|* 9. Buy and transfer fees separate from seller fees that support the above.
|***************************************************************************************************************************************|
|                         This particular contract is designed to hold Ethereum for the SOLE purpose of:                                |
|* 1. Giving it to YOU!!!!!                                                                                                             |
|* 2. The more you HODL, the more your share is!                                                                                        |
|***************************************************************************************************************************************|
|     Yes, we are aware that gas fees to support this are high so..... ***DRUMROLL***                                                   |
|***************  If YOU are the person whose transaction triggers a reflection payout OR a snapshot event......                        |
|***************  YOU will be sent a portion of eth from the pool for your contribution to the reflections......                        |
|***************  A small little thanks. Your reward is based on how many hodlers you process.                                          |
|***************  The more gas in your transaction, the more people are processed, the more your thank-you becomes.                     |
|***************  And yes, if you manually trigger a reflection event on the contract, that also counts!                                |
|***************************************************************************************************************************************|
|***************************************************************************************************************************************|
|******************** Fork if you dare... But seriously, if you fork just shout us out and consider our charity. :) ********************|
|***************************************************************************************************************************************|
|***************************************************************************************************************************************|
|**************** Don't Mind the blood, sweat and tears throughout the contract, it has caused us many sleepless nights ****************|
|                 - The Dev!                                                                                                            |
|***************************************************************************************************************************************|
|***************************************************************************************************************************************|
\***************************************************************************************************************************************/


import "./AutomatedExternalReflector.sol";
import "./IERC20.sol";

contract DynaAutoEthDistributorV2 is AutomatedExternalReflector {

    event UpdateRouter(address indexed newAddress, address indexed oldAddress);

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(address tokenAddress) payable {
        _owner = msg.sender;
        currentRound = 1;
        totalEthDeposits = address(this).balance;
        currentQueueIndex = 0;
        totalRewardsSent = 0;
        totalExcludedTokenHoldings = 0;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap V2 Routers (Mainnet and Ropsten)
        uniswapV2Router = _uniswapV2Router;
        maxGas = 450000;
        minGas = 100000;
        maxReflectionsPerRound = 100;
        timeBetweenRounds = 1 seconds;
        nextRoundStart = block.timestamp + 1 seconds;

        reflectionsEnabled = true;
        updateTokenAddress(tokenAddress, true);
        _excludeFromReflections(address(_uniswapV2Router), true);
        _excludeFromReflections(address(this), true);
        _excludeFromReflections(deadAddress, true);
        _excludeFromReflections(address(0), true);

        totalCirculatingTokens = 1 * 10 ** 12 * 10 ** 18;
    }

    function updateRouter(address newAddress, bool andPair) external onlyOwner (){

        emit UpdateRouter(newAddress, address(uniswapV2Router));

        uniswapV2Router = IUniswapV2Router02(newAddress);
        _excludeFromReflections(newAddress, true);

        if(andPair){
            address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(tokenContract), uniswapV2Router.WETH());
            _excludeFromReflections(uniswapV2Pair, true);
        }
    }
}
