// SPDX-License-Identifier: MIT AND Apache License 2.0

/*
the hyaliko space factory
by collin mckinney
heavily inspired by the blitmap contract
*/

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <arachnid@notdot.net>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }
    
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }
}

contract HyalikoSpaceFactory is ERC721Enumerable, ReentrancyGuard, Ownable {
    using strings for string;
    using strings for strings.slice;

    ERC721 private hyaliko;

    string private constant terrainColors = "#CCCCCC,#7C7C7C,#000000,#00D081,#AC8CFF,#961FFF,#F29800,#FE0302,#980100,#0BCDFE,#4900FF";
    string private constant backgroundColors = "#FFFFFF,#7F7F7F,#000000,#86FFD1,#87E8FF,#E155FF,#FFEA9B,#FF5161,#6577FF";
    string private constant particleColors = "#FFFFFF,#7C7C7C,#000000,#00D081,#961FFF,#0BCDFE,#F29800,#FE0302,#4900FF";

    string private constant terrainNames = "diamond,steel,obsidian,emerald,lavender quartz,amethyst,amber,ruby,garnet,topaz,sapphire";
    string private constant backgroundNames = "void,forged,stranded,aboreal,stratospheric,galactic,enlightened,blistering,submerged";
    string private constant particleShapeNames = "ethereal,fragmented,glitched";
    string private constant particleColorNames = "white,gray,black,green,purple,sky,orange,red,blue";

    struct Variant {
        uint32 hyalikoSpaceNumber;
        uint8 terrainColor;
        uint8 backgroundColor;
        uint8 particleShape;
        uint8 particleColor;
    }

    // There are 60 of these
    uint8[60] _remainingVariants = [50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50];

    event Published();
    event PublishedForSpaceOwners();
    // Used to track ID offset
    uint256 private _numberSpaceOwnerTokens;
    
    mapping(uint256 => Variant) private _tokenVariantIndex;
    mapping(bytes32 => bool) private _variantMinted;
    
    string private _uriPrefix;

    uint32 private constant _totalNumberOfOriginalHyalikoTokens = 565;
    uint8 private constant _totalNumberOfHyalikoSpaces = 60;
    uint8 private constant _maxNumVariants = 50;

    uint16 private numTerrainColors = 11;
    uint16 private numBackgroundColors = 9;
    uint16 private numParticleColors = 9;
    uint16 private numParticleShapes = 3;

    
    bool public published;
    bool public publishedForSpaceOwners;

    constructor(address hyalikoContractAddress) ERC721("hyaliko space factory", "HYSF") Ownable() {
        hyaliko = ERC721(hyalikoContractAddress);

        published = false;
        publishedForSpaceOwners = false;

        setBaseURI("https://api.hyaliko.com/space-factory/tokens/");
    }
    
    function _baseURI() override internal view virtual returns (string memory) {
        return _uriPrefix;
    }

    function setBaseURI(string memory prefix) public onlyOwner {
        _uriPrefix = prefix;
    }
    
    function publish() public onlyOwner {
        published = true;
        emit Published();
    }

    function publishForSpaceOwners() public onlyOwner {
        publishedForSpaceOwners = true;
        emit PublishedForSpaceOwners();
    }
    
    function allowedNumVariants() public pure returns (uint8) {
        return _maxNumVariants;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _mintVariant(uint256 tokenId, uint32 spaceIndex, uint8 terrainColor, uint8 backgroundColor, uint8 particleShape, uint8 particleColor) internal {
        require(spaceIndex < _totalNumberOfHyalikoSpaces, "b:02");
        require(terrainColor < numTerrainColors && backgroundColor < numBackgroundColors && particleShape < numParticleShapes && particleColor < numParticleColors, "b:04");
        // Will fail and revert if original hyaliko space doesn't exist
        uint256 hyalikoSpaceTokenId;
        if (spaceIndex <= 4) {
            hyalikoSpaceTokenId = spaceIndex;
        } else {
            hyalikoSpaceTokenId = 15 + ((spaceIndex - 5) * 10);
        }
        try hyaliko.ownerOf(hyalikoSpaceTokenId) {     
        } catch {
            revert("b:07");
        }
        
        require(_remainingVariants[spaceIndex] > 0, "b:05");
        
        // a given variant can only be minted once
        bytes32 parameterHash = keccak256(abi.encodePacked(spaceIndex, terrainColor, backgroundColor, particleShape, particleColor));
        require(_variantMinted[parameterHash] == false, "b:06");
        
        Variant memory variant;
        variant.hyalikoSpaceNumber = spaceIndex;
        variant.terrainColor = terrainColor;
        variant.backgroundColor = backgroundColor;
        variant.particleShape = particleShape;
        variant.particleColor = particleColor;
        
        _remainingVariants[spaceIndex]--;
        
        _tokenVariantIndex[tokenId] = variant;
        _variantMinted[parameterHash] = true;

        _safeMint(msg.sender, tokenId);
    }

    function mintVariantWithHyalikoSpace(uint256 tokenId, uint32 spaceIndex, uint8 terrainColor, uint8 backgroundColor, uint8 particleShape, uint8 particleColor) public nonReentrant {
        require(publishedForSpaceOwners == true, "b:01");
        require(hyaliko.ownerOf(tokenId) == msg.sender, "b:03");
        _mintVariant(tokenId, spaceIndex, terrainColor, backgroundColor, particleShape, particleColor);
        _numberSpaceOwnerTokens++;
    }
    
    function mintVariant(uint32 spaceIndex, uint8 terrainColor, uint8 backgroundColor, uint8 particleShape, uint8 particleColor) public nonReentrant payable {
        require(published == true, "b:01");
        require(msg.value == 0.1 ether, "b:08");

        uint256 tokenId = (_totalNumberOfOriginalHyalikoTokens) + (totalSupply() - _numberSpaceOwnerTokens);
        _mintVariant(tokenId, spaceIndex, terrainColor, backgroundColor, particleShape, particleColor);
    }
    
    function getHyalikoSpaceOf(uint256 tokenId) public view returns (uint32) {
        return _tokenVariantIndex[tokenId].hyalikoSpaceNumber;
    }

    function getTerrainColorOf(uint256 tokenId) public view returns (string memory) {
        Variant memory variant = _tokenVariantIndex[tokenId];
        string memory color = getItemFromCSV(terrainColors, variant.terrainColor);
        return color;
    }

    function getBackgroundColorOf(uint256 tokenId) public view returns (string memory) {
        Variant memory variant = _tokenVariantIndex[tokenId];
        string memory color = getItemFromCSV(backgroundColors, variant.backgroundColor);
        return color;
    }

    function getParticleSvgOf(uint256 tokenId) public view returns (string memory) {
        Variant memory variant = _tokenVariantIndex[tokenId];
        string memory svg;
        if (variant.particleShape == 0) {
            svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><defs><radialGradient id="gradient"><stop stop-opacity="1" stop-color="', getItemFromCSV(particleColors, variant.particleColor), '" offset="0" /><stop stop-opacity="0" stop-color="', getItemFromCSV(particleColors, variant.particleColor), '" offset="0.9" /></radialGradient></defs><circle cx="32" cy="32" r="32" fill="url(#gradient)"></circle></svg>'));
        } else if (variant.particleShape == 1) {
            svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><polygon points="16,48 32,16 48,48" fill="', getItemFromCSV(particleColors, variant.particleColor), '"></polygon></svg>'));
        } else {
            svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="32" height="32" x="16" y="16" fill="', getItemFromCSV(particleColors, variant.particleColor), '"></rect></svg>'));
        }
        
        return svg;
    }

    function getNameOf(uint256 tokenId) public view returns (string memory) {
        Variant memory variant = _tokenVariantIndex[tokenId];
        return string(abi.encodePacked(getItemFromCSV(terrainNames, variant.terrainColor), " ", getItemFromCSV(backgroundNames, variant.backgroundColor), " (", getItemFromCSV(particleColorNames, variant.particleColor), " ", getItemFromCSV(particleShapeNames, variant.particleShape), ")"));
    }

    function getParametersOf(uint256 tokenId) public view returns (uint32, uint8, uint8, uint8, uint8) {
        Variant memory variant = _tokenVariantIndex[tokenId];
        return (variant.hyalikoSpaceNumber, variant.terrainColor, variant.backgroundColor, variant.particleShape, variant.particleColor);
    }


    function getItemFromCSV(string memory str, uint256 index) internal pure returns (string memory) {
        strings.slice memory strSlice = str.toSlice();
        string memory separatorStr = ",";
        strings.slice memory separator = separatorStr.toSlice();
        strings.slice memory item;
        for (uint256 i = 0; i <= index; i++) {
            item = strSlice.split(separator);
        }
        return item.toString();
    }
}

/*               
errors:         
01: This can only be done after the project has been published.
02: Variants can only be created with valid hyaliko spaces. Range is 0 - 59.
03: You must own the hyaliko space that corresponds to the token ID that you are redeeming if you are minting with a hyaliko space.
04: Variant parameters are limited to a specified preset range (0 - 10 for terrain, 0 - 8 for background, 0 - 2 for particle shape, 0 - 8 for particle color).
05: All 50 variants of this hyaliko space have been minted.
06: A variant with this set of parameters already exists.
07: This hyaliko space is invalid or does not exist yet.
08: Variants cost 0.1 ETH.
*/