// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IOpenPalette.sol";
import "./IP.sol";

contract WaterPalette is ERC721Enumerable, ReentrancyGuard, Ownable {
    // Interfaces
    IOpenPalette public openPalette;
    IP public p;

    // Constants
    uint256 public constant BASE_PRICE = 20000000000000000; // 0.02 ETH
    uint256 public constant OP_HOLDER_PRICE_REDUCTION = 10000000000000000; // OpenPalette holders will pay 0.01 ETH less
    uint256 public constant P_HOLDER_PRICE_REDUCTION = 10000000000000000; // P holders will pay 0.01 ETH less
    uint256 public constant MAX_SUPPLY = 10000;

    // Minting State Enum
    enum MintingState {
        Pre,
        Public,
        Closed
    }
    MintingState public mintingState = MintingState.Closed;

    string private customBaseURI;

    /**
     * @notice Construct a WaterPalette instance
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param openPaletteAddress Address of the OpenPalette instance
     * @param pAddress Address of the P instance
     */
    constructor(
        string memory name,
        string memory symbol,
        address openPaletteAddress,
        address pAddress,
        string memory baseUri
    ) ERC721(name, symbol) {
        openPalette = IOpenPalette(openPaletteAddress);
        p = IP(pAddress);
        customBaseURI = baseUri;
    }

    /**
     * @notice Mint WaterPalette tokens.
     *         Pre-sale:
     *           - Only OpenPalette holders can mint
     *           - OpenPalette holders will pay 0.01 ETH
     *           - P holders will pay nothing
     *         Public-sale:
     *           - Everyone can mint
     *           - OpenPalette holders will pay 0.01 ETH
     *           - If minter holds both P and OpenPalette, they will pay nothing
     *           - If minter holds P but not OpenPalette, they will pay 0.01 ETH
     *           - Non-holders will pay 0.02 ETH
     * @param tokenIds Ids to be minted
     */
    function mint(uint256[] calldata tokenIds) public payable virtual nonReentrant {
        address minter = msg.sender;

        // Check if minting is started or the owner is using the command
        require(mintingState != MintingState.Closed || minter == owner(), "WaterPalette:MINT_DISABLED");

        uint256 tokenCount = tokenIds.length;
        require(totalSupply() + tokenCount <= MAX_SUPPLY, "WaterPalette:MAX_SUPPLY_REACHED");

        uint256 requiredPrice = getMintPrice(minter, tokenIds);
        require(msg.value >= requiredPrice, "WaterPalette:INVALID_PRICE");

        for (uint256 i = 0; i < tokenCount; i++) {
            require(tokenIds[i] >= 0 && tokenIds[i] < 10000, "WaterPalette:INVALID_TOKEN");
            require(
                mintingState != MintingState.Pre || minter == owner() || openPalette.ownerOf(tokenIds[i]) == minter,
                "WaterPalette:INVALID_OWNER"
            );
            require(!_exists(tokenIds[i]), "WaterPalette:ALREADY_MINTED");
            _safeMint(minter, tokenIds[i]);
        }
    }

    function getMintPrice(address minter, uint256[] calldata tokenIds) private view returns (uint256) {
        if (minter == owner()) return 0;

        uint256 tokenCount = tokenIds.length;

        uint256 price = tokenCount * BASE_PRICE;
        uint256 opPriceReduction = 0;
        uint256 pPriceReduction = 0;

        for (uint256 i = 0; i < tokenCount; i++) {
            if (getOpenPaletteOwner(tokenIds[i]) == msg.sender) {
                opPriceReduction += OP_HOLDER_PRICE_REDUCTION;
            }
            if (getPOwner(tokenIds[i]) == msg.sender) {
                pPriceReduction += P_HOLDER_PRICE_REDUCTION;
            }
        }

        price -= pPriceReduction + opPriceReduction;

        return price;
    }

    function getOpenPaletteOwner(uint256 tokenId) private view returns (address) {
        try openPalette.ownerOf(tokenId) returns (address owner) {
            return (owner);
        } catch {}
        return address(0);
    }

    function getPOwner(uint256 tokenId) private view returns (address) {
        try p.ownerOf(tokenId) returns (address owner) {
            return (owner);
        } catch {}
        return address(0);
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

    function setOpenPaletteAddress(address _address) public onlyOwner {
        openPalette = IOpenPalette(_address);
    }

    function setPAddress(address _address) public onlyOwner {
        p = IP(_address);
    }
}
