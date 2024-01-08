// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";


contract OpenSeaSplitter is PaymentSplitter, Ownable { 

    using SafeMath for uint256;
    
    address[] private _team = [
	0x510861CFa70D98f0f9013A700c18AC1eD5408D26, // Community
    0x254a6Eda7F8F0EA0251fE0c9f06096630AEE27E3 // craftbrain
    ];

    uint256[] private _team_shares = [50,50];

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