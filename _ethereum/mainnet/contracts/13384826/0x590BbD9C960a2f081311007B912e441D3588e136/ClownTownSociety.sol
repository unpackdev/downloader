// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface CryptoPunksAssets {
    function composite(bytes1, bytes1, bytes1, bytes1, bytes1) external view returns (bytes4);
    function getAsset(uint8) external view returns (bytes memory);
    function getAssetName(uint8) external view returns (string memory);
    function getAssetType(uint8) external view returns (uint8);
    function getAssetIndex(string calldata, bool) external view returns (uint8);
    function getMappedAsset(uint8, bool) external view returns (uint8);
}

interface CryptoPunksData {
    function punkAttributes(uint16) external view returns (string memory);
}

interface CryptoPunksMarket {
    function punkIndexToAddress(uint256) external view returns (address);
}

//   ██████╗██╗      ██████╗ ██╗    ██╗███╗   ██╗    ████████╗ ██████╗ ██╗    ██╗███╗   ██╗    ███████╗ ██████╗  ██████╗██╗███████╗████████╗██╗   ██╗
//  ██╔════╝██║     ██╔═══██╗██║    ██║████╗  ██║    ╚══██╔══╝██╔═══██╗██║    ██║████╗  ██║    ██╔════╝██╔═══██╗██╔════╝██║██╔════╝╚══██╔══╝╚██╗ ██╔╝
//  ██║     ██║     ██║   ██║██║ █╗ ██║██╔██╗ ██║       ██║   ██║   ██║██║ █╗ ██║██╔██╗ ██║    ███████╗██║   ██║██║     ██║█████╗     ██║    ╚████╔╝ 
//  ██║     ██║     ██║   ██║██║███╗██║██║╚██╗██║       ██║   ██║   ██║██║███╗██║██║╚██╗██║    ╚════██║██║   ██║██║     ██║██╔══╝     ██║     ╚██╔╝  
//  ╚██████╗███████╗╚██████╔╝╚███╔███╔╝██║ ╚████║       ██║   ╚██████╔╝╚███╔███╔╝██║ ╚████║    ███████║╚██████╔╝╚██████╗██║███████╗   ██║      ██║   
//   ╚═════╝╚══════╝ ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝       ╚═╝    ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝    ╚══════╝ ╚═════╝  ╚═════╝╚═╝╚══════╝   ╚═╝      ╚═╝   

contract ClownTownSociety is ERC721Enumerable, Ownable {
    CryptoPunksAssets private cryptoPunksAssets;
    CryptoPunksData private cryptoPunksData;
    CryptoPunksMarket private cryptoPunksMarket;
    
    enum Type { Kind, Face, Ear, Neck, Beard, Hair, Eyes, Mouth, Smoke, Nose }

    uint16 private constant MAX_COUNT = 10000;
    uint256 private BASE_PRICE_IN_WEI;
    uint256 private SEED;

    mapping(uint16 => bytes) private clowns;
    mapping(uint16 => uint16) private clownsToPunks;
    mapping(uint16 => uint16) private punksToClowns;

    bool private shouldVerifyCryptoPunkOwnership;
    bool private contractSealed;

    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }

    constructor() ERC721("ClownTownSociety", "CLWN") {
        cryptoPunksAssets = CryptoPunksAssets(0x2A256814597B4e3BE62ac0e599Bee9D7bED8C3cf);
        cryptoPunksData = CryptoPunksData(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2);
        cryptoPunksMarket = CryptoPunksMarket(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
        shouldVerifyCryptoPunkOwnership = true;
    }

//   ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗     ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
//  ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
//  ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
//  ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
//  ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
//   ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    function sealContract() external onlyOwner unsealed {
        contractSealed = true;
    }

    function openPublicSale(bool publicSaleOpened, uint256 basePriceInWei) external onlyOwner unsealed {
        shouldVerifyCryptoPunkOwnership = !publicSaleOpened;
        BASE_PRICE_IN_WEI = basePriceInWei;
    }

    function destroy() external onlyOwner unsealed {
        selfdestruct(payable(owner()));
    }
    
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance); 
    }

//  ██████╗ ███████╗ █████╗ ██████╗     ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
//  ██╔══██╗██╔════╝██╔══██╗██╔══██╗    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
//  ██████╔╝█████╗  ███████║██║  ██║    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
//  ██╔══██╗██╔══╝  ██╔══██║██║  ██║    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
//  ██║  ██║███████╗██║  ██║██████╔╝    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
//  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝     ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    function tokenURI(uint256 index) public view override returns (string memory)
    {
        require(_exists(index));
        
        uint16 punkIndex = uint16(index);
        bytes memory punkAssets = getPunkAssets(uint16(punkIndex));

        string memory json = base64Encode(abi.encodePacked(
            '{"name": "Clown Punk #',
            Strings.toString(index), 
            '", "description": "The clowns are in town! CryptoPunk owners can mint a randomly generated clown version of their punk for free. During the public sale, anyone can mint clowns for unclaimed punks, but half the proceeds are transferred to the CryptoPunk owners. 10% of profits donated to GiveDirectly.org (in contract). All metadata and images are fully generated and stored on-chain. Inspired by LarvaLabs (not affiliated).", "image": "data:image/svg+xml;base64,', 
            base64Encode(bytes(punkAssetsImageSvg(punkAssets))), 
            '", "attributes": [',
            metadataAttributes(punkAssets, punkIndex),
            ']}'));

        return string(abi.encodePacked('data:application/json;base64,', json));
    }
    
    function isPublicSaleOpen() external view returns (bool) {
        return !shouldVerifyCryptoPunkOwnership;
    }

    function isClownMintedForPunkIndex(uint16 punkIndex) public view returns (bool) {
        require(punkIndex < MAX_COUNT, "Invalid punk ID");
        uint16 clownIndex = punksToClowns[punkIndex];
        return (clownIndex != 0) || (punkIndex == clownsToPunks[0]);
    }
    
    function priceInWeiToMintClownForPunkIndex(uint16 punkIndex) external view returns (uint256) {
        require(punkIndex < MAX_COUNT, "Invalid punk ID");
        require(!isClownMintedForPunkIndex(punkIndex), "Already minted a clown from this punk");
        return shouldVerifyCryptoPunkOwnership ? 0 :
            priceInWeiToMintClownForPunkAssets(parseAssets(cryptoPunksData.punkAttributes(punkIndex)));
    }
    
    function tokenByPunkIndex(uint16 punkIndex) external view returns (uint16) {
        require(isClownMintedForPunkIndex(punkIndex), "No clown minted for this punk");
        return punksToClowns[punkIndex];
    }

    function attributesByIndex(uint16 index) external view returns (string memory text) {
        require(_exists(index));
        bytes memory punkAssets = getPunkAssets(index);
        for (uint8 j = 0; j < 8; j++) {
            uint8 asset = uint8(punkAssets[j]);
            if (asset > 0) {
                if (j > 0) {
                    text = string(abi.encodePacked(text, ", ", getAssetName(asset)));
                } else {
                    text = getAssetName(asset);
                }
            } else {
                break;
            }
        }
        text = string(abi.encodePacked(text, ", CryptoPunk #", Strings.toString(clownsToPunks[index])));
    }

    function imageByIndex(uint16 index) external view returns (string memory svg) {
        require(_exists(index));
        svg = punkAssetsImageSvg(getPunkAssets(index));
    }

//  ██╗    ██╗██████╗ ██╗████████╗███████╗    ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
//  ██║    ██║██╔══██╗██║╚══██╔══╝██╔════╝    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
//  ██║ █╗ ██║██████╔╝██║   ██║   █████╗      █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
//  ██║███╗██║██╔══██╗██║   ██║   ██╔══╝      ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
//  ╚███╔███╔╝██║  ██║██║   ██║   ███████╗    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
//   ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    address private constant giveDirectlyAddress = 0xc7464dbcA260A8faF033460622B23467Df5AEA42;
    
    function mintClownFromPunk(uint16 punkIndex) external payable {
        uint16 clownIndex = uint16(totalSupply());
        require(clownIndex < MAX_COUNT, "Total cap reached");
        require(punkIndex < MAX_COUNT, "Invalid punk ID");
        require(!isClownMintedForPunkIndex(punkIndex), "Already minted a clown from this punk");

        address punkOwnerAddress = cryptoPunksMarket.punkIndexToAddress(punkIndex);
        bytes memory punkAssets = parseAssets(cryptoPunksData.punkAttributes(punkIndex));

        if (punkOwnerAddress != msg.sender) {
            require(!shouldVerifyCryptoPunkOwnership, "Minting open to CryptoPunk owners only");
            uint256 mintPrice = priceInWeiToMintClownForPunkAssets(punkAssets);
            require(mintPrice <= msg.value, "Insufficient Ether sent");
            
            uint256 punkOwnerFee = mintPrice / 2;
            payable(punkOwnerAddress).transfer(punkOwnerFee);

            uint256 charityDonation = (mintPrice - punkOwnerFee) / 10;
            payable(giveDirectlyAddress).transfer(charityDonation);
        }

        clowns[clownIndex] = punkToClownAssets(punkAssets);
        clownsToPunks[clownIndex] = punkIndex;
        punksToClowns[punkIndex] = clownIndex;

        _mint(msg.sender, clownIndex);
    }

//  ██╗  ██╗███████╗██╗     ██████╗ ███████╗██████╗     ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
//  ██║  ██║██╔════╝██║     ██╔══██╗██╔════╝██╔══██╗    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
//  ███████║█████╗  ██║     ██████╔╝█████╗  ██████╔╝    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
//  ██╔══██║██╔══╝  ██║     ██╔═══╝ ██╔══╝  ██╔══██╗    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
//  ██║  ██║███████╗███████╗██║     ███████╗██║  ██║    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
//  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    function priceInWeiToMintClownForPunkAssets(bytes memory punkAssets) internal view returns (uint256) {
        uint8 kind = uint8(punkAssets[0]);
        if (kind < 9) {
            return BASE_PRICE_IN_WEI;
        } else if (kind == 9) {
            return (BASE_PRICE_IN_WEI * 5) / 2;
        } else if (kind == 10) {
            return BASE_PRICE_IN_WEI * 5;
        } else {
            return BASE_PRICE_IN_WEI * 10;
        }
    }

    function punkToClownAssets(bytes memory punkAssets) internal returns (bytes memory clownAssets) {
        uint8[10] memory punkTraits;
        for (uint8 j = 0; j < 8; ++j) {
            uint8 asset = uint8(punkAssets[j]);
            if (asset == 0) {
                break;
            }
            punkTraits[getAssetType(asset)] = asset;
        }
        
        uint8 kind = punkTraits[uint8(Type.Kind)];
        bool isMale = (kind < 5) || (kind >= 9);
        
        uint8 assetIndex = 0;
        clownAssets = new bytes(8);

        for (uint8 j = 0; j < 10 && assetIndex < 8; ++j) {
            uint8 asset = punkTraits[j];
            if ((j == uint8(Type.Hair)) && (asset != 14) && (asset != 104)) {
                if ((asset == 50) || (asset == 81)) {
                    clownAssets[assetIndex++] = bytes1(isMale ? 142 : 143); // red
                } else if (asset == 28) {
                    clownAssets[assetIndex++] = bytes1(uint8(144)); // purple
                } else if (asset == 121) {
                    clownAssets[assetIndex++] = bytes1(uint8(145)); // pink
                } else if (nextPseudoRandom(3) == 0) {
                    clownAssets[assetIndex++] = bytes1(isMale ? 140 : 141); // blue
                } else if (nextPseudoRandom(3) == 0) {
                    clownAssets[assetIndex++] = bytes1(isMale ? 14 : 104); // green
                } else if (nextPseudoRandom(2) == 0) {
                    clownAssets[assetIndex++] = bytes1(isMale ? 142 : 143); // red
                } else {
                    clownAssets[assetIndex++] = bytes1(isMale ? 144 : 145); // purple/pink
                }
            } else if ((j == uint8(Type.Eyes)) && (asset != 39) && (asset != 114) && (asset != 73) && (asset != 94)) {
                if (asset == 78) {
                    clownAssets[assetIndex++] = bytes1(uint8(94)); // blue
                } else if (asset == 97) {
                    clownAssets[assetIndex++] = bytes1(uint8(139)); // purple
                } else if (asset == 126) {
                    clownAssets[assetIndex++] = bytes1(uint8(114)); // green
                } else if (asset == 0) {
                    if (nextPseudoRandom(2) == 0) {
                        clownAssets[assetIndex++] = bytes1(isMale ? 138 : 139); // purple
                    } else if (nextPseudoRandom(2) == 0) {
                        clownAssets[assetIndex++] = bytes1(isMale ? 39 : 114); // green
                    } else {
                        clownAssets[assetIndex++] = bytes1(isMale ? 73 : 94); // blue
                    }
                } else {
                    clownAssets[assetIndex++] = bytes1(asset);
                }
            } else if ((j == uint8(Type.Nose)) && (asset != 18) && (asset != 109) && (kind < 10)) {
                if (nextPseudoRandom(2) == 0) {
                    clownAssets[assetIndex++] = bytes1(isMale ? 18 : 109); // red
                } else if (nextPseudoRandom(3) == 0) {
                    clownAssets[assetIndex++] = bytes1(isMale ? 134 : 135); // green
                } else {
                    clownAssets[assetIndex++] = bytes1(isMale ? 136 : 137); // blue
                }
            } else if (asset != 0) {
                clownAssets[assetIndex++] = bytes1(asset);
            }
        }
    }
    
    function parseAssets(string memory attributes) internal view returns (bytes memory punkAssets) {
        punkAssets = new bytes(8);
        bytes memory stringAsBytes = bytes(attributes);
        bytes memory buffer = new bytes(stringAsBytes.length);

        uint index = 0;
        uint j = 0;
        bool isMale;
        for (uint i = 0; i < stringAsBytes.length; i++) {
            if (i == 0) {
                isMale = (stringAsBytes[i] != "F");
            }
            if (stringAsBytes[i] != ",") {
                buffer[j++] = stringAsBytes[i];
            } else {
                punkAssets[index++] = bytes1(getAssetIndex(bufferToString(buffer, j), isMale));
                i++; // skip space
                j = 0;
            }
        }
        if (j > 0) {
            punkAssets[index++] = bytes1(getAssetIndex(bufferToString(buffer, j), isMale));
        }
    }

    function getPunkAssets(uint16 index) internal view returns (bytes memory punkAssets) {
        require(_exists(index));
        punkAssets = new bytes(8);
        for (uint8 j = 0; j < 8; j++) {
            punkAssets[j] = clowns[index][j];
        }
    }

    function appendAttribute(string memory prefix, string memory key, string memory value, bool asString, bool asNumber, bool append) internal pure returns (string memory text) {
        string memory quote = asString ? '"' : '';
        string memory displayType = asNumber ? '"display_type": "number", ' : '';
        string memory attribute = 
            string(abi.encodePacked('{ ', displayType, '"trait_type": "', key, '", "value": ', quote, value, quote, ' }'));
        if (append) {
            text = string(abi.encodePacked(prefix, ', ', attribute));
        } else {
            text = attribute;
        }
    }

    function metadataAttributes(bytes memory punkAssets, uint16 index) internal view returns (string memory text) {
        uint8 accessoryCount = 0;
        for (uint8 j = 0; j < 8; j++) {
            uint8 asset = uint8(punkAssets[j]);
            if (asset > 0) {
                if (j > 0) {
                    ++accessoryCount;
                    text = appendAttribute(text, "Accessory", getAssetName(asset), true, false, true);
                } else {
                    text = appendAttribute(text, "Type", getAssetName(asset), true, false, false);
                }
            } else {
                break;
            }
        }
        text = appendAttribute(text, "# Traits", Strings.toString(accessoryCount), false, false, true);
        text = appendAttribute(text, "CryptoPunk #", Strings.toString(clownsToPunks[index]), false, true, true);
    }
    
    function punkAssetsImage(bytes memory punkAssets) internal view returns (bytes memory) {
        bytes memory pixels = new bytes(2304);
        for (uint8 j = 0; j < 8; j++) {
            uint8 asset = uint8(punkAssets[j]);
            if (asset > 0) {
                bytes memory a = getAsset(asset);
                uint n = a.length / 3;
                for (uint i = 0; i < n; i++) {
                    uint[4] memory v = [
                        uint(uint8(a[i * 3]) & 0xF0) >> 4,
                        uint(uint8(a[i * 3]) & 0xF),
                        uint(uint8(a[i * 3 + 2]) & 0xF0) >> 4,
                        uint(uint8(a[i * 3 + 2]) & 0xF)
                    ];
                    for (uint dx = 0; dx < 2; dx++) {
                        for (uint dy = 0; dy < 2; dy++) {
                            uint p = ((2 * v[1] + dy) * 24 + (2 * v[0] + dx)) * 4;
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c = composite(a[i * 3 + 1], pixels[p], pixels[p + 1], pixels[p + 2], pixels[p + 3]);
                                pixels[p] = c[0];
                                pixels[p+1] = c[1];
                                pixels[p+2] = c[2];
                                pixels[p+3] = c[3];
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                pixels[p] = 0;
                                pixels[p+1] = 0;
                                pixels[p+2] = 0;
                                pixels[p+3] = 0xFF;
                            }
                        }
                    }
                }
            }
        }
        return pixels;
    }
    
    string private constant SVG_HEADER = '<svg id="crisp" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMax meet" viewBox="0 0 360 360">';
    string private constant SVG_FOOTER = '<style>rect{width:15px;height:15px;} #crisp{shape-rendering: crispEdges;}</style></svg>';

    function punkAssetsImageSvg(bytes memory punkAssets) internal view returns (string memory svg) {
        bytes memory pixels = punkAssetsImage(punkAssets);
        svg = string(abi.encodePacked(SVG_HEADER));
        for (uint y = 0; y < 24; y++) {
            for (uint x = 0; x < 24; x++) {
                uint p = (y * 24 + x) * 4;
                if (uint8(pixels[p + 3]) > 0) {
                    bytes4 color = bytes4(
                        (uint32(uint8(pixels[p])) << 24) |
                        (uint32(uint8(pixels[p+1])) << 16) |
                        (uint32(uint8(pixels[p+2])) << 8) |
                        (uint32(uint8(pixels[p+3]))));
                    svg = string(abi.encodePacked(svg, rectSvg(15 * x, 15 * y, color)));
                }
            }
        }
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    function composite(bytes1 index, bytes1 yr, bytes1 yg, bytes1 yb, bytes1 ya) internal view returns (bytes4) {
        return cryptoPunksAssets.composite(index, yr, yg, yb, ya);
    }
    
    function getAsset(uint8 index) internal view returns (bytes memory) {
        return cryptoPunksAssets.getAsset(index);
    }
    
    function getAssetName(uint8 index) internal view returns (string memory) {
        return cryptoPunksAssets.getAssetName(index);
    }
    
    function getAssetType(uint8 index) internal view returns (uint8) {
        return cryptoPunksAssets.getAssetType(index);
    }
    
    function getAssetIndex(string memory text, bool isMale) internal view returns (uint8) {
        return cryptoPunksAssets.getAssetIndex(text, isMale);
    }

    function getMappedAsset(uint8 index, bool toMale) internal view returns (uint8) {
        return cryptoPunksAssets.getMappedAsset(index, toMale);
    }

    function nextPseudoRandom(uint256 max) internal returns (uint) {
        SEED = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, SEED)));
        return SEED % max;
    }
    
    bytes16 private constant HEX_SYMBOLS = "0123456789ABCDEF";

    function rectSvg(uint x, uint y, bytes4 color) internal pure returns (string memory) {
        bytes memory opaqueBuffer = new bytes(6);
        bytes memory buffer = new bytes(8);
        bool isOpaque = false;
        for (uint i = 0; i < 4; i++) {
            uint8 value = uint8(color[i]);
            buffer[i * 2 + 1] = HEX_SYMBOLS[value & 0xf];
            buffer[i * 2] = HEX_SYMBOLS[(value >> 4) & 0xf];
            if (i < 3) {
                opaqueBuffer[i * 2] = buffer[i * 2];
                opaqueBuffer[i * 2 + 1] = buffer[i * 2 + 1];
            } else if (value == 255) {
                isOpaque = true;
            } else if (value == 0) {
                return '';
            }
        }
        return string(abi.encodePacked(
            '<rect x="', Strings.toString(x), '" y="', Strings.toString(y),
            '" fill="#', isOpaque ? string(opaqueBuffer) : string(buffer), '"/>'));
    }
    
    function bufferToString(bytes memory buffer, uint length) internal pure returns (string memory text) {
        bytes memory stringBuffer = new bytes(length);
        for (uint i = 0; i < length; ++i) {
            stringBuffer[i] = buffer[i];
        }
        text = string(stringBuffer);
    }
    
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // [MIT License]
    // @author Brecht Devos <brecht@loopring.org>
    function base64Encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
