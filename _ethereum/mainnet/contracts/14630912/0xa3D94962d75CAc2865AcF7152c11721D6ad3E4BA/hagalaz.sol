// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*
hagalaz.sol  
*/

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Hagalaz is ERC721A, Ownable {

    // Mapping from tokenID to tokenURI
    mapping(uint256 => string) private _indTokenURI;

    uint256 public MAX_SUPPLY = 100;
    uint256 public MINT_COST = 0.025 ether;
    uint256 public SET_URI_COST = 0.001 ether;

    string defaultUri = "https://gateway.pinata.cloud/ipfs/QmYEcNEZaTB3gHLDTCKGCutQm4YmqPmgxYFymHHvMCapTn/";
 
    bool public saleIsActive;

    constructor() ERC721A("Hagalaz", "H") {
        saleIsActive = false;
    }


    function mint(uint256 _mintAmount) public payable {
        require(saleIsActive, "Hagalaz are not on sale yet.");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Not enough tokens remaining.");
        require(msg.value >= MINT_COST * _mintAmount, "Not enough ETH to mint.");
  
        _safeMint(msg.sender, _mintAmount);

    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Not enough tokens remaining.");
        
        _safeMint(_receiver, _mintAmount);
        
    }

    function setDefaultUri(string memory _defaultUri) public onlyOwner {
        defaultUri = _defaultUri;
    }

    function setMintCost(uint256 _newMintCost) public onlyOwner {
        MINT_COST = _newMintCost;
    }

    function setSetUriCost(uint256 _newSetUriCost) public onlyOwner {
        SET_URI_COST = _newSetUriCost;
    }

    function setTokenURI(uint256 _tokenToUpdate, address _targetContract, uint256 _targetTokenId) public payable {
        require(_exists(_tokenToUpdate), "ERC721: set request for nonexistent token.");
        require(msg.sender == ownerOf(_tokenToUpdate), "Not owner of requested token.");
        require(msg.value >= SET_URI_COST, "Not enough ETH to set token URI.");

        ERC721A targetTokenAddress = ERC721A(_targetContract);

        _indTokenURI[_tokenToUpdate] = targetTokenAddress.tokenURI(_targetTokenId);       
    }

    function devSetTokenURI(uint256 _tokenToUpdate, address _targetContract, uint256 _targetTokenId) public onlyOwner {
        require(_exists(_tokenToUpdate), "ERC721: set request for nonexistent token");
 
        ERC721A targetTokenAddress = ERC721A(_targetContract);

        _indTokenURI[_tokenToUpdate] = targetTokenAddress.tokenURI(_targetTokenId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _returnedTokenURI = _indTokenURI[_tokenId];

        return bytes(_returnedTokenURI).length != 0 ? _returnedTokenURI : string(abi.encodePacked(defaultUri, Strings.toString(_tokenId)));
    }

    function resetTokenUri(uint256 _tokenID) public {
        require(_exists(_tokenID), "ERC721: reset request for nonexistent token");
        require(msg.sender == ownerOf(_tokenID));
        
        delete _indTokenURI[_tokenID];
    }

    function devResetTokenUri(uint256 _tokenID) public onlyOwner {
        require(_exists(_tokenID), "ERC721: reset request for nonexistent token");
        
        delete _indTokenURI[_tokenID];
    }   

    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
}