// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract LKY100 is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(address => uint256) public mintedTokens;

    constructor() ERC721("LKY100", "LKY") {
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeicckkeuspwrkjhonhivay3dkxoi5deaiknvfgexltqagln22unq4a/";
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        string memory uriSuffix = '.json';
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), uriSuffix)) : "";
    }

    function mint(uint256 _amount) public {
        for (uint256 i = 0; i < _amount;) {
            require(mintedTokens[msg.sender] < 2, "Max mint: 2 per wallet");
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            mintedTokens[msg.sender]++;
            unchecked{
                ++i;
            }
        }
    }

    function devMint(uint256 _amount, address _to) public onlyOwner {
        for (uint256 i = 0; i < _amount;) {
            _safeMint(_to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            unchecked{
                ++i;
            }
        }
    }
}
