// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract SecretTokyoClub is ERC721A, Ownable, ReentrancyGuard {
    string private _currentBaseURI;

    uint32 public constant MAX_SUPPLY = 5_000;
    uint32 public constant MAX_FREE_SUPPLY = 1000;
    uint32 public constant MAX_PER_TX = 5;
    uint32 public constant MAX_FREE_PER_WALLET = 2;

    uint256 public constant MINT_PRICE = 0.003 ether;

    bool public isLive = false;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("Secret Tokyo Club", "STClub") {
        _currentBaseURI = "https://secret-tokyo-club.com/metadata/";
    }

    function mint(uint256 count) external payable nonReentrant {
        require(isLive, "Minting is not live yet.");
        require(totalSupply() + count <= MAX_SUPPLY, "Sold Out!");
        require(count <= MAX_PER_TX, "Max per TX reached.");
        require(
            msg.value >= count * MINT_PRICE,
            "Please send the exact amount."
        );

        _safeMint(msg.sender, count);
    }

    function freeMint(uint32 count) external nonReentrant {
        require(isLive, "Minting is not live yet.");
        require(totalSupply() + count <= MAX_SUPPLY, "Sold Out!");
        require(
            totalSupply() + count <= MAX_FREE_SUPPLY,
            "Free Mint Sould Out!"
        );
        require(
            _mintedFreeAmount[msg.sender] + count <= MAX_FREE_PER_WALLET,
            "You can only mint two pieces for free."
        );

        _mintedFreeAmount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function setStateMint(bool _state) public onlyOwner {
        isLive = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        _currentBaseURI = baseUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os, "Transfer failed.");
    }
}
