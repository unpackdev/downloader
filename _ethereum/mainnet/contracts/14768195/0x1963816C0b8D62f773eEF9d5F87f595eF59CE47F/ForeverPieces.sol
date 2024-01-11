/* SPDX-License-Identifier: MIT */

/**
 *   @title Forever Pieces by DHL x Mykke Hofmann
 *   @author Fr0ntier X <dev@fr0ntierx.com>
 *   @notice ERC-721 token for Forever Pieces
 */

pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Mintable.sol";

contract ForeverPieces is ERC721, Ownable, Mintable {
    using Strings for uint256;

    uint256 private constant MAX_TOKEN_COUNT = 500;

    bool private _mintPaused;

    string public baseURI = "ipfs://QmQYuEuexE3FhDi4N5zetvu7hZwc8oJZGN899bH6SzKsnb/";

    constructor(address _imx) ERC721("MHNFT", "MHNFT") Mintable(msg.sender, _imx) {
        _mintPaused = false;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _mintFor(
        address to,
        uint256 id,
        bytes memory
    ) internal override {
        require(id >= 1 && id <= MAX_TOKEN_COUNT, "Invalid token ID");
        require(!_mintPaused, "Minting is paused");

        _safeMint(to, id);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function isMintPaused() external view returns (bool) {
        return _mintPaused;
    }

    function setMintPaused(bool paused) external onlyOwner {
        _mintPaused = paused;
    }
}
