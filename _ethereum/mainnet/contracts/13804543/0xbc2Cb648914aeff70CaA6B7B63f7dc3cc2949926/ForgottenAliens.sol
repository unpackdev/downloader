//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./IAdorableAliens.sol";

/**
 * @title Forgotten Adorable Aliens
 * @author dev: maximonee (twitter.com/maximonee_)
 * @notice This contract provides minting for Forgotten Adorable Aliens NFT by twitter.com/adorablealiens_
 */
contract ForgottenAdorableAliens is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(
        string memory name,
        string memory symbol,
        address _aliensContractAddress) 
        ERC721(
            name,
            symbol
        ) {
            // Start token IDs at 1
            _tokenIds.increment();

            aliens = IAdorableAliens(_aliensContractAddress);
        }

    bool public isPreSaleActive;
    bool public isPublicSaleActive;

    uint16 private constant ALIENS_MINTED = 4326;
    uint16 private constant MAX_SUPPLY = 825;

    uint256 private constant MAX_MULTI_MINT_AMOUNT = 5;
    uint256 private constant price = 0.01 ether;

    IAdorableAliens public immutable aliens;

    string public baseTokenURI = "https://arweave.net/F9AYvydQxsB5YALeF98fSQaEenN77YVCkHZqqeC9mos/";

    function setPreSaleState(bool _preSaleActiveState) public onlyOwner {
        isPreSaleActive = _preSaleActiveState;
    }

    function setPublicSaleState(bool _publicSaleActiveState) public onlyOwner {
        isPublicSaleActive = _publicSaleActiveState;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    Update the base token URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Allow an alien holder to mint their free Forgotten Alien
     */
    function mintWithAlien() public nonReentrant {
        require(isPreSaleActive, "SALE_NOT_ACTIVE");
        require(!isPublicSaleActive, "PRESALE_OVER");
        require(balanceOf(msg.sender) < 1, "ALREADY_MINTED_FORGOTTEN_ALIEN");
        require(totalSupply() < MAX_SUPPLY, "MAX_SUPPLY_REACHED");
        require(aliens.balanceOf(msg.sender) > 0, "MUST_BE_ALIEN_OWNER");

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId + ALIENS_MINTED);
        _tokenIds.increment();
    }

    /**
     * @notice Allow public to bulk mint tokens
     */
    function mint(uint256 numberOfMints) public payable nonReentrant {
        require(isPublicSaleActive, "SALE_NOT_ACTIVE");
        require(numberOfMints <= MAX_MULTI_MINT_AMOUNT, "TOO_LARGE_PER_TX");
        require(totalSupply() + numberOfMints <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");

        require(msg.value >= price * numberOfMints, "NPass:INVALID_PRICE");
        
        for (uint256 i = 0; i < numberOfMints; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId + ALIENS_MINTED);
            _tokenIds.increment();
        }
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current() - 1;
    }
}
