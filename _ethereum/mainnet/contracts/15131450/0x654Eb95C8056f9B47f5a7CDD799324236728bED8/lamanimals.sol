// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// Created by Ghora Ghori Club

contract Lamanimals is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool     public staticUri = true;
    string   private _baseUri;
    mapping(uint256 => string) private uris;
    mapping(address => bool) public controllers;

    constructor() ERC721A("Lamanimals", "LMN") {
        controllers[msg.sender] = true;
    }

    function setURI(uint256 _tokenId, string memory newURI) public onlyController {
        uris[_tokenId] = newURI;
    }

    function setController(address controller, bool enable) public onlyOwner {
        controllers[controller] = enable;
    }

    function setBaseUri(string memory newBaseUri) public onlyController {
        _baseUri = newBaseUri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token not exists");

        if (staticUri) {
            return string(abi.encodePacked(_baseUri, _tokenId.toString(), ".json"));
        }

        string memory dataURI = uris[_tokenId];
        return (dataURI);
    }

    function creatorMint(address _to, uint256 _amount) public onlyController {
        _safeMint(_to, _amount);
    }

    function withdrawETH() public payable onlyController {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    modifier senderIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyController() {
        require(controllers[msg.sender], "The caller is not controller");
        _;
    }
}