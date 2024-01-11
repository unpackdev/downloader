// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Owned.sol";
import "./ERC1155.sol";

contract HotChainSVG is ERC1155, Owned {
    Metadata public metadata;
    mapping(address => string) public collectionName;

    event CollectionNameUpdated(address indexed collection, string name);

    constructor() Owned(msg.sender) {}

    /// @notice Mint a new "Hot Chain SVG" token
    /// @param name Name of your NFT project that uses hot-chain-svg (keep it short)
    /// @param collection Contract address of your NFT project
    function mint(string calldata name, address collection) external payable {
        uint256 tokenId = (msg.value << 160) | uint160(collection);

        if (bytes(name).length > 0) {
            if (bytes(collectionName[collection]).length == 0) {
                collectionName[collection] = name;
                emit CollectionNameUpdated(collection, name);
            }
        }

        _mint(msg.sender, tokenId, 1, "");
    }

    function burn(uint256 tokenId) external payable {
        _burn(msg.sender, tokenId, 1);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        address collection = address(uint160(tokenId));
        return metadata.uri(tokenId, collectionName[collection]);
    }

    // Admin
    function overrideCollectionName(address addr, string calldata name)
        external
        onlyOwner
    {
        collectionName[addr] = name;
        emit CollectionNameUpdated(addr, name);
    }

    function setMetadata(Metadata _metadata) external onlyOwner {
        metadata = _metadata;
    }

    function withdrawAll() external onlyOwner {
        uint256 value = address(this).balance;
        (bool success, bytes memory message) = owner.call{value: value}("");
        require(success, string(message));
    }

    function withdrawTokens(Token token, uint256 value) external onlyOwner {
        require(token.transferFrom(address(this), owner, value));
    }
}

interface Token {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

interface Metadata {
    function uri(uint256 tokenId, string memory name)
        external
        view
        returns (string memory);
}
