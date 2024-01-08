pragma solidity ^0.8.4;

import "./NFT721Basic.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev Optional enumeration implementation for ERC-721 non-fungible token standard.
 */
contract NFT721Enumerable is NFT721Basic, ERC721Enumerable {
    /**
     * @dev Contract constructor.
     */
    constructor(string memory name, string memory symbol)
        public
        NFT721Basic(name, symbol)
    {
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
    }

    /**
     * @dev Returns the count of all existing NFTokens.
     * @return Total supply of NFTs.
     */
    function totalSupply() external view override returns (uint256) {
        return tokens.length;
    }

    /**
     * @dev Returns NFT ID by its index.
     * @param _index A counter less than `totalSupply()`.
     * @return Token id.
     */
    function tokenByIndex(uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        require(_index < tokens.length, "invalid index");
        return tokens[_index];
    }

    /**
     * @dev returns the n-th NFT ID from a list of owner's tokens.
     * @param _owner Token owner's address.
     * @param _index Index number representing n-th token in owner's list of tokens.
     * @return Token id.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        require(_index < ownerToIds[_owner].length, "invalid index");
        return ownerToIds[_owner][_index];
    }
}
