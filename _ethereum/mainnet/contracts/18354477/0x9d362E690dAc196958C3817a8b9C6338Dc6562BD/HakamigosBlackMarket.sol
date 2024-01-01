// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title: Hakamigos™
/// @author: Takuhatsu

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

/****************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░████████████░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░████████████████░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░████████████████████░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░████░░░░░░██████████░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░██████████████████████████░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░▒▒▒▒░░▒▒▒▒░░░░██░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░  ██░░  ██░░░░██░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░░░      ░░░░░░██░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░██░░░░░░░░░░░░██░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░████▒▒▒▒░░░░████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░██▒▒░░░░░░██░░░░░░██░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░██░░░░░░██░░▒▒████░░██░░░░░░░░ *
 * ░░░░░░░░░░░░████▒▒░░██████░░▒▒██▒▒▒▒██░░██░░░░░░ *
 * ░░░░░░░░░░██░░░░██▒▒▓▓▒▒▓▓▒▒██░░░░░░▒▒██░░██░░░░ *
 * ░░░░░░░░░░██░░▒▒░░██▒▒▓▓▒▒██░░░░░░░░▒▒██░░▒▒██░░ *
 * ░░░░░░░░░░██░░██▒▒░░▓▓▒▒▓▓░░░░░░██░░▒▒██░░▒▒██░░ *
 * ░░░░░░░░░░██░░██▒▒░░░░░░░░░░░░░░██░░▒▒██░░▒▒██░░ *
 * ░░░░░░░░░░██░░██▒▒░░░░░░░░░░░░░░██░░▒▒██░░▒▒██░░ *
 *                                  Hakamigos™ 2023 *
 ****************************************************/

contract HakamigosBlackMarket is ERC721, ERC721Enumerable, Ownable {
    string internal nftName = "Hakamigos";
    string internal nftSymbol = "HKMGS";

    string _baseTokenURI;

    uint16 public constant totalHakamigos = 20000;
    uint16 public constant maxHakamigosPurchase = 20;

    uint256 private mintedHakamigos;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    using Strings for uint256;
    using SafeMath for uint256;

    constructor() ERC721(nftName, nftSymbol) {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getHakamigos(uint16 numHakamigos) public {
        require(
            numHakamigos <= maxHakamigosPurchase,
            "You can mint up to 20 Hakamigos per transaction"
        );
        require(
            totalSupply().add(numHakamigos) <= totalHakamigos,
            "All Hakamigos are minted"
        );
        for (uint16 i = 0; i < numHakamigos; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function hakamigosRemained() public view returns (uint256) {
        uint256 hakamigosMinted = totalSupply();
        uint256 _hakamigosRemained = uint256(totalHakamigos).sub(
            hakamigosMinted
        );
        if (hakamigosMinted == 0) {
            return totalHakamigos;
        } else {
            return _hakamigosRemained;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
    }

    // OVERRIDES

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
