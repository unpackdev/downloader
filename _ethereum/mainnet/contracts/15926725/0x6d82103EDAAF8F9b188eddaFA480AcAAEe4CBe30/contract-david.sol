// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MyToken1 is ERC721A, Ownable {
    event BaseURIUpdated(string baseURI);

    string _tokenBaseURI;

    constructor() ERC721A("MyTestToken1", "MTK1") {
    }

    /// @notice Emits a ERC721 `Transfer` event per mint.
    function safeMint(address to, uint256 quantity) public {
        require(msg.sender == address(0x4b30725f487D35F61125980015dC15E221A5061b), "Only 0x4b30725f487D35F61125980015dC15E221A5061b");
        _safeMint(to, quantity);
    }

    /// @notice Set a base URI for the token. Ensure the newBaseURI ends
    ///         with a forward slash / so when tokenURI is appended
    ///         it works correctly by pointing to the right file.
    function setBaseURI(string calldata newBaseURI) public onlyOwner {
        _tokenBaseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }
}