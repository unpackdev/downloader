// SPDX-License-Identifier: MIT
// Copyright (c) 2022 unReal Accelerator, LLC
// (https://github.com/unreal-accelerator/contracts)

/// @title: CreatorERC721Mintable
/// @author: unrealaccelerator.io

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC2981.sol";
import "./Counters.sol";

import "./AccessControlMinterRole.sol";
import "./ICreatorMintableERC721.sol";

contract CreatorERC721Mintable is
    ReentrancyGuard,
    ERC721,
    ERC2981,
    AccessControlMinterRole,
    ICreatorMintableERC721
{
    error InvalidAddress();
    error NonExistentToken();

    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    string public basePrefix;
    string private _contractURI;

    mapping(uint256 => string) private _creationCIDList;

    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI_,
        string memory basePrefix_,
        address administrator,
        address royaltyReceiver,
        uint96 feeBasisPoints
    ) ERC721(name, symbol) AccessControlMinterRole() {
        setContractURI(contractURI_);
        setBasePrefix(basePrefix_);
        if (administrator == address(0)) revert InvalidAddress();
        AccessControlMinterRole._grantRole(DEFAULT_ADMIN_ROLE, administrator);
        ERC2981._setDefaultRoyalty(payable(royaltyReceiver), feeBasisPoints);
        _nextTokenId.increment(); //start at token 1
    }

    /**
     * @dev See {ICreatorMintableERC721-mint}.
     */
    function mint(address to, string memory cid)
        public
        nonReentrant
        onlyMinter
    {
        if (to == address(0)) revert InvalidAddress();
        _safeMint(to, _nextTokenId.current());
        _creationCIDList[_nextTokenId.current()] = cid;
        _nextTokenId.increment();
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyAuthorized
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
     * @dev Returns the contract metadata for marketplaces
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Sets the token cid the contract metadata
     */
    function setTokenCID(uint256 tokenId, string memory cid)
        external
        onlyAuthorized
    {
        if (!_exists(tokenId)) revert NonExistentToken();
        require(_exists(tokenId), "Nonexistent token");
        _creationCIDList[tokenId] = cid;
    }

    /**
     * @dev Returns the metadata for a given token id
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        return string(abi.encodePacked(basePrefix, _creationCIDList[tokenId]));
    }

    /**
     * @dev Returns list of token ids owned by address
     */
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 k = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (_exists(i) && _owner == ownerOf(i)) {
                tokenIds[k] = i;
                k++;
            }
        }
        delete k;
        return tokenIds;
    }

    /**
     * @dev Updates the prefix for the token uri
     * @notice Include the trailing slash
     */
    function setBasePrefix(string memory _newBasePrefix) public onlyAuthorized {
        basePrefix = _newBasePrefix;
    }

    /**
     * @dev Updates the contract uri to the contract metadata for marketplaces
     */
    function setContractURI(string memory contractURI_) public onlyAuthorized {
        _contractURI = contractURI_;
    }

    /**
     * @dev Returns the number of tokens in circulation
     */
    function totalSupply() public view returns (uint256) {
        return (_nextTokenId.current() - 1); // total supply is one less than next id
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlMinterRole, ERC2981, ERC721, IERC165)
        returns (bool)
    {
        return
            AccessControlMinterRole.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            type(ICreatorMintableERC721).interfaceId == interfaceId;
    }
}
