// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract FOMO_PASS is ERC1155Supply, Ownable {

    string public name;
    string public symbol;
    
    uint256 public constant FOMOPass = 0;
    uint256 public cost = 0.5 ether;
    uint256 public maxSupply = 300;
    uint256 public supply;
    uint256 payed;
    uint256 firstOut = 4 ether;
    address firstOutAddress = payable(0x3961AEe261a11e4a619dad3bce6658DAE0D9Eaf7);

    bool public paused = true;
    
    mapping (uint256 => string) private _uris;


    //events
    event Pause(bool _state);
    event SetTokenUri(uint256 _tokenId, string _uri);
    event Withdraw(address _from, address _to, uint256 _amount, bool _status);
    event SetCost(uint256 _newCost);

    constructor() ERC1155("") {

        name = "PROJECT FOMO Mint";
        symbol = "PFM";
        _uris[0] = "ipfs://QmT3t3e9xSNT2kiUaCkfHJBegUHE8Tysd7XRVAzcXJgujf/";

        _mint(msg.sender, FOMOPass, 50, "");
        supply += 50;
    }

    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 FOMOPass");
        require(supply + _mintAmount <= maxSupply, "max FOMOPass limit exceeded");

        if (msg.sender != owner()) {
                require(msg.value >= cost * _mintAmount, "insufficient funds"); 
        }
        
        _mint(msg.sender, FOMOPass, _mintAmount, "");
        supply += _mintAmount;
    }
    
    function totalSupply() public view returns(uint256){
        return supply;
    }
    
    function uri(uint256 tokenId) override public view returns (string memory) {
        return(_uris[tokenId]);
    }
  
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;

        emit SetCost(_newCost);
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;

        emit Pause(_state);
    }
    
    function setTokenUri(uint256 tokenId, string memory _uri) public onlyOwner { 
        _uris[tokenId] = _uri; 

        emit SetTokenUri(tokenId, _uri);
    }

    function withdrawl() public{
        uint256 contractBalance = address(this).balance;
        if(payed < firstOut){
            uint256 outstandingFirstOut = firstOut - payed;
            if(outstandingFirstOut > contractBalance){
                (bool os, ) = firstOutAddress.call{value: contractBalance}("");
                require(os);
                payed += contractBalance;
            }
            if(contractBalance >= outstandingFirstOut){
                (bool fo, ) = firstOutAddress.call{value: outstandingFirstOut}("");
                require(fo);
                payed += outstandingFirstOut;
            }
        }
    (bool hs, ) = firstOutAddress.call{value: address(this).balance * 7 / 100}("");
    require(hs);
        
    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    }
}