// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721.sol";

contract SameApeYachtClub is ERC721 {
    /// Storage ///

    string public constant baseURI =
        "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    uint256 public constant MAX_TOKEN_ID = 9999;
    uint256 public constant PRICE = 0.015 ether;
    address public owner;
    uint256 public totalSupply = 0;

    /// Errors
    error InvalidETHAmount();
    error InvalidId();
    error FailedToSendETH();

    /// Constructor ///

    constructor() ERC721("Same Ape Yacht Club", "SAYC") {
        owner = msg.sender;
    }

    /// External/Public Methods ///

    function claim(uint256 id) external payable {
        if (msg.value != PRICE) revert InvalidETHAmount();
        if (id > 9999) revert InvalidId();
        _mint(msg.sender, id);
        ++totalSupply;
        (bool sent, ) = payable(owner).call{value: msg.value}("");
        if (!sent) revert FailedToSendETH();
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (id > 9999) revert InvalidId();
        if (_ownerOf[id] == address(0)) revert InvalidId();

        return string.concat(baseURI, _toString(id));
    }

    /// Internal Methods ///

    function _toString(uint256 value) internal pure returns (string memory) {
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
}
