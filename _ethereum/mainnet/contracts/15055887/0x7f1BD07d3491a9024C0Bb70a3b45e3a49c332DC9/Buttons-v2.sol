/*

DAOCade Buttons V2

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
And democracy, like a Squirtle, must evolve.
This contract replaces the legacy Buttons contract (0x354454B8fd7dF1E5Df421ab92A6401282efeB002).
All holders of legacy buttons have been airdropped new ones.
The legacy contract cannot be minted anymore.

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Strings.sol";
import "./ERC1155Supply.sol";
import "./base64.sol";
import "./Ownable.sol";
import "./ERC1155Pausable.sol";


contract ButtonsV2 is ERC1155Supply, Ownable, Pausable {
    using Strings for uint256;

    uint256 public maxTokensPerButton = 1000;
    uint256[] public priceTiers = [200000000000000, 25000000000000000];
    uint256 public supplyThreshold = 50;

    string[] public buttons = ["A", "B", "UP", "DOWN", "LEFT", "RIGHT", "SELECT", "START"];
    string[] public buttonsDisplay = [":A_BUTTON:", ":B_BUTTON:", ":UP:", ":DOWN:", ":LEFT:", ":RIGHT:", ":SELECT:", ":START:"];
    string baseURI;
    string public name = "DAOcade";

    constructor(
        string memory _baseURI) ERC1155("") {
        baseURI = _baseURI;
    }

    function mintToEarlyHolders(address[] memory addrs, uint256[][] memory balances, uint256[] memory tokens) public onlyOwner{
        for(uint i=0; i< addrs.length; i++){
            _mintBatch(addrs[i], tokens, balances[i], '');
        }
    }

    function setPaused(bool _newPauseState) public onlyOwner {
        if(_newPauseState){
            _pause();
        }else{
            _unpause();
        }
    }

    function mintButton(uint id) public payable whenNotPaused {
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

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}



