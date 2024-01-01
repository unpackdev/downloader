// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract TheMachineDreams is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant SALE_PRICE = 10**17; // 0.1 ETH in wei
    uint256 public constant MAX_TOKENS = 10000;  // Maximum number of tokens

    mapping(string => bool) private _uriMinted;  // Mapping to keep track of minted URIs

    constructor() ERC721("TheMachineDreams", "TMD") {}

    function contractURI() public pure returns (string memory) {
        string memory json = '{"name": "The Machine Dreams","description": "The Machine Dreams is an art project that uses Artificial intelligence to generate art every hour based on what is trending on Google in the U.S.","image": "ipfs://bafkreib4gys2zvkhx77cvdit6jxilyj5gw64fejemk2q6jwqrzbfr7hram","external_link": "ipfs://bafkreib4gys2zvkhx77cvdit6jxilyj5gw64fejemk2q6jwqrzbfr7hram"}';
        return string.concat("data:application/json;utf8,", json);
    }

    function purchaseNFT(string memory uri) external payable {
        require(msg.value == SALE_PRICE && _tokenIdCounter.current() < MAX_TOKENS, "Invalid operation");
        require(!_uriMinted[uri], "URI has already been minted");  // Ensure the URI has not been minted before

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        _uriMinted[uri] = true;  // Mark the URI as minted
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    fallback() external {
        revert("Contract does not accept Ether directly");
    }

    // Overrides

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transfer(from, to, tokenId);
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
