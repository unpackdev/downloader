// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

contract StandWithUkraine is
    ERC721URIStorage,
    ERC721Enumerable,
    PaymentSplitter,
    Ownable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 private constant MINIMUM_MINT_PRICE = 5e16; // 0.05 ETH
    string private constant METADATA_URI =
        "https://gateway.pinata.cloud/ipfs/QmZGUf69yaFT2ukvjWCCHgNmffqSK8Att4sJjnVCCg9qjq";

    address[] private CHARITIES = [
        address(0xAD937C65B06C43821C633768d97a73f7568aC4Bf), // Project Hope
        address(0x64CeB9608Df2fa50Fc11cDA6213d444c5612Ed8c), // WCK
        address(0x6593C7e197A37A47B8D99D04230cc36757eF7f48), // FFL
        address(0xDa275Da0c213AFE93D7dDAE855de8582AC7Cc6c7) // Impact3
    ];
    uint256[] private SHARES = [
        uint256(33),
        uint256(33),
        uint256(33),
        uint256(1)
    ];

    constructor()
        ERC721("StandWithUkraine", "SWU")
        PaymentSplitter(CHARITIES, SHARES)
    {}

    function safeMint(address to) public payable {
        require(
            msg.value >= MINIMUM_MINT_PRICE,
            "Minimum mint price is 0.05 ETH"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, METADATA_URI);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
