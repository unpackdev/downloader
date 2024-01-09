// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";


/**
 * @title ERC721Common
 * ERC721Common - ERC721 contract with basic functionality and AccessControl
 */
abstract contract ERC721Common is ERC721, AccessControl {
    using SafeMath for uint256;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Returns the base uri used for all the tokens
     */
    function baseTokenURI() virtual public pure returns (string memory);

    /**
     * @dev Returns the tokenURI for the tokenId, which is just baseTokenURI + tokenId
    * @param _tokenId the tokenId
     */
    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * @dev verifies if the interfaceId passed in is supported 
     * Must be implemented here due to Solidity limitations
     * @param interfaceId interface being supported
     */
    function supportsInterface(bytes4 interfaceId)
        public
        virtual
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}