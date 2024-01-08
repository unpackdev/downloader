//SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./Ownable.sol";

contract FounderWhitelistNFT is ERC721, Ownable {
    uint256 count = 0;
    string _uri;

    constructor(string memory ipfs) ERC721("Sk8Whitelist", "SK8W") {
        _uri = ipfs;
    }

    function mint(address to) public onlyOwner {
        count++;
        _safeMint(to, count);
    }

    function setURI(string memory uri) public onlyOwner {
        _uri = uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _uri;
    }
}
