// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// On Tupac's Soul

import "./ERC721A.sol";
import "./Payable.sol";

contract FoodlesClubToken is ERC721A, Payable {
    using Strings for uint256;

    // Token values incremented for gas efficiency
    uint256 private maxSalePlusOne = 5001;
    uint256 private constant MAX_RESERVED_PLUS_ONE = 51;
    uint256 private constant MAX_FREE = 700;

    uint256 private constant MAX_PER_TRANS_PLUS_ONE = 11;

    uint256 private reserveClaimed = 0;
    uint256 private freeClaimed = 0;
    uint256 public tokenPrice = 0.03 ether;

    bool public saleEnabled = false;

    string public baseURI;
    string public placeholderURI;

    constructor() ERC721A("FoodlesClub", "FC", MAX_PER_TRANS_PLUS_ONE) Payable() {}

    //
    // Minting
    //

    /**
     * Mint tokens
     */
    function mint(uint256 numTokens, bool inclFreeMint) external payable {
        require(msg.sender == tx.origin, "FoodlesClubToken: No bots");
        require(saleEnabled, "FoodlesClubToken: Sale is not active");
        require((totalSupply() + numTokens) < maxSalePlusOne, "FoodlesClubToken: Purchase exceeds available tokens");
        if (inclFreeMint) {
            // Free claim
            require((numTokens - 1) < MAX_PER_TRANS_PLUS_ONE, "FoodlesClubToken: Can only mint 10 at a time");
            require(freeClaimed < MAX_FREE, "FoodlesClubToken: Free claims exceeded");
            require((tokenPrice * (numTokens - 1)) == msg.value, "FoodlesClubToken: Ether value sent is not correct");
            freeClaimed++;
        } else {
            require(numTokens < MAX_PER_TRANS_PLUS_ONE, "FoodlesClubToken: Can only mint 10 at a time");
            require((tokenPrice * numTokens) == msg.value, "FoodlesClubToken: Ether value sent is not correct");
        }
        _safeMint(msg.sender, numTokens);
    }

    /**
     * Mints reserved tokens.
     * @notice Max 10 per transaction.
     */
    function mintReserved(uint256 numTokens, address mintTo) external onlyOwner {
        require((totalSupply() + numTokens) < maxSalePlusOne, "FoodlesClubToken: Purchase exceeds available tokens");
        require((reserveClaimed + numTokens) < MAX_RESERVED_PLUS_ONE, "FoodlesClubToken: Reservation exceeded");
        reserveClaimed += numTokens;
        _safeMint(mintTo, numTokens);
    }

    /**
     * Toggle sale state
     */
    function toggleSale() external onlyOwner {
        saleEnabled = !saleEnabled;
    }

    /**
     * Update token price
     */
    function setTokenPrice(uint256 tokenPrice_) external onlyOwner {
        tokenPrice = tokenPrice_;
    }

    /**
     * Update maximum number of tokens for sale
     */
    function setMaxSale(uint256 maxSale) external onlyOwner {
        require(maxSale + 1 < maxSalePlusOne, "FoodlesClubToken: Can only reduce supply");
        maxSalePlusOne = maxSale + 1;
    }

    /**
     * Sets base URI
     * @dev Only use this method after sell out as it will leak unminted token data.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Sets placeholder URI
     */
    function setPlaceholderURI(string memory _newPlaceHolderURI) external onlyOwner {
        placeholderURI = _newPlaceHolderURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory uri = _baseURI();
        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, tokenId.toString(), ".json")) : placeholderURI;
    }

    /**
     * @dev Return sale claim info.
     * saleClaims[0]: maxSale (total available tokens)
     * saleClaims[1]: totalSupply
     * saleClaims[2]: reserveClaimed
     * saleClaims[3]: freeClaimed
     */
    function saleClaims() public view virtual returns (uint256[4] memory) {
        return [maxSalePlusOne - 1, totalSupply(), reserveClaimed, freeClaimed];
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
