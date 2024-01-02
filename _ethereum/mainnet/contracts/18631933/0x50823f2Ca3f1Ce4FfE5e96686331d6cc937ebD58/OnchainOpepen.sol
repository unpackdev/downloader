// SPDX-License-Identifier: MIT

/**
 * OnchainOpepens
 *
 * Burn OnchainRocks to get an OnchainOpepen
 *
 * Why? For the culture
 *
 * CC0. No owner, no royalties, no roadmap.
 *
 * Art fully on-chain
 *
 */
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./IERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Base64.sol";
import "./SSTORE2.sol";
import "./console2.sol";
import "./DynamicBuffer.sol";
import "./HelperLib.sol";
import "./OnchainOpepenArt.sol";

struct TraitDTO {
    string name;
    string mimetype;
    uint256 occurrence;
    bytes data;
    bool hide;
    bool useExistingData;
    uint256 existingDataIndex;
}

struct Trait {
    string name;
    string mimetype;
    uint256 occurrence;
    address dataPointer;
    bool hide;
}

struct Layer {
    string name;
    uint256 primeNumber;
    uint256 numberOfTraits;
}

error InvalidInput();
error NotAvailable();

interface OnchainRocks {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenIdToHash(uint256 tokenId) external returns (string memory);
    function setApprovalForAll(address operator, bool approved) external;
    function balanceOf(address owner) external view returns (uint256);
    function hashToMetadata(string memory _hash) external view returns (string memory);
    function hashToSVG(string memory _hash) external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract OnchainOpepen is ERC721ABurnable {
    using HelperLib for string;
    using DynamicBuffer for bytes;

    mapping(uint256 => Layer) private layers;
    mapping(uint256 => mapping(uint256 => Trait)) private traits;
    mapping(uint256 => string) private hashOverride;

    OnchainRocks rocks;

    uint256 private numberOfLayers;

    uint256 public maxSupply;

    constructor(OnchainRocks _rocks) ERC721A("OnchainOpepen", "ONCHAINOPEPEN") {
        maxSupply = 250;
        rocks = _rocks;
        addArt();
    }

    function addArt() public {
        // Background
        {
            TraitDTO[] memory _traits = new TraitDTO[](1);
            _traits[0] = TraitDTO("Bg", "image/png", 250, OnchainOpepenArt.bg, false, false, 0);
            addLayer(0, "Background", 263743197985470588204349265269345001644610514897601719492623, _traits, 2);
        }

        // Images
        {
            TraitDTO[] memory _traits = new TraitDTO[](11);

            _traits[0] = TraitDTO("Rock", "image/png", 250, OnchainOpepenArt.Rock, false, false, 0);
            _traits[1] = TraitDTO("Brown", "image/png", 250, OnchainOpepenArt.Brown, false, false, 0);
            _traits[2] = TraitDTO("Bleu", "image/png", 250, OnchainOpepenArt.Bleu, false, false, 0);
            _traits[3] = TraitDTO("Rouge", "image/png", 250, OnchainOpepenArt.Rouge, false, false, 0);
            _traits[4] = TraitDTO("Orange", "image/png", 250, OnchainOpepenArt.Orange, false, false, 0);
            _traits[5] = TraitDTO("Navy", "image/png", 250, OnchainOpepenArt.Navy, false, false, 0);
            _traits[6] = TraitDTO("Gold", "image/png", 250, OnchainOpepenArt.Gold, false, false, 0);
            _traits[7] = TraitDTO("Hell", "image/png", 250, OnchainOpepenArt.Hell, false, false, 0);
            _traits[8] = TraitDTO("Zombie", "image/png", 250, OnchainOpepenArt.Zombie, false, false, 0);
            _traits[9] = TraitDTO("Rip", "image/png", 250, OnchainOpepenArt.Rip, false, false, 0);
            _traits[10] = TraitDTO("Squi", "image/png", 250, OnchainOpepenArt.Squi, false, false, 0);

            addLayer(1, "Type", 773144458924271516429415765228637679419660582975860746246683, _traits, 2);
        }
    }

    function tokenIdToHash(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) {
            revert NotAvailable();
        }
        return hashOverride[tokenId];
    }

    function mint(uint256 tokenId1, uint256 tokenId2) external {
        rocks.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), tokenId1);
        rocks.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), tokenId2);
        _mint(msg.sender, 1);
        hashOverride[_nextTokenId() - 1] = rocks.tokenIdToHash(tokenId1);
    }

    // function mint__(string memory hash) public {
    //     require(_nextTokenId() < 11, "Maximum limit reached");
    //     _mint(msg.sender, 1);
    //     hashOverride[_nextTokenId() - 1] = hash;
    // }

    function hashToSVG(string memory _hash) public view returns (string memory) {
        uint256 thisTraitIndex;

        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        svgBytes.appendSafe(
            '<svg width="1200" height="1200" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-image:url('
        );

        for (uint256 i = 0; i < numberOfLayers - 1;) {
            thisTraitIndex = _hash.subStr((i * 3), (i * 3) + 3).parseInt();
            svgBytes.appendSafe(
                abi.encodePacked(
                    "data:",
                    traits[i][thisTraitIndex].mimetype,
                    ";base64,",
                    Base64.encode(SSTORE2.read(traits[i][thisTraitIndex].dataPointer)),
                    "),url("
                )
            );
            unchecked {
                ++i;
            }
        }

        thisTraitIndex = _hash.subStr((numberOfLayers * 3) - 3, numberOfLayers * 3).parseInt();

        svgBytes.appendSafe(
            abi.encodePacked(
                "data:",
                traits[numberOfLayers - 1][thisTraitIndex].mimetype,
                ";base64,",
                Base64.encode(SSTORE2.read(traits[numberOfLayers - 1][thisTraitIndex].dataPointer)),
                ');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"></svg>'
            )
        );

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svgBytes)));
    }

    function hashToMetadata(string memory _hash) public view returns (string memory) {
        bytes memory metadataBytes = DynamicBuffer.allocate(1024 * 128);
        metadataBytes.appendSafe("[");
        bool afterFirstTrait;

        for (uint256 i = 0; i < numberOfLayers;) {
            uint256 thisTraitIndex = _hash.subStr((i * 3), (i * 3) + 3).parseInt();
            if (traits[i][thisTraitIndex].hide == false) {
                if (afterFirstTrait) {
                    metadataBytes.appendSafe(",");
                }
                metadataBytes.appendSafe(
                    abi.encodePacked(
                        '{"trait_type":"', layers[i].name, '","value":"', traits[i][thisTraitIndex].name, '"}'
                    )
                );
                if (afterFirstTrait == false) {
                    afterFirstTrait = true;
                }
            }

            if (i == numberOfLayers - 1) {
                metadataBytes.appendSafe("]");
            }

            unchecked {
                ++i;
            }
        }

        return string(metadataBytes);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidInput();
        }

        bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);

        jsonBytes.appendSafe(
            abi.encodePacked('{"name":"', name(), " #", _toString(tokenId), '","description":"OnchainOpepen",')
        );

        string memory tokenHash = tokenIdToHash(tokenId);

        string memory svgCode = "";

        string memory svgString = hashToSVG(tokenHash);
        svgCode = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '<svg width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                        svgString,
                        '"></image></svg>'
                    )
                )
            )
        );

        jsonBytes.appendSafe(abi.encodePacked('"image_data":"', svgCode, '",'));

        jsonBytes.appendSafe(abi.encodePacked('"attributes":', hashToMetadata(tokenHash), "}"));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(jsonBytes)));
    }

    function addLayer(
        uint256 index,
        string memory name,
        uint256 primeNumber,
        TraitDTO[] memory _traits, // change this from calldata to memory
        uint256 _numberOfLayers
    ) internal {
        layers[index] = Layer(name, primeNumber, _traits.length);
        numberOfLayers = _numberOfLayers;
        for (uint256 i = 0; i < _traits.length;) {
            address dataPointer;
            if (_traits[i].useExistingData) {
                dataPointer = traits[index][_traits[i].existingDataIndex].dataPointer;
            } else {
                dataPointer = SSTORE2.write(_traits[i].data);
            }
            traits[index][i] =
                Trait(_traits[i].name, _traits[i].mimetype, _traits[i].occurrence, dataPointer, _traits[i].hide);
            unchecked {
                ++i;
            }
        }
        return;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId) public override {
        _burn(tokenId);
    }

    function burn(uint256 tokenId, bool approvalCheck) public {
        _burn(tokenId, approvalCheck);
    }
}
