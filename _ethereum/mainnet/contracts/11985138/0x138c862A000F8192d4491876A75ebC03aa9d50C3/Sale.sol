// SPDX-License-Identifier: MIT
// Physalis.Finance: PreSale

pragma solidity ^0.5.5;
import "./ERC20.sol";
import "./Crowdsale.sol";
import "./AllowanceCrowdsale.sol";
import "./TimedCrowdsale.sol";


contract Sale is Crowdsale, AllowanceCrowdsale, TimedCrowdsale {  
    constructor(
    uint256 _rate,
    address payable _wallet,
    ERC20 _token,
    address _tokenWallet,
    uint256 _openingTime,
    uint256 _closingTime
         )
    AllowanceCrowdsale(_tokenWallet)
    Crowdsale(_rate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)

    public
    {
    }

    
}