// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";


contract DerpySplitter is PaymentSplitter, Ownable { 

    using SafeMath for uint256;
    
    address[] private _team = [
	0xa492605BeE17582a13F8274caa326Ff8317FB392,
    0x8672aDa837C557fF4A039677299D65EB0681d8A7, 
    0x788f4a9b99ED6e220E901E3F0aBE80B93D14C04a
    ];

    uint256[] private _team_shares = [33,33,33];

    constructor()
        PaymentSplitter(_team, _team_shares)
    {
    }

    function PartialWithdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

   function withdrawAll() public onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
}