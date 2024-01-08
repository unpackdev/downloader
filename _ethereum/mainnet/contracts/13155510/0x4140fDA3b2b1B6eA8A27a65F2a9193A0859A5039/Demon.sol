// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title Demon contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Demon is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public DEMON_PROVENANCE = "";
    uint256 public constant DemonPrice = 60000000000000000; //0.06 ETH
    uint public constant MaxDemonPurchase = 100;
    uint256 public MAX_DEMON = 10000;
    bool public saleIsActive = false;
    string _baseTokenURI;

    constructor(string memory baseURI) ERC721("Loot Demon", "Demon") {
        _baseTokenURI = baseURI;
    }


    /*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        DEMON_PROVENANCE = provenanceHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
    * Mints  Demons
    */
    function mintDemon(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Demon");
        require(numberOfTokens <= MaxDemonPurchase, "Can only mint 100 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_DEMON, "Purchase would exceed max supply of Demons");
        require(DemonPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_DEMON) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
