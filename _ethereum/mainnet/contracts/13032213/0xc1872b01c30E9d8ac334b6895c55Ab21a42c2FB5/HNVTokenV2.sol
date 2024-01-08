// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract HNVTokenV2 is ERC721URIStorage,Ownable {
    event BatchMint(address _whoDone, uint256);

    uint16 public tokenCounter;
    uint16 private ownerCounter;
    uint16 public alreadyMinted = 0;
    uint16 MAX_TOKEN_SUPPLY = 7501;
    uint16  public MAX_MINT_PER_TIME = 5;
    uint public nftCost = 4*10**16;

    constructor () 
        ERC721 ("Ninja Village", "HNV")
    {
        tokenCounter = 1500;
        ownerCounter = 0;
    }

    function decimals() public view virtual  returns (uint8) {
        return 0;
    }

    modifier isLessThanMaxSupply(){
        require(tokenCounter < 7501);
        _;
    }

    function setMaxMintPerTime(uint8 _max) external onlyOwner
    {
        MAX_MINT_PER_TIME = _max;
    }

    // when _howManyMEth = 1, it's 0.001 ETH
    function setNftCost(uint256 _howManyMEth) external onlyOwner
    {
        nftCost = _howManyMEth * 10 ** 16;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked("ipfs://", _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function createCollectible(string memory _tokenURI) internal isLessThanMaxSupply returns (uint256) {
        uint256 newItemId = tokenCounter;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        tokenCounter = tokenCounter + 1;
        alreadyMinted += 1;
        return newItemId;
    }

    function mint(string[] memory _tokenURIs) payable external 
    {
        require(_tokenURIs.length <= MAX_MINT_PER_TIME, "minting limit 5 tokens per time");
        require(msg.value >= (nftCost * _tokenURIs.length), "Low Price");

        for (uint32 index = 0; index < _tokenURIs.length; index++) 
        {  //for loop example
            createCollectible(_tokenURIs[index]);
        }
    }

    function ownerMint(address _to, string memory _tokenURI) public onlyOwner returns (uint256)
    {
        require (ownerCounter < 1500, "Owner can mint 0 to 1499");
        uint256 newItemId = ownerCounter;
         _safeMint(_to, newItemId);
         _setTokenURI(newItemId, _tokenURI);
         ownerCounter = ownerCounter + 1;
         alreadyMinted += 1;

        return newItemId;
    }

/*
    solidity not support yet.
    function batchMint(address[] memory _addrs, string[] memory _tokenURIs) public onlyOwner 
    {
        require(_addrs.length == _tokenURIs.length, "address length must equal to tokenUrIs");
        require(ownerCounter < 1500, "Owner can mint 0 to 1499");
        require(ownerCounter + _addrs.length < 1500, "Exceed max supply");

        for (uint32 i = 0; i < _addrs.length; i++)
        {
            uint256 newItemId = ownerCounter;
            _balances[_addrs[i]] += 1;
            _owners[newItemId] = _addrs[i];
            _tokenURIs[newItemId] = _tokenURIs[i];
            ownerCounter = ownerCounter + 1;
        }
        emit BatchMint(msg.sender, _addrs.length);
    }
 */
    function updateTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function totalSupply() public pure returns (uint256){
        return 7501;
    }
    
    function withdrawAll() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external virtual payable { } 
    fallback() external virtual payable {  }
}
