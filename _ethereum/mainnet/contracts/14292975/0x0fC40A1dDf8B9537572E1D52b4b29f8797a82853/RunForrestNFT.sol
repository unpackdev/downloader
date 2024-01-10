//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";

contract RunForrestNFT is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public baseURI;
    string public hiddenMetadataUri;
    uint256 public cost = 0.07 ether;
    uint256 public whitelistCost = 0.03 ether;
    uint256 public maxSupply = 9000;
    uint256 public maxMintAmount = 20;

    mapping(address => bool) public whitelisted;
        
    bool public paused = true;
    bool public revealed = false;

    constructor() ERC721("RunForrest NFT", "RUN") {
        setHiddenMetadataUri("ipfs://QmfHNqk8cdgNqwyodxU8yjcLC2BCoCXAu98kqxJcCMyuEs/runforrest.json");
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "Invalid mint amount!");
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    // RunForrest mint
    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(!paused,"The contract is paused!");
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply.current() + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            if (whitelisted[msg.sender] == true)
            {
                //whitelist mint
                require(msg.value >= whitelistCost * _mintAmount);
            } 
            else
            {
                //public mint
                require(msg.value >= cost * _mintAmount);
            }
        }
          for (uint i = 0; i < _mintAmount; i++) {
             _mintRunForrest();
        }
    }

    function _mintRunForrest() private {
        uint newTokenID = supply.current();
        _safeMint(msg.sender, newTokenID);
        supply.increment();
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
        address currentTokenOwner = ownerOf(currentTokenId);

        if (currentTokenOwner == _owner) {
            ownedTokenIds[ownedTokenIndex] = currentTokenId;

            ownedTokenIndex++;
        }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)): "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setWhitelistCost(uint256 _newCost) public onlyOwner {
        whitelistCost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    function addAllWhitelistUser(address[1115] memory _users) public onlyOwner {
        for (uint256 i = 0; i < 1115; i++) {
            whitelisted[_users[i]] = true;
        }
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

     function giveAway(address[] calldata to) public onlyOwner {
         for (uint32 i = 0; i < to.length; i++) {
             require(1 + supply.current() <= maxSupply, "Limit reached");
             _safeMint(to[i], supply.current()+1, "");
         }
     }


    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

}