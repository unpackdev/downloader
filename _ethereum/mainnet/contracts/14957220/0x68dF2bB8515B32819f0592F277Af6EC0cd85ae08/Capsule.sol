// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ICapsuleFactory.sol";

contract Capsule is ERC721URIStorage, ERC721Enumerable, Ownable {
    // solhint-disable-next-line var-name-mixedcase
    string public VERSION;
    string public constant LICENSE = "www.capsulenft.com/license";
    ICapsuleFactory public immutable factory;
    /// @notice Token URI owner can change token URI of any NFT.
    address public tokenURIOwner;
    uint256 public counter;
    /// @notice Max possible NFT id of this collection
    uint256 public maxId = type(uint256).max;
    /// @notice Flag indicating whether this collection is private.
    bool public immutable isCollectionPrivate;

    event TokenURIOwnerUpdated(address indexed oldOwner, address indexed newOwner);
    event TokenURIUpdated(uint256 indexed tokenId, string oldTokenURI, string newTokenURI);

    constructor(
        string memory _name,
        string memory _symbol,
        address _tokenURIOwner,
        bool _isCollectionPrivate
    ) ERC721(_name, _symbol) {
        isCollectionPrivate = _isCollectionPrivate;
        factory = ICapsuleFactory(_msgSender());
        // Address zero as tokenURIOwner is valid
        tokenURIOwner = _tokenURIOwner;
        VERSION = ICapsuleFactory(_msgSender()).VERSION();
    }

    modifier onlyMinter() {
        require(factory.capsuleMinter() == _msgSender(), "!minter");
        _;
    }

    modifier onlyTokenURIOwner() {
        require(tokenURIOwner == _msgSender(), "caller is not tokenURI owner");
        _;
    }

    /******************************************************************************
     *                              Read functions                                *
     *****************************************************************************/

    /// @notice Check whether given tokenId exists.
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @notice Check if the Capsule collection is locked.
    /// @dev This is checked by ensuring the counter is greater than the maxId.
    function isCollectionLocked() public view returns (bool) {
        return counter > maxId;
    }

    /// @notice Check whether given address is owner of this collection.
    function isCollectionMinter(address _account) external view returns (bool) {
        if (isCollectionPrivate) {
            return owner() == _account;
        }
        return true;
    }

    /// @notice Returns tokenURI of given tokenId.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    /******************************************************************************
     *                             Write functions                                *
     *****************************************************************************/

    function burn(address _account, uint256 _tokenId) external onlyMinter {
        require(ERC721.ownerOf(_tokenId) == _account, "not NFT owner");
        _burn(_tokenId);
    }

    /**
     * @notice Lock collection at provided NFT count (the collection total NFT count),
     * preventing any further minting past the given NFT count.
     * @dev Max id of this collection will be provided NFT count minus one.
     */
    function lockCollectionCount(uint256 _nftCount) external virtual onlyOwner {
        require(maxId == type(uint256).max, "collection is already locked");
        require(_nftCount > 0, "_nftCount is zero");
        require(_nftCount >= counter, "_nftCount is less than counter");

        maxId = _nftCount - 1;
    }

    function mint(address _account, string memory _uri) external onlyMinter {
        require(!isCollectionLocked(), "collection is locked");
        _safeMint(_account, counter);
        _setTokenURI(counter, _uri);
        counter++;
    }

    /******************************************************************************
     *                             Owner functions                                *
     *****************************************************************************/
    /// @notice Set new token URI for given tokenId. Only tokenURI owner can set a new URI.
    function setTokenURI(uint256 _tokenId, string memory _newTokenURI) external onlyTokenURIOwner {
        emit TokenURIUpdated(_tokenId, tokenURI(_tokenId), _newTokenURI);
        _setTokenURI(_tokenId, _newTokenURI);
    }

    /// @notice Update token URI owner. OnlyTokenURIOwner can call this function.
    function updateTokenURIOwner(address _newTokenURIOwner) external onlyTokenURIOwner {
        emit TokenURIOwnerUpdated(tokenURIOwner, _newTokenURIOwner);
        tokenURIOwner = _newTokenURIOwner;
    }

    function renounceOwnership() public override onlyOwner {
        factory.updateCapsuleCollectionOwner(_msgSender(), address(0));
        super.renounceOwnership();
    }

    function transferOwnership(address _newOwner) public override onlyOwner {
        if (_msgSender() != address(factory)) {
            factory.updateCapsuleCollectionOwner(_msgSender(), _newOwner);
        }
        super.transferOwnership(_newOwner);
    }

    /******************************************************************************
     *                            Internal functions                              *
     *****************************************************************************/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(tokenId);
    }
}
