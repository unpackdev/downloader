// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title HippoU Token
/// https://hippoarmy.com

import "./ERC721Optimised.sol";
import "./DevPayable.sol";
import "./Counters.sol";

contract HippoToken is ERC721Optimised, DevPayable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter public tokenCounter;

    uint256 public constant MAX_PER_TRANS = 10;

    uint256 public tokenPrice = 0.025 ether;

    uint256 public saleUpTo = 0;

    string public baseURI;
    string public placeholderURI;

    constructor(address payable _devAddress) ERC721Optimised("HippoU", "HIPPO") DevPayable(_devAddress) {}

    //
    // Minting
    //

    /**
     * Mint tokens
     */
    function mint(uint256 numTokens)
        external
        payable
    {
        require((tokenCounter.current() + numTokens) <= saleUpTo, "HippoToken: Purchase exceeds available tokens");
        require(numTokens <= MAX_PER_TRANS, "HippoToken: Can only mint 10 at a time");
        require((tokenPrice * numTokens) <= msg.value, "HippoToken: Ether value sent is not correct");
        doMint(numTokens, msg.sender);
    }

    /**
     * Mints reserved tokens
     * @dev Recommended this method mints a maximum of 10 tokens per call to prevent out of gas errors.
     */
    function mintReserved(uint256 numTokens, address mintTo) external onlyOwner {
        doMint(numTokens, mintTo);
    }

    function doMint(uint256 numTokens, address mintTo) internal {
        for (uint256 i = 0; i < numTokens; i++) {
            tokenCounter.increment();
            _mint(mintTo, tokenCounter.current());
        }
    }

    /**
     * Set sale up to
     * @dev This function is inclusive
     */
    function setSaleUpTo(uint256 _saleUpTo) external onlyOwner {
        saleUpTo = _saleUpTo;
    }

    /**
     * Set token price
     */
    function setTokenPrice(uint256 _newTokenPrice) external onlyOwner {
        tokenPrice = _newTokenPrice;
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
     * @dev Only use this method after sell out as it will leak unminted token data.
     */
    function setPlaceholderURI(string memory _newPlaceHolderURI) external onlyOwner {
        placeholderURI = _newPlaceHolderURI;
    }

    /**
     * Returns the number of tokens minted.
     */
    function totalSupply() external view returns (uint256) {
        return tokenCounter.current();
    }

    /**
     * @dev See {IERC721-balanceOf}.
     * This is NOT gas efficient, but doing this saves gas during mint and transfer by reducing variables.
     * Highly recommend NOT integrating to this interface in other contracts.
     */
    function balanceOf(address owner) external view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        uint256 owned = 0;
        // Loop through tokens to find the owner
        for (uint256 i = 1; i <= tokenCounter.current(); i++) {
            if (_owners[i] == owner) {
                owned++;
            }
        }
        return owned;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory uri = _baseURI();
        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, tokenId.toString(), ".json")) : placeholderURI;
    }
}
