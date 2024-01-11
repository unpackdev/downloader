// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./Ownable.sol";
import "./ERC721R.sol";

contract MohawkNFT is ERC721r, Ownable{

    uint private totalMinted = 0;
    /// @dev Base token URI used as a prefix by tokenURI().
    string private baseTokenURI;

    //Constants
    uint256 public TOTAL_SUPPLY;
    uint256 public MINT_PRICE = 0.15 ether;
    uint256 public RELEASED_MINT_PRICE = 0.2 ether;
    uint public releaseDate = 	1653839999; // Sun May 29 2022 23:59:59 GMT+0800 (Singapore Standard Time)
    bool public finalized = false;

    
    constructor(string memory _baseTokenURI,uint256 _totalSupply) ERC721r("MohawkNFT", "MWHK",_totalSupply)
     {
        baseTokenURI = _baseTokenURI;
        TOTAL_SUPPLY  = _totalSupply;
    }
    
    // early mint
    function earlyMintMohawk()
        public
        payable
    {
        require(tx.origin == msg.sender,"CONTRACTS NOT ALLOWED TO MINT");
        require(totalMinted <= TOTAL_SUPPLY);
        require(block.timestamp <= releaseDate, "Early mint has ended");
        totalMinted += 1;
        _mintRandom(msg.sender,1);
    }

    // normal mint
    function mintMohawk()
    public
    payable
    {
        require(block.timestamp > releaseDate, "Normal sale hasn't started yet");
        require(tx.origin == msg.sender,"CONTRACTS NOT ALLOWED TO MINT");
        require(totalMinted <= TOTAL_SUPPLY);
        totalMinted += 1;
        _mintRandom(msg.sender,1);
    }

    function withdrawAll(address payable payee) public onlyOwner virtual {
        Address.sendValue(payee, address(this).balance);
    }


    function updateParams(bool newFinal) public onlyOwner {
        require(finalized == false, "final");
        finalized = newFinal; 
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId)))
            : "";
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        require(finalized == false, "final");
        baseTokenURI = _baseTokenURI;
    } 

    function _baseURI() internal view override virtual returns (string memory) {
	    return baseTokenURI;
	}

}

