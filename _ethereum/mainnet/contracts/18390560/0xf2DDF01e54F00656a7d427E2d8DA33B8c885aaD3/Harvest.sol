// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IHarvest.sol";


abstract contract Harvest is IHarvest
{
    using SafeERC20 for IERC20;

    // TEAM_WALLET
    address private constant _HARVEST_ADDRESS = 0x1d6B3E373B947319a4B76A851bb17C1dEcCADb1D;


    receive() external payable 
    {
        emit Thanks(msg.sender, msg.value);
    }


    /// the function of collecting tokens that got accidentally
    /// or specifically into a smart contract and were not recorded
    /// in storage
    /// NOTE: this function does not take user's funds from the contract,
    /// but will withdraw those funds that are considered to be
    /// donation and receiving funds!
    function collect(address token) public virtual returns (bool)
    {
        uint256 harvestAmount = _getHarvest(token);

        if(harvestAmount == 0)
        {
            return false;
        }

        if(token == address(0))
        {
            (bool sent, ) = payable(_HARVEST_ADDRESS).call{value: harvestAmount}("");
            require(sent, "Failed to send Ether!");
        }
        else
        {
            IERC20(token).safeTransfer(_HARVEST_ADDRESS, harvestAmount);
        }

        emit HarvestCollected();
        return true;
    }


    /// The main idea is to collect all funds that were sent in contract
    /// accidently or as donation, not to stole a whole contract balance
    /// NOTE: any funds received for a smart contract and not recorded
    /// in the storage are regarded as a donation that the team can take
    function _getHarvest(address token) internal view returns (uint256)
    {
        if(token == address(0))
        {
            return address(this).balance;
        }

        return IERC20Metadata(token).balanceOf(address(this));
    }


    function _extractDonationPercentage(uint256 fullAmount, uint16 percentage) internal pure returns (uint256)
    {
        // accuracy up to two characters
        // 10000 = 100.00
        return fullAmount * percentage / 10000;
    }
}
