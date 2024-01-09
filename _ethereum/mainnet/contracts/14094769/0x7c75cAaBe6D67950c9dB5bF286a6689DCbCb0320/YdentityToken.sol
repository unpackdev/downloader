// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

/// @title Ydentity ID Contract
/// @author Sensible Lab
/// @dev based on a standard ERC721, each address can only have 1 ID and non-transferable
contract YdentityID is ERC721, ERC721Enumerable, Pausable, Ownable {
    /// @notice Emitted when token metadata gets updated
    event UpdateMetadata(uint256 indexed tokenId, address indexed owner);

    string private _baseUri;

    mapping(uint256 => string) private _tokenAttributes;

    constructor() ERC721("Ydentity ID", "Ydentity ID") {}

    function togglePause() external onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal pure override(ERC721) {
        revert("Ydentity ID is non-transferable");
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
        delete _tokenAttributes[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address to,
        uint256 tokenId,
        string memory attributes
    ) public {
        if (balanceOf(to) == 0) {
            require(!_exists(tokenId), "Token already exists");
            // set attributes
            _tokenAttributes[tokenId] = attributes;
            // call ERC721 safe mint
            _safeMint(to, tokenId);
        } else {
            require(
                tokenOfOwnerByIndex(to, 0) == tokenId,
                "TokenId not match. Each address can only mint once."
            );
            require(
                ownerOf(tokenId) == _msgSender(),
                "Ydentity ID can only be updated by owner"
            );
            // set attributes
            _tokenAttributes[tokenId] = attributes;

            emit UpdateMetadata(tokenId, ownerOf(tokenId));
        }
    }

    function verifySignature(
        address from,
        uint256 tokenId,
        bytes memory signature
    ) public view returns (bool) {
        require(_exists(tokenId), "Token not exists");

        bytes32 digest = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encode(_tokenAttributes[tokenId]))
        );

        address signer = ECDSA.recover(digest, signature);
        return signer == from;
    }

    function substring(
        string memory str,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }

    /// @notice get token attributes
    function getAttributes(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        return _tokenAttributes[tokenId];
    }

    /// @notice get token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory result = string(
            abi.encodePacked(
                'data:application/json;utf8,{"name":"',
                "Ydentity ID #",
                Strings.toString(tokenId),
                '",',
                '"retriveAt":',
                Strings.toString(block.timestamp),
                ",",
                '"attributes":',
                _tokenAttributes[tokenId],
                "}"
            )
        );

        return result;
    }
}
