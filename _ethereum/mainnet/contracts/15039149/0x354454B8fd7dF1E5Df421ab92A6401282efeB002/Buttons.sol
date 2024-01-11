/*

         ((((((((((((           (((((((         (((((((((((((((       
      (((        (((((((     %((      (((    (((              (((     
    %%((                (( %%((         (( %((      ((((((      (((   
   %%%((     ((((((/     ((#((     (     ((((     ((((((((((     ((   
   %%%((     ((((((((     (((     (((     (((     ((((((((((     (((  
   #%%((     ((((((((     (((              ((      (((((((((     ((   
    %%((     (((((((      ((                ((       ((((       ((    
    %%((                (((     ((((((((     ((((             (((     
    %%%((            ((((((    ((%%%%%%(((  (((((((((((((((((%        
    %%%%(((((((((((((%%%%%%((((     %%%%%%%%((    ((%%%%%%%           
     %%%%%%%%%%%%%%     %%%%%          *# %%((    ((    (((((((       
            (((((((((   (((((((((((  ((((  /((    (((((        (((    
         (((         (((          ((((            (((     ((     ((.  
       %((     (((    ((   ((((    ((    (((((     (*             ((  
     ,%#((    ((((((((((/          ((    (((((     ((    (((((((/((   
     %%%((     (((    ((    ((     (((             (((           ((   
     %%%%(((         ((((     ((   (((((,   ((((  ((%%(((((((((((     
      %%%%%%(((((((((%%%#(((((#%(((%%%%%%%#%%%%%%% %%%%%%%%%%%%       
         %%%%%%%%%%  /%%%%%%*%%%%     %%%%                            


The future of gaming is democratic.

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Strings.sol";
import "./ERC1155Supply.sol";
import "./base64.sol";
import "./Ownable.sol";
import "./ERC1155Pausable.sol";

contract ERC721 {
    function balanceOf(address addr) public view returns (uint) {}
}

contract Buttons is ERC1155Supply, Ownable, Pausable {
    using Strings for uint256;

    uint256 public maxTokensPerButton = 1000;
    uint256[] public priceTiers = [200000000000000, 25000000000000000];
    uint256 public supplyThreshold = 50;

    string[] public buttons = ["A", "B", "UP", "DOWN", "LEFT", "RIGHT", "SELECT", "START"];
    string[] public buttonsDisplay = [":A_BUTTON:", ":B_BUTTON:", ":UP:", ":DOWN:", ":LEFT:", ":RIGHT:", ":SELECT:", ":START:"];
    string baseURI;
    address[] mossyContracts;
    string public name = "DAOcade";
    bool public presale = true;

    constructor(
        string memory _baseURI, 
        address[] memory _mossyContracts,
        address[] memory _premintWallets) ERC1155("") {
        baseURI = _baseURI;
        mossyContracts = _mossyContracts;

        for(uint i=0 ; i<_premintWallets.length; i++){
            for(uint j=0; j<buttons.length; j++){
                _mint(_premintWallets[i], j, 1, "");
            }
        }
        _pause();
    }

    function setPaused(bool _newPauseState) public onlyOwner {
        if(_newPauseState){
            _pause();
        }else{
            _unpause();
        }
    }

    function mintButton(uint id) public payable whenNotPaused {
        require(isApproved(msg.sender), 'NOT_APPROVED');
        require(id < buttons.length, 'BAD_BUTTON');
        require(totalSupply(id) < maxTokensPerButton, 'MAX_TOKENS');
        if(totalSupply(id) < supplyThreshold){
            require(priceTiers[0] <= msg.value, 'LOW_ETHER');
        }else{
            require(priceTiers[1] <= msg.value, 'LOW_ETHER');
        }
        _mint(msg.sender, id, 1, "");
    }

    function getPrice(uint id) public view returns(uint256){
        if(totalSupply(id) < supplyThreshold){
            return priceTiers[0];
        }else{
            return priceTiers[1];
        }
    }

    function setPrice(uint tier, uint price) public onlyOwner {
        require(tier < 2, 'INVALID_TIER');
        priceTiers[tier] = price;
    }

    function uri(uint id) public view override returns(string memory) {
        require(exists(id), "NOT_EXIST");
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', buttonsDisplay[id] , '", "description": "Enables ', buttons[id] ,' voting in the DAOcade Discord.", "image": "', baseURI, buttons[id], '.png' ,'", "attributes": [{"trait_type":"Button", "value":"', buttons[id] ,'"}]}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function isMossyHolder(address addr) public view returns(bool){
        for(uint i=0; i<mossyContracts.length; i++){
            ERC721 mossyContract = ERC721(address(mossyContracts[i]));
            if(mossyContract.balanceOf(addr) > 0){
                return true;
            }
        }
        return false;
    }

    function isApproved(address addr) public view returns(bool){
        if(!presale){
            return true;
        }else if(isMossyHolder(addr)){
            return true;
        }
        return false;
    }

    function setPresale(bool _isPresale) public onlyOwner{
        presale = _isPresale;
    }
}



