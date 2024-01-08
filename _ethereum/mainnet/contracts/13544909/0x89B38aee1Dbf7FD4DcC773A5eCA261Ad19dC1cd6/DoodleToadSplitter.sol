// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";


contract DoodleToadSplitter is PaymentSplitter, Ownable { 

    using SafeMath for uint256;
    
    address[] private _team = [
	0x4FD2d094FC4Fa48b03B103B61347902a359960e3, // hopkins
    0xbde1760A6B32AAcd3E37Ca040A8e495336A62038, // toadLER
    0x2DC0F538e6183648E364C044F752e32eb0982A5D // lollihops
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