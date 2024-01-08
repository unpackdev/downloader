// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Enumerable.sol";

import "./SafeMath.sol";
import "./Strings.sol";

import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract KwyptoKado is ERC721Enumerable, Pausable, Ownable  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;


    uint256 public maxSupply = 9999;
    uint256 public maxMintAmount = 10;
    uint256 public maxPerWallet = 99;
    uint256 public cost = 0.077 ether;
    bool public preSaleIsActive = true;
    uint8 public boostValue = 1;
    string public boostedStat = "Power";
    string baseURI;

    mapping(address => bool) public whitelistedUsers;

    constructor() ERC721("KwyptoKados", "KwyptoKado") {
        _tokenIdCounter.increment();
        baseURI = "ipfs://Qma6kNDutfab5A4bSjnaKf75madVMEGmE3x2w3mYRzepFW/";
    }
    

    function _baseTokenURI() internal view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI(), Strings.toString(_tokenId), ".json"));
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    

    function createKado(uint8 _amount) public payable whenNotPaused {
        require(_tokenIdCounter.current().add(_amount) > 200, "Not allowed first 200");
        if(preSaleIsActive){
            require(whitelistedUsers[msg.sender] == true, "Whitelisted users only during pre-sale!");
        }
        
        require(_amount <= maxMintAmount, "Don't be greedy! Only 10 at a time.;)");
        require(msg.value >= cost * _amount, "Need to send monies!");
        require(balanceOf(msg.sender).add(_amount) <= maxPerWallet, "Only 99 per wallet!");
        require(_tokenIdCounter.current().add(_amount) <= maxSupply, "Not enough left, sorry!");
        

        for (uint i = 1; i <= _amount; i++){
            uint256 newTokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, newTokenId);
            _tokenIdCounter.increment();
        } 

    }

    function ownerKados(uint8 _amount, address _to) public onlyOwner {
        require(totalSupply() <= 200, "Only allowed first 200");
        for (uint i = 1; i <= _amount; i++){
            uint256 newTokenId = _tokenIdCounter.current();
            _safeMint(_to, newTokenId);
            _tokenIdCounter.increment();
        } 
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
      {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
          tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
     }


    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
  

    function addMultipleWhitelistUsers (address[] memory _users) public onlyOwner {
        for(uint256 i; i < _users.length; i++){
            whitelistedUsers[_users[i]] = true;
        }
    }

    function addWhitelistUser(address _user) public onlyOwner {
        whitelistedUsers[_user] = true;
    }
    
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelistedUsers[_user] = false;
    }

    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


}