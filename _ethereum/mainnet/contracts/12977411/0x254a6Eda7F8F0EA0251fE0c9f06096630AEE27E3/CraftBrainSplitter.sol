// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";


contract CraftBrainSplitter is PaymentSplitter, Ownable { 

    using SafeMath for uint256;
    
    address[] private _team = [
	0x93a3cf8aaF3f6E4C2239245c4FD60f2d1F4feCBc,
    0xEA69Dea54bae710029e6f8853aD306990a3Db16A,
    0xad73C44d179950C117347a1e8b5Bbe2Efea70528,
    0xC0aE184A59729DECa7c51a301FE9C6c7d3EEA4c3 // gnosis safe
    ];

    uint256[] private _team_shares = [30,30,30,10];

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