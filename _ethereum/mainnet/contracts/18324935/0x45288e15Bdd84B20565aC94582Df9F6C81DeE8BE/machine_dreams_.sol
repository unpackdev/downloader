// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";  // Import Ownable from OpenZeppelin

contract MachineDreams is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {  // Inherit from Ownable
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant SALE_PRICE = 10**17; // 0.1 ETH in wei
    uint256 public constant MAX_TOKENS = 10000;  // Maximum number of tokens

    constructor() ERC721("MachineDreams", "MD") {}

    function contractURI() public pure returns (string memory) {
        string memory json = '{"name": "Machine Dreams","description": "Machine Dreams is an art project that uses Artificial intelligence to generate art every hour based on what is trending on Google in the U.S.","image": "ipfs://bafkreib4gys2zvkhx77cvdit6jxilyj5gw64fejemk2q6jwqrzbfr7hram","external_link": "ipfs://bafkreib4gys2zvkhx77cvdit6jxilyj5gw64fejemk2q6jwqrzbfr7hram"}';
        return string.concat("data:application/json;utf8,", json);
    }

    function purchaseNFT(string memory uri) external payable {
        require(msg.value == SALE_PRICE && _tokenIdCounter.current() < MAX_TOKENS, "Invalid operation");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function withdraw() external onlyOwner {  // onlyOwner modifier ensures only the contract creator can call this function
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);  // Transfer all funds to the contract creator
    }

    // Overrides

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
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
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
