// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Crowdsale.sol";

contract SuckTokenSale is Crowdsale {

    constructor(
        uint256 rate,    // rate in TKNbits
        address payable wallet,
        IERC20 token
    )
        Crowdsale(rate, wallet, token)
    {
        
    }

    function getCrowdSaleBalance() public view returns (uint256)  {
        require(msg.sender == wallet(), "Only owner can see the balance");
        return token().balanceOf(address(this));
    }

}