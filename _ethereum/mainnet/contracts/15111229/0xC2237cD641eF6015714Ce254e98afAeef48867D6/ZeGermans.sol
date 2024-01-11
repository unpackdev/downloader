// SPDX-License-Identifier: MIT

import "./ERC721A.sol";

pragma solidity ^0.8.15;

/*
* ACHTUNG: 4444 happy Germans are ready for ze Metawurst.
*
* Reveal after minting out (we must get them ready yet, generierund und so). 
*
* Minting is free. 3 per wallet max. Use "praegen" to mint.
*
* This is a fun project of https://rarity.garden (you can mint there, too)
*/

contract ZeGermans is ERC721A
{

    using Strings for uint256;

    address public owner;
    string public _baseTokenUri;
    string public _defaultURI;
    mapping(address => uint256) public minters;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory defaultURI,
        uint256 maxBatch,
        uint256 collectionSize
    ) ERC721A(name, symbol, maxBatch, collectionSize) {

        _baseTokenUri = baseTokenURI;
        owner = _msgSender();
        _defaultURI = defaultURI;
    }

    function praegen(uint256 anzahl) external {

        require(totalSupply() + anzahl <= collectionSize, "Achtung: die maximale Anzahl der Wertmarken wurde erreicht.");
        uint256 minterMinted = minters[_msgSender()];
        require(minterMinted + anzahl <= maxBatchSize, "Achtung: die maximale Praegung fuer die Brieftasche wurde erreicht.");

        minters[_msgSender()] += anzahl;
        _safeMint(_msgSender(), anzahl, "");
    }

    function _baseURI() internal view virtual override returns (string memory) {

        return _baseTokenUri;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        
        require(_exists(tokenId), "ERC721Hartspiritus: Anfrage fuer nicht-existierende Wertmarke");
          
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : _defaultURI;
    }
    
    function setBaseUri(string calldata baseTokenURI) public virtual {

        require(_msgSender() == owner, "Achtung: Sie muessen der Eigentuemer sein.");

        _baseTokenUri = baseTokenURI;
    }

    function performEthRecover(uint256 amount, address receiver) external
    {
        require(_msgSender() == owner, "Achtung: Sie muessen der Eigentuemer sein.");

        (bool success,) = payable(receiver).call{value: amount}("");
    }

    function transferOwnership(address newOwner) external
    {
        require(_msgSender() == owner, "Achtung: Sie muessen der Eigentuemer sein.");

        owner = newOwner;
    }
}