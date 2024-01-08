// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract Zorks is ERC721 {
    uint public price = 0.08 ether ; //cost of 1 zork
    uint public max_supply = 4000 ; //max total supply ever
    uint public start_unix = 0 ;  //start minting time

    bool public hasEnded = true ; 
    bool public hasRevealed = false ;

    string public _baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmctTzEzhZZLeefUiJbw9xYUUozaukaryvG3n6WegxrVa2/" ;   

    address public OpenSeaRegistry_address  = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; 

    address public owner ;

    uint public _totalSupply = 0 ;

    constructor() ERC721("Zorks", "ZORK") {
        owner = msg.sender ; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyFans U+2122") ; 
        _;
    }

    function mint(uint amount) public payable {
        require(hasEnded, "minting has ended") ; 
        require(block.timestamp >= start_unix, "minting not live (yet)") ; 
        require(msg.value >= amount * price, "tx value insufficient") ; 
        require(_totalSupply + amount < max_supply, "cannot mint amount") ; 

        for (uint i = _totalSupply; i < _totalSupply + amount; i++) {
            _mint(msg.sender, i) ; 
        }

        _totalSupply += amount ; 
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply ; 
    }

    receive() payable external {
        uint _amount = msg.value / price ; 
        mint(_amount) ; 
    }

    function withdraw(address payable receiver) onlyOwner external {
        require(receiver != address(0), "cannot withdaw to burn address") ; 
        receiver.transfer(address(this).balance) ;
    }

    function transferOwnership(address newOwner) onlyOwner external {
        require(newOwner != address(0), "cannot transfer ownership to burn address") ; 
        owner = newOwner ; 
    }

    function changeLive(bool state) onlyOwner external {
        hasEnded = state ; 
    }

    function set_registry_address(address _addr) external onlyOwner {
        OpenSeaRegistry_address = _addr ; 
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        if (_operator == address(OpenSeaRegistry_address)) {
            return true;
        }
        
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function reveal(string memory __baseTokenURI) external onlyOwner {
        require(!hasRevealed, "already revealed") ; 
        _baseTokenURI = __baseTokenURI ; 
        hasRevealed = true ; 
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId));
        return concatenate(baseTokenURI(), uint2str(_tokenId), ".json") ; 
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        address _owner = ownerOf(_tokenId);
        return _owner != address(0);
    }

    function concatenate(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
        }
}