// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC20.sol";

interface IFang20 {
    function burnFromExtentionContract(address user, uint256 amount) external;
}

contract DivineWolvesBreeding is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    //Counters
    Counters.Counter private supply;

    address extendingContract;
    address erc20Contract;
    string public baseURI;

    //Inventory
    uint16 public maxMintAmountPerTransaction = 1;
    uint256 public maxSupply = 1900;

    //Prices
    uint256 public cost = 700 ether;
    uint256 public incrementCost = 1 ether;
   

    //Utility
    bool public paused = false;
  

    constructor(string memory _baseUrl) ERC721("DivineWolfPups", "DWP") {
        baseURI = _baseUrl;
    }

    function setIncrementCost(uint256 _incrementCost) public onlyOwner{
        incrementCost = _incrementCost;
    }

    function setErc20(address _bAddress) public onlyOwner {
        erc20Contract = _bAddress;
    }

    function setExttendingContractAddress(address _bAddress) public onlyOwner {
        extendingContract = _bAddress;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
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

    function mintExternal(address _address, uint256 _tokenId) external {
        require(msg.sender == extendingContract, "Sorry you dont have permission to mint");
        _safeMint(_address, _tokenId);
    }

   
    function getBreedingCost() public view returns (uint256){
        return  (totalSupply() * incrementCost) + cost;
    }
    // public
    function mint(uint256 _mintAmount) public  {
        if (msg.sender != owner()) {
            require(!paused);
            require(_mintAmount > 0, "Mint amount should be greater than 0");
            require(_mintAmount <= maxMintAmountPerTransaction, "Sorry you cant mint this amount at once");
            require(supply.current() + _mintAmount <= maxSupply, "Exceeds Max Supply");
            uint256 balance = IERC20(erc20Contract).balanceOf(msg.sender);
            require((_mintAmount * getBreedingCost()) <= balance, "Insufficent ERC20 Tokens");
            //Burn Erc20
           IFang20(erc20Contract).burnFromExtentionContract(msg.sender, _mintAmount * getBreedingCost());
        }
        _mintLoop(msg.sender, _mintAmount);
    }

    function gift(address _to, uint256 _mintAmount) public onlyOwner {
        _mintLoop(_to, _mintAmount);
    }

    function airdrop(address[] memory _airdropAddresses) public onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            address to = _airdropAddresses[i];
            _mintLoop(to, 1);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

   

    function setmaxMintAmountPerTransaction(uint16 _amount) public onlyOwner {
        maxMintAmountPerTransaction = _amount;
    }

    
    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }


    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
