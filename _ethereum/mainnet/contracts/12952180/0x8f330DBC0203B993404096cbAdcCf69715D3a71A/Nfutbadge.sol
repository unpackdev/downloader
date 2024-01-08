// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Strings.sol";

/**
 * @title ERC721 contract
 * NFUT Cards Team Badges - a contract for NFUT Team non-fungible collectibles.
 * Website: nfutcards.com
 */
contract Nfutbadge is ERC721Enumerable, Ownable{

    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    bool public saleIsActive;
    bool public airdropIsActive;
    uint public MAX_PURCHASE;
    uint256 public MAX_SUPPLY;
    uint256 public AIRDROP_BADGE_MAX_SUPPLY;
    uint256 public RESERVED_TOKENS;
    uint256 public BADGE_MINT_PRICE;
    uint256 public badgesAirdropCounter;

    uint256 public startingIndex;
    uint256 public startingIndexBlock;

    string private _baseURIExtended;
    mapping (uint256 => string) _tokenURIs;

    constructor(
        string memory token_name,
        string memory token_symbol,
        uint256 max_supply,
        uint256 badge_max_supply,
        uint256 reserved_tokens,
        uint badge_max_purchase,
        uint256 badge_mint_price
    ) ERC721(token_name, token_symbol) {
        MAX_SUPPLY = max_supply;
        AIRDROP_BADGE_MAX_SUPPLY = badge_max_supply;
        RESERVED_TOKENS = reserved_tokens;
        MAX_PURCHASE = badge_max_purchase;
        BADGE_MINT_PRICE = badge_mint_price;

        airdropIsActive = false;
        saleIsActive = false;
        badgesAirdropCounter = 0;
    }

    event AirdropBadgeMinted(address _to, uint256 _total);

    function reverseSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function reverseAirdropState() public onlyOwner {
        airdropIsActive = !airdropIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mintReservedTokens() public onlyOwner {
        require(totalSupply().add(RESERVED_TOKENS) <= MAX_SUPPLY, "Purchase would exceed max supply");

        for (uint i = 0; i < RESERVED_TOKENS; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function mintBadgeTokens(uint numberOfTokens) public payable{
        require(saleIsActive, "Sale is not active at the moment");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(numberOfTokens <= MAX_PURCHASE,"Max purchase exceeded");
        require(BADGE_MINT_PRICE.mul(numberOfTokens) == msg.value, "Sent ether value is incorrect");

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function mintAirdropBadgeTokens() public {
        require(airdropIsActive, "Airdrop is not active at the moment");
        require(totalSupply().add(1) <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(badgesAirdropCounter.add(1) <= AIRDROP_BADGE_MAX_SUPPLY, "Purchase would exceed max airdrop badges supply");
        _safeMint(msg.sender, totalSupply());
        badgesAirdropCounter = badgesAirdropCounter.add(1);
        emit AirdropBadgeMinted(msg.sender, totalSupply());
    }

    function calcStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index has already been set");
        require(startingIndexBlock != 0, "Starting index has not been set yet");

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if(block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_SUPPLY;
        }

        // To prevent original sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }
}