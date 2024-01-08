// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC721.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract DasGestell is ERC721, ReentrancyGuard, Ownable {
    // Interfaces
    IERC721 public openPalette;

    // Constants
    uint256 public constant PRICE = 60000000000000000; // 0.06 ETH
    uint256 public constant PRICE_FOR_NON_HOLDERS = 75000000000000000; // 0.075 ETH
    uint256 public constant MAX_SUPPLY = 200;

    // Minting State Enum
    enum MintingState {
        Closed,
        Limited,
        Pre,
        Public
    }
    MintingState public mintingState = MintingState.Closed;

    string private customBaseURI;

    uint256 lastTokenId;
    mapping(address => bool) private didMint;

    constructor(
        string memory name,
        string memory symbol,
        address openPaletteAddress,
        string memory baseUri
    ) ERC721(name, symbol) {
        openPalette = IERC721(openPaletteAddress);
        customBaseURI = baseUri;
    }

    function mint() public payable nonReentrant {
        uint256 tokenId;
        unchecked {
            tokenId = lastTokenId + 1;
        }
        address minter = msg.sender;
        uint256 openPaletteCount = openPalette.balanceOf(minter);
        uint256 price = openPaletteCount > 0 ? PRICE : PRICE_FOR_NON_HOLDERS;

        // Check if minting is started or the owner is using the command
        require(mintingState != MintingState.Closed, "DasGestell:MINT_DISABLED");

        require(totalSupply() < MAX_SUPPLY, "DasGestell:MAX_SUPPLY_REACHED");

        require(msg.value >= price, "DasGestell:INVALID_PRICE");

        require(openPaletteCount > 0 || mintingState == MintingState.Public,
            "DasGestell:NO_OPEN_PALETTE"
        );

        require(canMint(minter), "DasGestell:LIMITED_MINTING");

        _safeMint(minter, tokenId);
        setDidMint(minter);
        lastTokenId = tokenId;
    }

    function ownerMint() public nonReentrant onlyOwner {
        uint256 tokenId;
        unchecked {
            tokenId = lastTokenId + 1;
        }
        address minter = msg.sender;

        require(totalSupply() < MAX_SUPPLY, "DasGestell:MAX_SUPPLY_REACHED");

        _safeMint(minter, tokenId);
        lastTokenId = tokenId;
    }

    function canMint(address minter) private view returns (bool) {
        return mintingState != MintingState.Limited || (!didMint[minter]);
    }

    function setDidMint(address minter) private {
        didMint[minter] = true;
    }

    function setMintingState(uint256 state) public onlyOwner {
        mintingState = MintingState(state);
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

    function setOpenPaletteAddress(address _address) public onlyOwner {
        openPalette = IERC721(_address);
    }

    function totalSupply() public view returns (uint256) {
        return lastTokenId;
    }
}
