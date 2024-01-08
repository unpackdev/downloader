// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

  //___    _   ___ ___ ___ _   _ _  _ _  _ ___ ___ _   _   _ ___ 
 //| _ \  /_\ | _ \ __| _ ) | | | \| | \| |_ _/ __| | | | | | _ )
 //|   / / _ \|   / _|| _ \ |_| | .` | .` || | (__| |_| |_| | _ \
 //|_|_\/_/ \_\_|_\___|___/\___/|_|\_|_|\_|___\___|____\___/|___/                                                               

//Written by BunniZero, if you copy pls give credit and link RareBunniClub.com
//Web rarebunniclub.com
//Twitter @rarebunniclub
//Linktree https://linktr.ee/RareBunniClub

contract RBCUtility is Ownable, ERC20("CARROTS", "CARROTS") 
{
    using SafeMath for uint256;
   
    uint256 public totalTokensBurned;

    mapping (address => bool) public CanMint;
    mapping (address => bool) public CanBurn;

    constructor(address _initContract) //init with Staking Contract address
    {
        CanMint[_initContract] = true;        
    }
   
	modifier canMintAddress
    {
         require(CanMint[msg.sender] == true, "Calling from Invalid Contract");
         _;
    }

    modifier canBurnAddress
    {
         require(CanBurn[msg.sender] == true, "Calling from Invalid Contract");
         _;
    }
	
	function getReward(address _to, uint256 totalPayout) external payable canMintAddress
	{
		_mint(_to, totalPayout * 10 ** 18); //Only allow Whole Numbers
	}
        
	function burn(address _from, uint256 _amount) external canBurnAddress
	{        
		_burn(_from, _amount  * 10 ** 18); //Only allow Whole Numbers
		totalTokensBurned += _amount;
	}
 
    function setAddressActive(address _ContractAddress, bool _canMint, bool _canBurn) public onlyOwner {
        CanMint[_ContractAddress] = _canMint;
        CanBurn[_ContractAddress] = _canBurn;
    }
}