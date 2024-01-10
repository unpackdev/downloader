// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./ERC165Upgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";

/// @notice Base non-transferrable optimized nft contract for FWB
abstract contract FWBMembershipSkeletonNFT is
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @notice Counter for totalSupply
    CountersUpgradeable.Counter numberTokens;

    /// @notice Stores address to membership id
    mapping(address => uint256) public addressToId;

    /// @notice Stores membership id to address
    mapping(uint256 => address) private idToAddress;

    /// @notice modifier signifying contract function is not supported
    modifier notSupported() {
        revert("Fn not supported: nontransferrable NFT");
        _;
    }

    /**
        Common NFT functions
     */

    /// @notice NFT Metadata Name
    string public constant name = "FWB Membership NFT";

    /// @notice NFT Metadata Symbol
    string public constant symbol = "FWBMEM";

    /*
     *  NFT Functions
     */

    /// @notice blanaceOf getter for NFT compat
    function balanceOf(address user) public view returns (uint256) {
        return addressToId[user] == 0 ? 0 : 1;
    }

    /// @notice ownerOf getter, checks if token exists
    function ownerOf(uint256 id) public view returns (address) {
        require(
            idToAddress[id] != address(0x0),
            "ERC721: Token does not exist"
        );
        return idToAddress[id];
    }

    /// @notice approvals not supported
    function getApproved(uint256) public pure returns (address) {
        return address(0x0);
    }

    /// @notice approvals not supported
    function isApprovedForAll(address, address) public pure returns (bool) {
        return false;
    }

    /// @notice approvals not supported
    function approve(address, uint256) public notSupported {}

    /// @notice approvals not supported
    function setApprovalForAll(address, bool) public notSupported {}

    /// @notice internal safemint function
    function _safeMint(address to, uint256 id) internal {
        require(idToAddress[id] == address(0x0), "Mint: already claimed");
        require(
            to != address(0x0) && id != 0,
            "Mint: cannot mint null id or to"
        );
        numberTokens.increment();
        _transferFrom(address(0x0), to, id);
    }

    /// @notice transfer function to be overridden
    function transferFrom(
        address from,
        address to,
        uint256 checkTokenId
    ) external virtual {}

    /// @notice not supported
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public notSupported {
        // no impl
    }

    /// @notice not supported
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public notSupported {
        // no impl
    }

    /// @notice erc721 enumerable partial impl
    function totalSupply() public view returns (uint256) {
        return numberTokens.current();
    }

    /// @notice Supports ERC721, ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            ERC165Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId;
    }

    /// @notice internal burn for virtual nfts
    /// @param id of nft to burn
    function _burn(uint256 id) internal {
        address from = ownerOf(id);
        numberTokens.decrement();
        delete idToAddress[id];
        delete addressToId[from];
        emit Transfer(from, address(0x0), id);
    }

    /// @notice internal exists fn for a given token id
    function _exists(uint256 id) internal view returns (bool) {
        return idToAddress[id] != address(0x0);
    }

    /// @notice internal transfer function for virtual nfts
    /// @param from address to move from
    /// @param to address to move to
    /// @param id id of nft to move
    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        addressToId[from] = 0x0;
        idToAddress[id] = to;
        addressToId[to] = id;
        emit Transfer(from, to, id);
    }
}
