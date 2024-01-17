// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";

/**
 * @notice Testing token for PROOF staff.
 */
contract ProofOfStaff is ERC721, AccessControlEnumerable {
    using Counters for Counters.Counter;

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice Defines the receiver of a mint batch.
     */
    struct Receiver {
        address to;
        uint256 num;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The role allowed to mint, burn, and set the base tokenURI.
     */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The next token ID to be minted.
     */

    Counters.Counter private _nextTokenId;

    /**
     * @notice The base token URI
     */
    string private _baseTokenURI;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(string memory baseTokenURI) ERC721("PROOF of Staff", "POS") {
        _baseTokenURI = baseTokenURI;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =========================================================================
    //                           Minting
    // =========================================================================

    /**
     * @notice Allows the manager to mint a number of tokens to a given address.
     */
    function mint(address to, uint256 num) public onlyRole(MANAGER_ROLE) {
        _processMint(to, num);
    }

    /**
     * @notice Allows the manager to mint multiple tokens to given addresses.
     */
    function mint(Receiver[] calldata receivers) public onlyRole(MANAGER_ROLE) {
        for (uint256 i; i < receivers.length; ++i) {
            _processMint(receivers[i].to, receivers[i].num);
        }
    }

    /**
     * @notice Processes mints and increments the internal counter.
     */
    function _processMint(address to, uint256 num) internal {
        for (uint256 i; i < num; ++i) {
            _mint(to, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    // =========================================================================
    //                           Burning
    // =========================================================================

    /**
     * @notice Allows the manager to burn a given token.
     */
    function burn(uint256 tokenId) public onlyRole(MANAGER_ROLE) {
        _burn(tokenId);
    }

    /**
     * @notice Allows the manager to burn multiple tokens.
     */
    function burn(uint256[] calldata tokenIds) public onlyRole(MANAGER_ROLE) {
        for (uint256 i; i < tokenIds.length; ) {
            _burn(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    // =========================================================================
    //                           Internal
    // =========================================================================

    /**
     * @notice Allows the manager to set the tokenURI base.
     */
    function setBaseTokenURI(string calldata baseTokenURI)
        external
        onlyRole(MANAGER_ROLE)
    {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @notice Blocks all approved actions.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControlEnumerable.supportsInterface(interfaceId);
    }
}
