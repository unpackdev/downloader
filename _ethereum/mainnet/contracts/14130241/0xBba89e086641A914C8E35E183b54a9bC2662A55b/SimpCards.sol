// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";

contract SimpCards is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    bool public revealed = false;

    string public hiddenMetadataUri;
    string public baseTokenURI;

    mapping (address => uint256) private addrBalance;

    uint256 public immutable maxSupply = 888;
    uint256 public maxPerWallet = 2;

    constructor() ERC721("Simp Cards", "SIMPCARDS") Ownable() {
        _tokenIds.increment();
        hiddenMetadataUri = "https://arweave.net/NVZ1dTM8Mz2cC2-YRLL-QV0RYt9jFmhlyF9_RKbxagY";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
        revealed = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function mint(uint256 qty) public nonReentrant {
        uint256 tokensOwned = balanceOf(msg.sender);

        require(tokensOwned + qty <= maxPerWallet, "MAX MINT LIMIT HIT");

        uint256 currentSupply = totalSupply();
        require(currentSupply + qty <= maxSupply, "NOT ENOUGH MINTS AVAILABLE");

        for(uint256 i = 0; i < qty; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIds.increment();
        }
    }

    
}
