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

contract Calamigos is ERC721Enumerable, ERC2981Royalties, Ownable {
    using SafeMath for uint256;

    // Token detail
    struct CalamigosDetail {
        uint256 first_encounter;
    }

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 first_encounter);

    // Token Detail
    mapping(uint256 => CalamigosDetail) private _CalamigosDetail;

    // Provenance number
    string public PROVENANCE = "";

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 5;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 10000;

    // Current price.
    uint256 public CURRENT_PRICE = 70000000000000000;

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
        payable(0x13ed6a8a96a0Db33A36c4E9CAF563c3e2a0A437f).transfer(
            (balance * 40) / 100
        );
        payable(0x2951A551BaA66063dFdCDE31fedA0855F95B7c63).transfer(
            (balance * 40) / 100
        );
        payable(0x05152838Ceff9c37142D385D4eC930E68101BE97).transfer(
            (balance * 20) / 100
        );
    }

    /**
     * Reserve tokens
     */
    function reserveTokens() public onlyOwner {
        uint256 i;
        uint256 tokenId;
        uint256 first_encounter = block.timestamp;

        for (i = 1; i <= 100; i++) {
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
        _CalamigosDetail[tokenId] = CalamigosDetail(first_encounter);
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
     * Mint Calamigos
     */
    function mintCalamigos(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Mint is not available right now");
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Can only mint 5 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of Calamigos"
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
                _CalamigosDetail[tokenId] = CalamigosDetail(first_encounter);
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
    function getCalamigosDetail(uint256 tokenId)
        public
        view
        returns (CalamigosDetail memory detail)
    {
        require(_exists(tokenId), "Token was not minted");

        return _CalamigosDetail[tokenId];
    }
}
