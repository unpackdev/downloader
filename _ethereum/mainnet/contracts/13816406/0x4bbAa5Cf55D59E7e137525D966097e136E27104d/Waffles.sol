//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";
import "./ERC1155.sol";
import "./ERC2981Royalties.sol";

contract Waffles is ERC721Enumerable, ERC2981Royalties, Ownable {
    using SafeMath for uint256;

    // Token detail
    struct WafflesDetail {
        uint256 first_encounter;
    }

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 first_encounter);

    // Token Detail
    mapping(uint256 => WafflesDetail) private _WafflesDetail;

    // Provenance number
    string public PROVENANCE = "";

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 1111;

    // Current price.
    uint256 public CURRENT_PRICE = 50000000000000000;

    // Define if sale is active
    bool public saleIsActive = true;

    // Base URI
    string private baseURI;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setRoyalties(owner(), 1000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * With
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(0xdf6E574E80471F2709d0fd04853B5197D53DB73A).transfer(
            (balance * 28) / 100
        );
        payable(0xe1F9E80A35f4DfeB63d78C86085a890875F88957).transfer(
            (balance * 28) / 100
        );
        payable(0xcA3Cf019F6BfCEE33618Af4Ad3Cf79c0576CFbD1).transfer(
            (balance * 29) / 100
        );
        payable(0x267F718f8c8f990C06b668ba41cD92c8f4bDb220).transfer(
            (balance * 15) / 100
        );
    }

    /**
     * Reserve tokens
     */
    function reserveTokens() public onlyOwner {
        uint256 i;
        uint256 tokenId;
        uint256 first_encounter = block.timestamp;

        for (i = 1; i <= 20; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    /**
     * Mint a specific token.
     */
    function mintTokenId(uint256 tokenId) public onlyOwner {
        require(!_exists(tokenId), "Token was minted");
        uint256 first_encounter = block.timestamp;
        _safeMint(msg.sender, tokenId);
        _WafflesDetail[tokenId] = WafflesDetail(first_encounter);
        emit TokenMinted(tokenId, msg.sender, first_encounter);
    }

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    /*
     * Set max tokens
     */
    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        MAX_TOKENS = maxTokens;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /**
     * Mint Waffles
     */
    function mintWaffles(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Mint is not available right now");
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of Waffles"
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Value sent is not correct"
        );
        uint256 first_encounter = block.timestamp;
        uint256 tokenId;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _WafflesDetail[tokenId] = WafflesDetail(first_encounter);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory BaseURI) public onlyOwner {
        baseURI = BaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Set the current token price
     */
    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

    /**
     * Get the token detail
     */
    function getWafflesDetail(uint256 tokenId)
        public
        view
        returns (WafflesDetail memory detail)
    {
        require(_exists(tokenId), "Token was not minted");

        return _WafflesDetail[tokenId];
    }
}
