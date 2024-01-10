// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title BLOBHEAD ERC721 CONTRACT
 */

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

/// @title  Minting your Blob 

contract BlobHeads is Ownable, ERC721 {
    
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter public totalBlobs;

    string private _currentBaseURI;
    uint256 private maxBlobs = 2000;

    address receiver;

    constructor() ERC721("BlobHeads", "BLOB") {
        setBaseURI("test/");
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        _currentBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return _currentBaseURI;
    }

    function setReceiver(address _receiver) public onlyOwner {
        receiver = _receiver;
    }

    function mintBlob() payable public
    { 
        require(msg.value == 0.05 ether);
        require(totalBlobs.current() < maxBlobs);

        uint256 newBlobId = totalBlobs.current();

        totalBlobs.increment();

        _safeMint(msg.sender, newBlobId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        return bytes(_currentBaseURI).length > 0 ? string(abi.encodePacked(_currentBaseURI, tokenId.toString(), ".json")) : "";
    }

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

    function fetchBalance() external
    {
        require(msg.sender == receiver);
        payable(msg.sender).transfer(address(this).balance);
    }
}