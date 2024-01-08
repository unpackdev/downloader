// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./base64.sol";
import "./TheColors.sol";
import "./INFTOwner.sol";

/**
 * @title TheSpirals contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract TheSpirals is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for uint32;
    using Strings for uint8;

    struct SpiralTraits {
        uint8 direction;
        uint8 strokeWidth;
        uint8 spiralSize;
        uint8 stepDuration;
        uint8 duration;
    }

    string public PROVENANCE_HASH = "";

    address constant public THE_COLORS = address(0x9fdb31F8CE3cB8400C7cCb2299492F2A498330a4);

    mapping(uint256 => bool) public hasClaimed;

    constructor() ERC721("The Spirals (thecolors.art)", "SPIRALS") {}

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(hasClaimed[tokenId], "ERC721Metadata: URI query for nonexistent token");

        string memory svgData = generateSVGImage(tokenId);
        string memory image = Base64.encode(bytes(svgData));

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"image":"',
                            'data:image/svg+xml;base64,',
                            image,
                            '",',
                            generateNameDescription(tokenId),
                            generateAttributes(tokenId),
                            '}'
                        )
                    )
                )
            )
        );
    }

    function getTokenMetadata(uint256 tokenId) public view returns (string memory) {
        string memory image = Base64.encode(bytes(generateSVGImage(tokenId)));

        return string(
            abi.encodePacked(
                'data:application/json',
                '{',
                '"image":"',
                'data:image/svg+xml;base64,',
                image,
                '",',
                generateNameDescription(tokenId),
                generateAttributes(tokenId),
                '}'
            )
        );
    }

    function getTokenSVG(uint256 tokenId) public view returns (string memory) {
        return generateSVGImage(tokenId);
    }

    function getBase64TokenSVG(uint256 tokenId) public view returns (string memory) {
        string memory image = Base64.encode(bytes(generateSVGImage(tokenId)));
        return string(
            abi.encodePacked(
                'data:application/json;base64',
                image
            )
        );
    }

    function getColorsOwnedByUser(address user) public view returns (uint256[] memory tokenIds) {
      uint256[] memory tokenIds = new uint256[](4317);

      uint index = 0;
      for (uint i = 0; i < 4317; i++) {
        address tokenOwner = INFTOwner(THE_COLORS).ownerOf(i);
        
        if (user == tokenOwner) {
          tokenIds[index] = i;
          index += 1;
        }
      }

      uint left = 4317 - index;
      for (uint i = 0; i < left; i++) {
        tokenIds[index] = 9999;
        index += 1;
      }

      return tokenIds;
    }

    function getUnmintedSpiralsByUser(address user) public view returns (uint256[] memory tokenIds) {
      uint256[] memory tokenIds = new uint256[](4317);

      uint index = 0;
      for (uint i = 0; i < 4317; i++) {
        address tokenOwner = INFTOwner(THE_COLORS).ownerOf(i);
        
        if (user == tokenOwner && !hasClaimed[i]) {
          tokenIds[index] = i;
          index += 1;
        }
      }

      uint left = 4317 - index;
      for (uint i = 0; i < left; i++) {
        tokenIds[index] = 9999;
        index += 1;
      }

      return tokenIds;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE_HASH = provenanceHash;
    }

    /**
    * Mints The Spirals
    */
    function mintSpiral(uint256 tokenId) public {
        address tokenOwner = INFTOwner(THE_COLORS).ownerOf(tokenId);

        require(!hasClaimed[tokenId], "Color has already claimed their Spiral.");
        require(msg.sender == tokenOwner, "Only token owner can mint their Spiral.");

        uint32 r = TheColors(THE_COLORS).getRed(tokenId);
        uint32 g = TheColors(THE_COLORS).getGreen(tokenId);
        uint32 b = TheColors(THE_COLORS).getBlue(tokenId);

        _safeMint(msg.sender, tokenId);
        generateColorSpectrum(tokenId, r, g, b);

        hasClaimed[tokenId] = true;
    }

    function mintBatch(uint256[] memory tokenIds) public {
      for (uint256 i = 0; i < tokenIds.length; i++) {
        mintSpiral(tokenIds[i]);
      }
    }

    function generateNameDescription(uint256 tokenId) internal view returns (string memory) {
        string memory hexCode = TheColors(THE_COLORS).getHexColor(tokenId);
        return string(
            abi.encodePacked(
                '"external_url":"https://thecolors.art",',
                unicode'"description":"The Spirals are a set of 4,317 iconic designs generated and stored entirely on-chain, given to The Colors holders.',
                '\\nToken id: #',
                tokenId.toString(),
                '",',
                '"name":"The ',
                hexCode,
                ' Spiral",'
            )
        );
    }

    function generateAttributes(uint256 tokenId) internal view returns (string memory) {
        string memory hexCode = TheColors(THE_COLORS).getHexColor(tokenId);
        uint32 r = TheColors(THE_COLORS).getRed(tokenId);
        uint32 g = TheColors(THE_COLORS).getGreen(tokenId);
        uint32 b = TheColors(THE_COLORS).getBlue(tokenId);

        SpiralTraits memory traits = generateTraits(tokenId, r, g, b);

        bytes memory buffer = abi.encodePacked(
                '"attributes":[',
                '{"trait_type":"Background color","value":"',
                hexCode,
                '"},',
                '{"trait_type":"Type","value":"',
                getType(traits.direction),
                '"},',
                '{"trait_type":"Stroke","value":"',
                getStroke(traits.strokeWidth),
                '"},'
        );

        return string(
            abi.encodePacked(
                buffer,
                '{"trait_type":"Size","value":"',
                getSize(traits.spiralSize),
                '"},',
                '{"trait_type":"Speed","value":"',
                getSpeed(traits.stepDuration),
                '"},',
                '{"trait_type":"Duration","value":"',
                traits.duration.toString(),
                's"}',
                ']'
            )
        );
    }

    function getSpeed(uint8 stepDuration) internal view returns (string memory) {
      if (stepDuration == 1) {
        return "Fast";
      } else if (stepDuration == 2) {
        return "Medium";
      } else {
        return "Slow";
      }
    }

    function getSize(uint8 spiralSize) internal view returns (string memory) {
      if (spiralSize == 5) {
        return "Small";
      } else if (spiralSize == 6) {
        return "Kinda Small";
      } else if (spiralSize == 7) {
        return "Small Medium";
      } else if (spiralSize == 8) {
        return "Large Medium";
      } else if (spiralSize == 9) {
        return "Kinda Large";
      } else {
        return "Large";
      }
    }

    function getType(uint8 direction) internal view returns (string memory) {
      if (direction == 2) {
        return "Flat";
      } else if (direction == 3) {
        return "Semi-Flat";
      } else if (direction == 4) {
        return "Semi-Straight";
      } else {
        return "Straight";
      }
    }

    function getStroke(uint8 strokeWidth) internal view returns (string memory) {
      if (strokeWidth < 3) {
        return "Thin";
      } else if (strokeWidth < 5) {
        return "Semi-Thin";
      } else if (strokeWidth < 7) {
        return "Semi-Thick";
      } else {
        return "Thick";
      }
    }

    function generateSVGImage(uint256 tokenId) internal view returns (string memory) {
        string memory hexCode = TheColors(THE_COLORS).getHexColor(tokenId);
        uint32 r = TheColors(THE_COLORS).getRed(tokenId);
        uint32 g = TheColors(THE_COLORS).getGreen(tokenId);
        uint32 b = TheColors(THE_COLORS).getBlue(tokenId);

        SpiralTraits memory traits = generateTraits(tokenId, r, g, b);
        string memory pathD = generatePathD(traits.direction, traits.spiralSize);

        bytes memory svgPartA = generateSVGPartA(tokenId, r, g, b, pathD, traits.strokeWidth, traits.stepDuration);
        bytes memory svgPartB = generateSVGPartB(pathD, traits.strokeWidth, traits.stepDuration, traits.duration);

        return string(
            abi.encodePacked(
              '<svg fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="500" height="500" style="background-color:',
              hexCode,
              '">',
              svgPartA,
              svgPartB,
              '</svg>'
            )
        );
    }

    function generateSVGPartB(string memory pathD, uint8 strokeWidth, uint8 stepDuration, uint8 duration) internal view returns (bytes memory) {
      bytes memory bufferA = abi.encodePacked(
              '<animate id="step5" begin="step4.end+0.5s" attributeType="XML" attributeName="stroke-dasharray" to="3217" dur="',
              stepDuration.toString(),
              's" fill="freeze" />',
              '<animate id="step6" begin="step5.end+0.5s" attributeType="XML" attributeName="stroke-dasharray" to="6434" dur="',
              stepDuration.toString(),
              's" fill="freeze" />',
              '</path>'
              '<path id="spiral" stroke-dasharray="0" stroke-dashoffset="0" stroke="#0000ff" stroke-width="'
        );

        bytes memory bufferB = abi.encodePacked(
              strokeWidth.toString(),
              '" d="',
              pathD,
              '">'
              '<animate id="start" attributeType="XML" attributeName="stroke" begin="0.5s;end.end+0.5s" to="#0000ff" dur="',
              duration.toString(),
              '.5s" fill="freeze" />',
              '<animate attributeType="XML" attributeName="stroke-dashoffset" begin="start.begin" to="6434" dur="',
              duration.toString()
        );

        bytes memory bufferC = abi.encodePacked(
              's" fill="freeze" />',
              '<animate attributeType="XML" attributeName="stroke-dasharray" begin="start.begin" to="6434" dur="',
              duration.toString(),
              's" fill="freeze" />',
              '<animate attributeType="XML" attributeName="stroke-dashoffset" begin="step6.end+1" to="0" dur="0.3s" fill="freeze" />',
              '<animate id="end" attributeType="XML" attributeName="stroke-dasharray" begin="step6.end+1" to="0" dur="0.3s" fill="freeze" />',
              '</path>'
        );

        return abi.encodePacked(bufferA, bufferB, bufferC);
    }

    function generateSVGPartA(uint256 tokenId, uint32 r, uint32 g, uint32 b, string memory pathD, uint8 strokeWidth, uint8 stepDuration)
      internal view
      returns (bytes memory)
    {
        (string memory rHexCode, string memory gHexCode, string memory bHexCode) = generateColorSpectrum(tokenId, r, g, b);

        bytes memory bufferA = abi.encodePacked(
              '<path id="spiral" stroke-dasharray="6434" stroke-dashoffset="6434" stroke="',
              rHexCode,
              '" stroke-width="',
              strokeWidth.toString(),
              '" d="',
              pathD,
              '">',
              '<animate begin="start.begin" attributeType="XML" attributeName="stroke" to="',
              rHexCode,
              '" dur="0.3s" fill="freeze" />'
        );

        bytes memory bufferB = abi.encodePacked(
              '<animate id="step1" begin="start.begin+0.5s" attributeType="XML" attributeName="stroke-dashoffset"  to="0" dur="',
              stepDuration.toString(),
              's" fill="freeze" />'
              '<animate id="step2" begin="step1.end+0.5s" attributeType="XML" attributeName="stroke-dasharray" to="0" dur="',
              stepDuration.toString(),
              's" fill="freeze" />'
              '<animate begin="start.begin+6.5s" attributeType="XML" attributeName="stroke" to="',
              gHexCode,
              '" dur="0.3s" fill="freeze" />'
        );

        bytes memory bufferC = abi.encodePacked(
              '<animate id="step3" begin="step2.end+1s" attributeType="XML" attributeName="stroke-dasharray" to="1608" dur="',
              stepDuration.toString(),
              's" fill="freeze" />',
              '<animate id="step4" begin="step3.end+0.5s" attributeType="XML" attributeName="stroke-dashoffset" to="6434" dur="',
              stepDuration.toString(),
              's" fill="freeze" />',
              '<animate begin="start.begin+13s" attributeType="XML" attributeName="stroke" to="',
              bHexCode,
              '" dur="0.3s" fill="freeze" />'
        );

        return abi.encodePacked(bufferA, bufferB, bufferC);
    }

    function generatePathD(uint8 direction, uint8 spiralSize) internal view returns (string memory) {
        bytes memory pathD = abi.encodePacked("M250,250 a5,");

        for (uint i = 0; i < 38; i++) {
          pathD = abi.encodePacked(
            pathD,
            direction.toString(),
            ' 0 1,1 ',
            i % 2 == 1 ? '-' : '',
            ((i + 2) * spiralSize).toString(),
            ',0 5,'
          );
        }

        return string(
          abi.encodePacked(
            pathD,
            '0'
          )
        );
    }

    function generateTraits(uint256 tokenId, uint32 r, uint32 g, uint32 b) internal view returns (SpiralTraits memory) {
        SpiralTraits memory traits;

        traits.direction = uint8((_rng(tokenId, r + g + b) % 4) + 2);
        traits.strokeWidth = uint8((_rng(tokenId, r) % 8) + 1);
        traits.spiralSize = uint8((_rng(tokenId, g) % 6) + 5);
        traits.stepDuration = uint8((_rng(tokenId, b) % 3) + 1);
        traits.duration = uint8((_rng(tokenId, r + g) % 16) + 21);

        return traits;
    }

    function generateColorSpectrum(uint256 tokenId, uint32 r, uint32 g, uint32 b) internal view returns (string memory, string memory, string memory) {
        return (
          string(
            abi.encodePacked(
              '#',
              uintToHexString(uint256(_rng(tokenId, r) % 16777215))
            )
          ),
          string(
            abi.encodePacked(
              '#',
              uintToHexString(uint256(_rng(tokenId, g) % 16777215))
            )
          ),
          string(
            abi.encodePacked(
              '#',
              uintToHexString(uint256(_rng(tokenId, b) % 16777215))
            )
          )
        );
    }
    
    function uintToHexString(uint256 number) public pure returns(string memory) {
        bytes32 value = bytes32(number);
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(6);
        for (uint i = 0; i < 3; i++) {
            str[i*2] = alphabet[uint(uint8(value[i + 29] >> 4))];
            str[1+i*2] = alphabet[uint(uint8(value[i + 29] & 0x0f))];
        }
        
        return string(str);
    }

    function _rng(uint256 tokenId, uint256 seed) internal view returns(uint256) {
        uint256 _tokenId = tokenId + 1;
        return uint256(keccak256(abi.encodePacked(_tokenId.toString(), seed.toString()))) +
                uint256(_tokenId * seed);
    }
}