// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author jpegmint.xyz

import "./AccessControl.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract GremlinsAirdrop is ERC721, ERC721Enumerable, AccessControl {

    /// Variables ///
    string internal _metadataBaseURI;
    uint256 internal _tokenMaxSupply;
	uint256[] private _tokenIdTracker;

    /// Roles ///
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// Constructor ///
    constructor(string memory name, string memory symbol, uint256 tokenMaxSupply)
    ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _tokenMaxSupply = tokenMaxSupply;
        _tokenIdTracker = new uint256[](tokenMaxSupply);
    }

    //================================================================================
    // Minting Functions
    //================================================================================

    /**
     * @dev Airdrops tokens to specified wallet addresses. Batching supported.
     */
    function airdrop(address[] memory wallets) external onlyRole(ADMIN_ROLE) {
        require(availableSupply() >= wallets.length, "Airdrop: More wallets provided than available supply");
        for (uint256 i = 0; i < wallets.length; i++) {
            uint256 tokenId = _generateTokenId();
            _mint(wallets[i], tokenId);
        }
    }

    /**
     * @dev Generate random tokenIds using Meebits random ID strategy.
     */
    function _generateTokenId() private returns (uint256) {
        uint256 remainingQty = availableSupply();
        uint256 randomIndex = _generateRandomNum(remainingQty) % remainingQty;

        // If array value exists, use, otherwise use generated random value.
        uint256 existingValue = _tokenIdTracker[randomIndex];
        uint256 tokenId = existingValue != 0 ? existingValue : randomIndex;

        // Keep track of seen indexes for black magic.
        uint256 endIndex = remainingQty - 1;
        uint256 endValue = _tokenIdTracker[endIndex];
        _tokenIdTracker[randomIndex] = endValue != 0 ? endValue : endIndex;

        return tokenId + 1; // Start tokens at #1
    }

    /**
     * @dev Generate pseudorandom number via various transaction properties.
     */
    function _generateRandomNum(uint256 seed) internal view virtual returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, tx.gasprice, block.timestamp, seed)));
    }

    /**
     * @dev Helper function to pair with total supply.
     */
    function availableSupply() public view returns (uint256) {
        return _tokenMaxSupply - totalSupply();
    }

    //================================================================================
    // Metadata Functions
    //================================================================================

    /**
     * @dev Store and update new base uri.
     */
    function setBaseURI(string memory newURI) external onlyRole(ADMIN_ROLE) {
        _metadataBaseURI = newURI;
    }

    /**
     * @dev Return the base URI for OpenZeppelin default TokenURI implementation.
     */
    function _baseURI() internal view override returns (string memory) {
        return _metadataBaseURI;
    }

    //================================================================================
    // Other Functions
    //================================================================================

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
