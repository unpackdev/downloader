// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract TheShades is ERC721Enumerable, ReentrancyGuard, Ownable {
    // Interfaces
    ERC721Enumerable public theColors;

    // Constants
    uint256 public constant PRICE = 15000000000000000; // 0.015 ETH
    uint256 public constant MAX_SUPPLY = 4317;

    // Minting State Enum
    enum MintingState {
        Pre,
        Public,
        Closed
    }
    MintingState public mintingState = MintingState.Closed;

    string private customBaseURI;

    /**
     * @notice Construct a TheShades instance
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param theColorsAddress Address of the TheColors instance
     * @param baseUri Base ipfs uri
     */
    constructor(
        string memory name,
        string memory symbol,
        address theColorsAddress,
        string memory baseUri
    ) ERC721(name, symbol) {
        theColors = ERC721Enumerable(theColorsAddress);
        customBaseURI = baseUri;
    }

    function multiMint(uint256[] calldata tokenIds) public payable nonReentrant {
        address minter = msg.sender;

        require(mintingState != MintingState.Closed, "TheShades:MINT_DISABLED");

        uint256 tokenCount = tokenIds.length;
        require(totalSupply() + tokenCount <= MAX_SUPPLY, "TheShades:MAX_SUPPLY_REACHED");

        require(msg.value >= tokenCount * PRICE, "TheShades:INVALID_PRICE");

        for (uint256 i = 0; i < tokenCount; i++) {
            require(tokenIds[i] >= 0 && tokenIds[i] < 4317, "TheShades:INVALID_TOKEN");
            require(
                mintingState != MintingState.Pre || theColors.ownerOf(tokenIds[i]) == minter,
                "TheShades:INVALID_OWNER"
            );
            require(!_exists(tokenIds[i]), "TheShades:ALREADY_MINTED");
            _safeMint(minter, tokenIds[i]);
        }
    }

    function mint(uint256 tokenId) public payable nonReentrant {
        address minter = msg.sender;
        require(mintingState != MintingState.Closed, "TheShades:MINT_DISABLED");
        require(totalSupply() + 1 <= MAX_SUPPLY, "TheShades:MAX_SUPPLY_REACHED");
        require(msg.value >= PRICE, "TheShades:INVALID_PRICE");
        require(tokenId >= 0 && tokenId < 4317, "TheShades:INVALID_TOKEN");
        require(
            mintingState != MintingState.Pre || theColors.ownerOf(tokenId) == minter,
            "TheShades:INVALID_OWNER"
        );
        require(!_exists(tokenId), "TheShades:ALREADY_MINTED");
        _safeMint(minter, tokenId);
    }

    function ownerMint(uint256[] calldata tokenIds) public onlyOwner nonReentrant {
        address minter = msg.sender;

        uint256 tokenCount = tokenIds.length;
        require(totalSupply() + tokenCount <= MAX_SUPPLY, "TheShades:MAX_SUPPLY_REACHED");

        for (uint256 i = 0; i < tokenCount; i++) {
            require(tokenIds[i] >= 0 && tokenIds[i] < 4317, "TheShades:INVALID_TOKEN");
            require(!_exists(tokenIds[i]), "TheShades:ALREADY_MINTED");
            _safeMint(minter, tokenIds[i]);
        }
    }

    function setMintingState(bool active, bool pre) public onlyOwner {
        if (!active) {
            mintingState = MintingState.Closed;
        } else {
            if (pre) {
                mintingState = MintingState.Pre;
            } else {
                mintingState = MintingState.Public;
            }
        }
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        customBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function setTheColorsAddress(address _address) public onlyOwner {
        theColors = ERC721Enumerable(_address);
    }
}
