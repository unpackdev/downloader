// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***************************************************************************************************************************************\
|****************************************** Welcome to the DYNAMICS Token Injector source code *****************************************|
|***************************************************************************************************************************************|
|* This project supports the following:                                                                                                 |
|***************************************************************************************************************************************|
|* 1. A good cause, a portion of fees are sent to charity as outlined on the Dynamics Webpage                                           |
|* 2. Token reflections.                                                                                                                |
|* 3. Automatic Liquidity reflections.                                                                                                  |
|* 4. Automated reflections of Ethereum to hodlers.                                                                                     |
|* 5. Token Buybacks.                                                                                                                   |
|* 6. A Token airdrop system where tokens can be injected directly back into pools for Liquidity, Ethereum reflections and Buybacks.    |
|* 7. Burning Functions.                                                                                                                |
|* 7. An airdrop system that feeds directly into the contract.                                                                          |
|* 8. Multi-Tiered sell fees that encourage hodling and discourage whales/dumping.                                                      |
|* 9. Buy and transfer fees separate from seller fees that support the above.                                                           |
|***************************************************************************************************************************************|
|                          This particular contract is designed to hold tokens for the SOLE purpose of:                                 |
|* 1. Feeding tokens back into the DYNAMICS token supply as either liquidity, eth airdrop funding or buyback funding                    |
|* 2. Burning tokens to make your holding scarcer and therefore more worthwhile to HODL!!!                                              |
|                                                                                                                                       |
|I encourage you to peruse the source so you can be sure that once tokens are here, NO ONE can remove them except for the above purposes|
| While this contract should be excluded from reflections, should it receive any eth this will be withdraw to the charity wallet, BUT!  |
| We do not intend nor expect this contract to accrue eth at all. It is simply a fallback so eth isn't stuck and can go to a good cause.|
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


import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SupportingAirdropDeposit.sol";
import "./AuthorizedList.sol";
import "./LockableSwap.sol";

contract DYNAAirdropper is AuthorizedList, LockableSwap {
    using SafeMath for uint256;
    SupportingAirdropDeposit tokenContract;
    IERC20 token;
    address payable charityWallet = payable(0xA7817792a12C6cC5E6De2929FE116a67a79DF9d3);

    constructor(address tokenContractAddress) AuthorizedList() payable  {
        tokenContract = SupportingAirdropDeposit(tokenContractAddress);
        token = IERC20(tokenContractAddress);
    }

    receive() external payable {

    }

    fallback() external payable {

    }

    // This contract is supposed to only work with tokens, if eth gets stuck we dump it to a predefined wallet.
    function dumpEth() external authorized {
        if( address(this).balance > 0){
            address(charityWallet).call{value: address(this).balance}("");
        }
    }

    function updateTokenAddress(address payable newTokenAddress) external authorized {
        tokenContract = SupportingAirdropDeposit(newTokenAddress);
        token = IERC20(newTokenAddress);
    }

    function tokenInjection(uint256 liquidityInjectionTokens, uint256 ethDistributionInjectionTokens, uint256 buybackInjectionTokens) external authorized lockTheSwap {
        uint256 liqD = liquidityInjectionTokens * 10 ** 18;
        uint256 ethD = ethDistributionInjectionTokens * 10 ** 18;
        uint256 buybackD = buybackInjectionTokens * 10 ** 18;
        tokenContract.depositTokens(liqD, ethD, buybackD);
    }

    function getTokenBalance() external view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function burnTokens(uint256 _burnAmount) external authorized lockTheSwap {
        uint256 burnAmount = _burnAmount * 10 ** 18;
        tokenContract.burn(burnAmount);
    }

}
