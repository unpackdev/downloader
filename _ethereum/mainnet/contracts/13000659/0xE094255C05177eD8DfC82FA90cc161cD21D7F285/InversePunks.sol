pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @title InversePunks contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract InversePunks is ERC721, Ownable {
    using SafeMath for uint256;

    string public IPUNKS_PROVENANCE = "";

    uint256 public constant punkPrice = 10000000000000000; // 0.01 ETH

    uint public constant maxPunkPurchase = 20;

    uint256 public MAX_PUNKS = 10000;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setBaseURI('ipfs://QmToARS85mrzoFuKQHCXkBAw756ermfE43GdyHABLWgkyX/');
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     * Set some Punks aside
     */
    function reservePunks() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 30; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        IPUNKS_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
    * Mints Punks
    */
    function mintPunk(uint numberOfTokens) public payable {
        require(numberOfTokens <= maxPunkPurchase, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_PUNKS, "Purchase would exceed max supply of Punks");
        require(punkPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_PUNKS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}