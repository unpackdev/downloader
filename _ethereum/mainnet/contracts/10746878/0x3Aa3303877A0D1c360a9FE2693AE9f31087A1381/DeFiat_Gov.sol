// SPDX-License-Identifier: DeFiat 2020

/*
* Copyright (c) 2020 DeFiat.net
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

//DeFiat Governance v0.1 - 2020 AUG 27

pragma solidity ^0.6.0;

contract DeFiat_Gov{
//Governance contract for DeFiat Token.
    address public mastermind;
    mapping (address => uint256) private actorLevel; //governance = multi-tier level
    
    mapping (address => uint256) private override _balances; 
     mapping (address => uint256) private override _allowances; 
     
    uint256 private burnRate; // %rate of burn at each transaction
    uint256 private feeRate;  // %rate of fee taken at each transaction
    address private feeDestination; //target address for fees (to support staking contracts)

    event stdEvent(address _txOrigin, uint256 _number, bytes32 _signature, string _desc);

//== CONSTRUCTOR
constructor() public {
    mastermind = msg.sender;
    actorLevel[mastermind] = 3;
    feeDestination = mastermind;
    emit stdEvent(msg.sender, 3, sha256(abi.encodePacked(mastermind)), "constructor");
}

//== MODIFIERS ==
    modifier onlyMastermind {
    require(msg.sender == mastermind, " only Mastermind");
    _;
    }
    modifier onlyGovernor {
    require(actorLevel[msg.sender] >= 2,"only Governors");
    _;
    }
    modifier onlyPartner {
    require(actorLevel[msg.sender] >= 1,"only Partners");
    _;
    }  //future use
    
//== VIEW ==    
    function viewActorLevelOf(address _address) public view returns (uint256) {
        return actorLevel[_address]; //address lvl (3, 2, 1 or 0)
    }  
    function viewBurnRate() public view returns (uint256)  {
        return burnRate;
    }
    function viewFeeRate() public view returns (uint256)  {
        return feeRate;
    }
    function viewFeeDestination() public view returns (address)  {
        return feeDestination;
    }
    
//== SET INTERNAL VARIABLES==

    function setActorLevel(address _address, uint256 _newLevel) public {
      require(_newLevel < actorLevel[msg.sender], "Can only give rights below you");
      actorLevel[_address] = _newLevel; //updates level -> adds or removes rights
      emit stdEvent(_address, _newLevel, sha256(abi.encodePacked(msg.sender, _newLevel)), "Level changed");
    }
    
    //MasterMind specific 
    function removeAllRights(address _address) public onlyMastermind {
      require(_address != mastermind);
      actorLevel[_address] = 0; //removes all rights
      emit stdEvent(address(_address), 0, sha256(abi.encodePacked(_address)), "Rights Revoked");
    }
    function killContract() public onlyMastermind {
        selfdestruct(msg.sender); //destroys the contract if replacement needed
    } //only Mastermind can kill contract
    function setMastermind(address _mastermind) public onlyMastermind {
      mastermind = _mastermind;     //Only one mastermind
      actorLevel[_mastermind] = 3; 
      actorLevel[msg.sender] = 2;  //new level for previous mastermind
      emit stdEvent(tx.origin, 0, sha256(abi.encodePacked(_mastermind, mastermind)), "MasterMind Changed");
    }     //only Mastermind can transfer his own rights
     
    //Governors specific
    function changeBurnRate(uint _burnRate) public onlyGovernor {
      require(_burnRate <=200, "20% limit"); //cannot burn more than 20%/tx
      burnRate = _burnRate; 
      emit stdEvent(address(msg.sender), _burnRate, sha256(abi.encodePacked(msg.sender, _burnRate)), "BurnRate Changed");
    }     //only governors can change burnRate/tx
    function changeFeeRate(uint _feeRate) public onlyGovernor {
      require(_feeRate <=200, "20% limit"); //cannot take more than 20% fees/tx
      feeRate = _feeRate;
      emit stdEvent(address(msg.sender), _feeRate, sha256(abi.encodePacked(msg.sender, _feeRate)), "FeeRate Changed");
    }    //only governors can change feeRate/tx
    function setFeeDestination(address _nextDest) public onlyGovernor {
         feeDestination = _nextDest;
    }

}