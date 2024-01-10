// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./IFun1155.sol";

contract Capri_Son is ERC721A, Ownable {

    address private _fun1155Address;

    bool public _publicMintActive = false;
    bool public _whitelistMintActive = false;
    bool public _restrictedWhitelist = true;
    uint public _numRestrictedWhitelistMints = 2;
    uint public _pricePerToken = 0.3 ether;

    mapping(address => uint) private _whitelistMints;
    mapping(address => bool) private _whitelistAddresses;
    mapping(uint => address) private _whitelistContract;
    uint private _numWhitelistContracts = 0;

    uint private _maxSupply = 2477;
    uint private _maxMintPerTx = 10;

    string private _baseUri = "https://releaseday.tv/";
    address private _withdrawAddress;

    constructor() ERC721A("Capri_Son", "Capri_Son") {}

    function whitelistMint(address to, uint amount)
        public
        payable
    {
        require(_whitelistMintActive, "Whitelist mint not active.");
        require(isWhitelisted(to), "Not eligible for whitelist mint.");

        if(_restrictedWhitelist == true){
            require(amount <= 2, "Max restricted whitelist mints is 2.");
            require(_whitelistMints[to] + amount <= _numRestrictedWhitelistMints, "You have reached whitelist mint capacity.");
            _whitelistMints[to] = _whitelistMints[to] + amount;
        }

        _doMint(to, amount);
    }

    function mint(address to, uint amount) 
        public
        payable
    {
        require(_publicMintActive, "Public mint not active.");
        _doMint(to, amount);
    }

    function _doMint(address to, uint amount)
        internal
    {
        uint totalSupply = totalSupply();
        require(amount > 0, "Must mint at least 1.");
        require(amount <= _maxMintPerTx, "Must mint 10 or fewer.");
        require(totalSupply + amount <= _maxSupply, "Requested mint amount would exceed max supply.");
        require(msg.value == _pricePerToken * amount, "Must send exactly 0.3 * [num of tokens] ETH.");
        _reallyDoMint(to, amount);
    }

    function _reallyDoMint(address to, uint amount)
        internal
    {
        _safeMint(to, amount);
        IFun1155(_fun1155Address).mint(to, 1, amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(_baseUri, Strings.toString(tokenId), ".json"));
    }

    function _startTokenId()
        internal
        pure
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    function addressOwnsWhitelistContractToken(address to)
        public
        view
        returns (bool) 
    {
        for(uint i = 0; i < _numWhitelistContracts; i++){
            uint balanceOf = IERC721(_whitelistContract[i]).balanceOf(to);
            if (balanceOf > 0){
                return true;             
            }
        }

        return false;
    }    

    function isWhitelisted(address to)
        public
        view
        returns (bool)
    {
        if (_whitelistAddresses[to] == true){
            return true;
        }

        if (addressOwnsWhitelistContractToken(to) == true){
            return true;
        }

        return false;
    }

    function ownerMint(address[] calldata addresses, uint[] calldata quantities)
        public
        onlyOwner
    {
        require(addresses.length == quantities.length, "Must contain equiv number addresses and quantities");

        for(uint i = 0; i < quantities.length; i++){
            _reallyDoMint(addresses[i], quantities[i]);            
        }
    }

    function addWhitelistContract(address contractAddress) 
        public 
        onlyOwner 
    {
        _whitelistContract[_numWhitelistContracts] = contractAddress;
        _numWhitelistContracts++;
    }

    function addWhitelistAddresses(address[] calldata addresses)
        public
        onlyOwner
    {
        for(uint i = 0; i < addresses.length; i++){
            _whitelistAddresses[addresses[i]] = true;
        }
    }

    function setFun1155Address(address to) 
        public
        onlyOwner
    {
        _fun1155Address = to;
    }    

    function setWhitelistMintActiveState(bool state)
        public
        onlyOwner
    {
        _whitelistMintActive = state;
    }

    function setPublicMintActiveState(bool state)
        public
        onlyOwner
    {
        _publicMintActive = state;
    }

    function setRestictedWhitelistMintState(bool state)
        public
        onlyOwner
    {
        _restrictedWhitelist = state;
    }

    function setBaseUri(string memory baseUri)
        public
        onlyOwner
    {
        _baseUri = baseUri;
    }

    function setPrice(uint price)
        public
        onlyOwner
    {
        _pricePerToken = price;
    }

    function setWithdrawAddress(address to)
        public
        onlyOwner
    {
        _withdrawAddress = to;
    }

    function withdraw() 
        public 
        onlyOwner 
    {
        (bool success, ) = _withdrawAddress.call{value: address(this).balance}("");
        require(success, "CapriSon: Withdraw failed.");
    }    
}