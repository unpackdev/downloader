/**
*
* - Power Casino Dividend Contract for Power Stake Community Earnings Platform.
*
*
*
* - This contract receives 15% of  Powercasino.live  TOTAL Weekly turnover and distributes it all as Ethereum Dividends to all 
* - Power Coin holders on the  powerstake.live  Earnings Platform Exchange.
* - Also 5% of every pot in the Raffle that takes place every 48 hours in the Power Casino goes to all power coin holders. 
*
* - All Power Coin holders recieves 20% Dividends from all transfers and buying/selling volume of power coin on the platform on top of all dividends distributed from this contract.
*
* - The more POWER you own and hold, the larger is your Dividend Bonus from the Casino Weekly Turnover as you get the same 
* - percentage of the Ethereum dividends each week as you hold Power Coins relative to the total Power Coin supply.
*
*
* - Anyone can send Ethereum to this contract in form of donations or tip to the community. All funds sent to this contract are for dividend payment to all power coin holders exclusively.
* - This contract is 100% decentralized and anyone can run the distribute function on this contract directly through Etherscan to distribute 100% of the ETH balance to all power coin holders.
*
* - Power Stake Dividends Earnings Platform: www.powerstake.live
* - Casino Website: www.powercasino.live
*
* -Community Telegram Group: https://t.me/powerstakingcommunity
* -Casino Telegram Group: https://t.me/PowerCasinoLive
*
*
* - No Admin Keys!
* - No Developer Fees!
* - No need for referrals to earn on the platform!
* - No KYC/AML!
* - 100% Decentralized!
* - No counterparty risk!
* - No off switch!
* - Open Source - 100% Transparent!
* - High Dividend Rate!
*
*/

pragma solidity ^0.4.24;

contract PowerStakeCommunity {
    function buy(address _referredBy) public payable returns(uint256);
    function exit() public;
}

contract PowerCasinoDividends {
    PowerStakeCommunity PowerStakeCommunityContract = PowerStakeCommunity(0x59C857b02787a10abd584dc654A3f22ff9B1c83D);
    
    /// @notice Any funds sent here are for dividend payment to all power coin holders.
    function () public payable {
    }
    
    /// @notice Distribute dividends to the PowerStakeCommunity contract. Can be called
    ///     repeatedly until practically all dividends have been distributed.
    /// @param rounds How many rounds of dividend distribution do we want?
    function distribute(uint256 rounds) external {
        for (uint256 i = 0; i < rounds; i++) {
            if (address(this).balance < 0.001 ether) {
                // Balance is very low. Not worth the gas to distribute.
                break;
            }
            
            PowerStakeCommunityContract.buy.value(address(this).balance)(0x0);
            PowerStakeCommunityContract.exit();
        }
    }
}