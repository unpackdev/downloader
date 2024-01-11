// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./BiTSNFTUtils.sol";

/// @title BiTS Bank - Mint and Redeem BiTS
/// @author dydxcrypt@protonmail.com
contract BiTSNFTURI is Ownable {
    ContractMeta private _contractMeta;
   
    constructor (string memory name_, string memory description_, string memory depositSymbol_, string memory mintSymbol_) {
        _contractMeta = ContractMeta(name_,description_,depositSymbol_,mintSymbol_);
    }


    function buildImage(TokenMeta memory _tokenMeta, SVGMeta memory _svgMeta, DepositUnits _depositUnit) private view returns (string memory)  {
        Seed memory _seed = generateSeed(_tokenMeta.tokenId, uint(_depositUnit) );
        bytes memory _imgPrefix = generateImagePrefix(_seed);
        bytes memory _circlePrefix = abi.encodePacked(
            CIRCLE_PREFIX,
            _svgMeta.strokeHue,
            '; fill: ',
            _svgMeta.backgroundHue,
            CIRCLE_SUFFIX
        );
        bytes memory _textPrefix = abi.encodePacked('<g style="fill: #eeb32b; font-family: Arial, sans-serif; font-size: 10px; font-weight: 700; text-anchor: middle; filter: url(#convolve);">',
                        META_TEXT_PREFIX,
                        _svgMeta.depositUnitInString);
        bytes memory _textSuffix = abi.encodePacked(' ',
                        _contractMeta.depositSymbol,
                        ' ',
                        Strings.toString(block.timestamp),
                        ' ',
                        Strings.toString(_tokenMeta.tokenId),
                        '</textPath></text>',
                        USER_TEXT_PREFIX,
                        _tokenMeta.userText,
                        '</textPath></text></g>',
                        UNIT_TEXT_PREFIX,
                        _svgMeta.depositUnitName,
                        '</text>',
                        _svgMeta.svgLogo,
                        '</svg>');
        return
            Base64.encode(
                bytes.concat(SVG_PREFIX, _imgPrefix, _circlePrefix, _textPrefix, _textSuffix)
            );
    }

    function createTokenURI(TokenMeta memory _tokenMeta, SVGMeta memory _svgMeta, DepositUnits _depositUnit) public view onlyOwner returns(string memory) {
        bytes memory _metaPre = abi.encodePacked( '{"name":"',
                                _contractMeta.mintName,
                                '", "description":"',
                                _contractMeta.mintDescription,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                buildImage(_tokenMeta, _svgMeta, _depositUnit));
        bytes memory _metaAttr = abi.encodePacked('", "attributes": ',
                                "[",
                                '{"trait_type": "Mint Block",',
                                '"value":"',
                                Strings.toString(block.timestamp),
                                '"},',
                                '{"trait_type": "Mint Deposit",',
                                '"value":"',
                                Strings.toString(_tokenMeta.depositAmount),
                                '"},',
                                '{"trait_type": "Message",',
                                '"value":"',
                                _tokenMeta.userText,
                                '"}',
                                "]",
                                "}");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes.concat(_metaPre, _metaAttr)
                    )
                )
            );
    }


    

    function generateImagePrefix(Seed memory _seed) internal pure returns(bytes memory) {
        uint48 strokePatternHue2 = (_seed.strokePatternHue + 120) < 360 ? _seed.strokePatternHue + 120 : (_seed.strokePatternHue + 120) - 360;
        uint48 strokePatternHue3 = (strokePatternHue2 + 120) < 360 ? strokePatternHue2 + 120 : (strokePatternHue2 + 120) - 360;
        bytes memory _imagePrefix = abi.encodePacked(
            "<pattern id='a' patternUnits='userSpaceOnUse' width='40' height='60' patternTransform='scale(",
            Strings.toString(_seed.scale),
            ") rotate(",
            Strings.toString(_seed.rotate),
            ")'><g fill='none' stroke-width='",
            Strings.toString(_seed.strokeWidth),
            "'><path d='M-4.798 13.573C-3.149 12.533-1.446 11.306 0 10c2.812-2.758 6.18-4.974 10-5 4.183.336 7.193 2.456 10 5 2.86 2.687 6.216 4.952 10 5 4.185-.315 7.35-2.48 10-5 1.452-1.386 3.107-3.085 4.793-4.176'   stroke='hsla(",
            Strings.toString(_seed.strokePatternHue),
            ",50%,50%,1)'/><path d='M-4.798 33.573C-3.149 32.533-1.446 31.306 0 30c2.812-2.758 6.18-4.974 10-5 4.183.336 7.193 2.456 10 5 2.86 2.687 6.216 4.952 10 5 4.185-.315 7.35-2.48 10-5 1.452-1.386 3.107-3.085 4.793-4.176'  stroke='hsla(",
            Strings.toString(strokePatternHue2),
            ",35%,45%,1)' /><path d='M-4.798 53.573C-3.149 52.533-1.446 51.306 0 50c2.812-2.758 6.18-4.974 10-5 4.183.336 7.193 2.456 10 5 2.86 2.687 6.216 4.952 10 5 4.185-.315 7.35-2.48 10-5 1.452-1.386 3.107-3.085 4.793-4.176' stroke='hsla(",
            Strings.toString(strokePatternHue3),
            ",65%,55%,1)'/></g></pattern></defs>"
        );
        return _imagePrefix;
    }


    function generateSeed(uint256 tokenId, uint256 depositUnit) internal view returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, depositUnit))
        );

        uint48 scaleMax = 9;
        uint48 rotateMax = 360;
        uint48 strokeWidthMax = 9;
        uint48 hueMax = 360;
        uint48 saturationMax = 100;
        

        return Seed({
            scale: uint48(
                uint48(pseudorandomness >> 48) % scaleMax + 2
            ),
            rotate: uint48(
                uint48(pseudorandomness >> 96) % rotateMax
            ),
            strokeWidth: uint48(
                uint48(pseudorandomness >> 144) % strokeWidthMax + 2
            ),
            strokePatternHue: uint48(
                uint48(pseudorandomness >> 192) % hueMax
            ),         
            strokeSaturation: uint48(
                uint48(pseudorandomness >> 184) % saturationMax
            ),           
            strokeLightness: uint48(
                uint48(pseudorandomness >> 176) % saturationMax
            )
        });
    }

}
