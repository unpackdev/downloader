// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title HawaiianLions Token
/// @author @MilkyTasteEth MilkyTaste:8662 https://milkytaste.xyz
/// https://www.hawaiianlions.world/

import "./ERC721Optimised.sol";
import "./Payable.sol";

contract HawaiianLionsToken is ERC721Optimised, Payable {
    using Strings for uint256;

    // Token values incremented for gas efficiency
    uint256 private constant MAX_SALE_PLUS_TWO = 557;
    uint256 private constant MAX_RESERVED_PLUS_ONE = 36;
    uint256 private constant MAX_PER_TRANS_PLUS_ONE = 6;

    uint256 private tokenCounter = 1;
    uint256 private reserveClaimed = 0;
    uint256 public constant TOKEN_PRICE = 0.05 ether;

    bool public saleEnabled = false;

    address public utilityAddress;

    string public baseURI;
    string public placeholderURI;

    constructor(address payable _devAddress) ERC721Optimised("HawaiianLions", "HLION") Payable(_devAddress) {}

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
        require(msg.sender == tx.origin, "HawaiianLionsToken: No bots");
        require(saleEnabled, "HawaiianLionsToken: Sale is not active");
        require((tokenCounter + numTokens) < MAX_SALE_PLUS_TWO, "HawaiianLionsToken: Purchase exceeds available tokens");
        require(numTokens < MAX_PER_TRANS_PLUS_ONE, "HawaiianLionsToken: Can only mint 5 at a time");
        require((TOKEN_PRICE * numTokens) == msg.value, "HawaiianLionsToken: Ether value sent is not correct");
        doMint(numTokens, msg.sender);
    }

    /**
     * Mints reserved tokens
     */
    function mintReserved(uint256 numTokens, address mintTo) external onlyOwner {
        require((tokenCounter + numTokens) < MAX_SALE_PLUS_TWO, "HawaiianLionsToken: Purchase exceeds available tokens");
        require((reserveClaimed + numTokens) < MAX_RESERVED_PLUS_ONE, "HawaiianLionsToken: Reservation exceeded");
        reserveClaimed += numTokens;
        doMint(numTokens, mintTo);
    }

    /**
     * Mint by utility contract.
     * @dev This function is reserved for future utility.
     */
    function mintUtility(uint256 numTokens, address mintTo) external {
        require(msg.sender == utilityAddress, "HawaiianLionsToken: Only callable by utility address");
        doMint(numTokens, mintTo);
    }

    function doMint(uint256 numTokens, address mintTo) internal {
        for (uint256 i = 0; i < numTokens; i++) {
            _mint(mintTo, tokenCounter + i);
        }
        tokenCounter += numTokens;
    }

    /**
     * Toggle sale state
     */
    function toggleSale() external onlyOwner {
        saleEnabled = !saleEnabled;
    }

    /**
     * Set the minter address.
     * @notice This is for future utility.
     */
    function setUtilityAddress(address _utilityAddress) external onlyOwner {
        utilityAddress = _utilityAddress;
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
     * Returns the number of tokens minted.
     */
    function totalSupply() external view returns (uint256) {
        return tokenCounter - 1;
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
        for (uint256 i = 1; i <= tokenCounter; i++) {
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
