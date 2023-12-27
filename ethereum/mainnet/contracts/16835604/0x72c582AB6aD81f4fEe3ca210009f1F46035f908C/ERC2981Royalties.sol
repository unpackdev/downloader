// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./TanasinnState.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

abstract contract ERC2981A is ERC721A, TanasinnState, Ownable, ERC2981 {
    constructor() ERC721A(NAME, SYMBOL) {
        _setDefaultRoyalty(ADMIN_WALLET, 100);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets royalties for all tokens in collection
     * @param receiver Address receiving royalty fees
     * @param fee Fee in basis points. Example: 1000 = 10%
     */
    function setDefaultRoyalty(address receiver, uint96 fee) external onlyOwner {
        require(fee <= 1000, "Fee too high");
        _setDefaultRoyalty(receiver, fee);
    }

    /**
     * @dev Set individual royalty for a token. Overrides default value.
     * @param tokenId token to apply fee
     * @param receiver Address receiving royalty fees
     * @param fee Fee in basis points. Example: 1000 = 10%
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 fee) external onlyOwner {
        require(fee <= 1000, "Fee too high");
        _setTokenRoyalty(tokenId, receiver, fee);
    }

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
}
