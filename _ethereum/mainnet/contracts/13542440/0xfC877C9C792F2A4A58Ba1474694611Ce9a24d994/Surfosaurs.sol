pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @title Surfosaurs contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Surfosaurs is ERC721, Ownable {
    using SafeMath for uint256;

    string public SURFOSAURS_PROVENANCE =
        "5a37fa823df7b2abf333e61e9689e3aef74d1f1e5acd290fdb4d4e954c54a850";

    uint256 public constant surfosaursPrice = 25000000000000000; //0.025 ETH in wei

    uint256 public constant maxSurfosaursPurchase = 20;

    uint256 public MAX_SURFOSAURS = 10000;

    uint256 public RESERVE = 1000;

    bool public saleIsActive = false;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setBaseURI("https://www.surfosaurs.net/surfosaurs/");
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function reserveSurfosaursMint(uint256 numberOfTokens) public onlyOwner {
        require(
            totalSupply().add(numberOfTokens) <= (MAX_SURFOSAURS),
            "Reserve mint would exceed max supply of Surfosaurs"
        );
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SURFOSAURS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        SURFOSAURS_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintSurfosaur(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Surfosaurs");
        require(
            numberOfTokens <= maxSurfosaursPurchase,
            "Can only mint up to 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= (MAX_SURFOSAURS - RESERVE),
            "Purchase would exceed max supply of Surfosaurs"
        );
        require(
            surfosaursPrice.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < (MAX_SURFOSAURS - RESERVE)) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}
