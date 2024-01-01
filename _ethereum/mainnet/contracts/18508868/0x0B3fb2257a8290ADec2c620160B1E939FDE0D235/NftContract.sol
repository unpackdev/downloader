// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./IProxyRegistry.sol";


contract NftContract is Ownable, ERC721Enumerable {
    using Strings for uint256;

    uint256[] public metadataIds;
    string[] public metadataUris;
    address public minter;

    IProxyRegistry public immutable proxyRegistry;

    event TokensCreated(uint256[] tokenIds, address indexed owner);

    event TokenCreated(uint256 indexed tokenId, address indexed owner);

    event TokenBurned(uint256 indexed tokenId);

    event MinterUpdated(address indexed minter);

    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    constructor(address owner, IProxyRegistry _proxyRegistry) ERC721("Nebularte 2023", "NBE23") {
        _transferOwnership(owner);
        proxyRegistry = _proxyRegistry;
    }

    function burn(uint256 tokenId) external onlyMinter {
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }

    function mint(address target, uint tokenId) external onlyMinter {
        _safeMint(target, tokenId);
       emit TokenCreated(tokenId, target);
    }

    function mintBulk(address target, uint[] memory tokenIds) external onlyMinter {
        require(tokenIds.length > 0, "Array sizes is invalid");
        for (uint i = 0; i < tokenIds.length; i++) {
            _safeMint(target, tokenIds[i]);
        }
        emit TokensCreated(tokenIds, target);
    }

    function exists(uint tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (address(proxyRegistry) != address(0x0) && proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        uint ipfsIndex = metadataIds.length - 1;
        for (uint i = 1; i < metadataIds.length; i++) {
            if (tokenId < metadataIds[i]) {
                ipfsIndex = i - 1;
                break;
            }
        }

        return bytes(metadataUris[ipfsIndex]).length > 0 ? string(abi.encodePacked(metadataUris[ipfsIndex], tokenId.toString())) : "";
    }

    function updateMetadata(uint[] calldata ids, string[] calldata uris) external onlyOwner {
        require(ids.length == uris.length, "Array sizes doesn't match");
        require(metadataIds.length <= ids.length, "New metadata is less than existing");

        uint j = metadataIds.length > ids.length ? ids.length : metadataIds.length;
        for (uint i = 0; i < j; i++) {
            metadataIds[i] = ids[i];
            metadataUris[i] = uris[i];
        }

        j = ids.length - metadataIds.length;
        for (uint i = metadataIds.length; i < ids.length; i++) {
            metadataIds.push(ids[i]);
            metadataUris.push(uris[i]);
        }
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0x0), "Minter can not be a zero address");
        minter = _minter;
        emit MinterUpdated(_minter);
    }

    function withdrawERC20(IERC20 _tokenContract) external onlyOwner {
        uint256 balance = _tokenContract.balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        _tokenContract.transfer(msg.sender, balance);
    }

    function approveERC721(IERC721 _tokenContract) external onlyOwner {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }
}