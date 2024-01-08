//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Oinks_Backyard_BBQ is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    using SafeMath for uint256;

    string public OBB_PROVENANCE = "";

    string private baseURI;
    bool public saleIsActive = false;

    // Reserve 101 Oink's
    uint256 public constant MAX_OINKS_RESERVED = 101;

    uint256 public MAX_OINKS;
    uint256 public constant maxOinksPurchase = 10;
    uint256 public constant oinkPrice = 40000000000000000; // 0.04 ETH

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxOinksSupply
    ) ERC721(name, symbol) {
        MAX_OINKS = maxOinksSupply;
    }

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        OBB_PROVENANCE = provenanceHash;
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmZwyNtucQhBVsKqZiWM5JpKpBTWpcoHtQ2cmPVrwJFknJ";
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * Set Oink's aside for giveaways, etc.
     */
    function reserveOinks(uint256 numberOfTokens) public onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply.add(numberOfTokens) <= MAX_OINKS_RESERVED,
            "Transaction would exceed max supply of reserved Oink's"
        );
        uint256 i;
        for (i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /*
     * Mint Oink's
     */
    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Oink's");
        require(
            numberOfTokens <= maxOinksPurchase,
            "Can only mint 10 Oink's at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_OINKS,
            "Purchase would exceed max supply of Oink's"
        );
        require(
            oinkPrice.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_OINKS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        uint256 balance = address(this).balance;

        to.transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
