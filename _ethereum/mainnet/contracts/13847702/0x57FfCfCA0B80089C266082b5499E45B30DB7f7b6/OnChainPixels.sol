// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract OnChainPixels is ERC721Enumerable, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using ECDSA for bytes32;
	using Counters for Counters.Counter;
	using Strings for uint256;

    uint256 public constant MAX_TOKENS = 10000;
	uint256 public constant RESERVE_TOKENS = 100;
	uint256 public constant MAX_TOKENS_PER_TRAN = 10;
	uint256 public constant MAX_TOKEN_WHITELIST_CAP = 3;

	bool public whitelistMintActive = false;
	bool public publicMintActive = false;

	mapping(address => uint256) private whitelistAddressMintCount;

    struct Image {
        string name;
        string description;
        uint256[32] data;
    }

	mapping(uint256 => Image) images;
    
    Counters.Counter public tokenSupply;
    Counters.Counter public reserveSupply;

	constructor() ERC721("OnChainPixels", "OCP") {}

    /********************
    * tokenURI override *
    ********************/

    // Override function for tokenURI checking for existence and calling private _tokenURI
	function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

		return _tokenURI(_tokenId);
	}

    // Constants used for creation of tokenURI JSON
	string private constant tokenURIStart = "data:application/json;base64,";
	bytes private constant j1 = '{"name":"';
    bytes private constant nb = "Pixel Art #";
    bytes private constant j2 = '","description":"';
    bytes private constant j3 = '","attributes":[{"trait_type":"Token ID","value":"';
	bytes private constant j4 = '"}],"image":"data:image/svg+xml;base64,';
	bytes private constant j5 = '"}';
    uint256 private constant JSON_BASE_LENGTH = 117;

    // Private tokeURI generator function, takes constants and stiches them together using writeBytes
	function _tokenURI(uint256 _tokenId) private view returns (string memory) {
        // Get reference to image for tokenId
        Image storage image = images[_tokenId];

        // Get tokenId bytes
        bytes memory tokenBytes = bytes(_tokenId.toString());

        // If image.name is empty, use Pixel Art #{tokenId}, else use image.name
        bytes memory nameBytes;
        if(bytes(image.name).length == 0) {
            nameBytes = new bytes(nb.length + tokenBytes.length);
            writeBytes(nameBytes, nb, 0);
            writeBytes(nameBytes, tokenBytes, nb.length);
        }
        else {
            nameBytes = bytes(image.name);
        }
        
        // Description bytes
        bytes memory descBytes = bytes(image.description);

        // Generate SVG string bytes
        bytes memory svg = _generateSVG(image);

        // Create bytes of total length needed
        bytes memory resultBytes = new bytes(JSON_BASE_LENGTH + nameBytes.length + descBytes.length + tokenBytes.length + svg.length);

        // Use an incremental offset and write bytes sections in order
        uint256 offset = 0;
        writeBytes(resultBytes, j1, offset);
        offset += j1.length;

        writeBytes(resultBytes, nameBytes, offset);
        offset += nameBytes.length;

        writeBytes(resultBytes, j2, offset);
        offset += j2.length;
        writeBytes(resultBytes, descBytes, offset);
        offset += descBytes.length;

        writeBytes(resultBytes, j3, offset);
        offset += j3.length;
        writeBytes(resultBytes, tokenBytes, offset);
        offset += tokenBytes.length;
        
        writeBytes(resultBytes, j4, offset);
        offset += j4.length;
        writeBytes(resultBytes, svg, offset);
        offset += svg.length;

        writeBytes(resultBytes, j5, offset);
        
        // Since the length of the base64 encoded JSON is dependent on the length of the SVG base64
        // there is no way of knowing the length up to this point, in this case its alright
        // to use string concatination as its only one pass through the bytes and would be
        // similar performance to use raw bytes regardless
        return string(abi.encodePacked(tokenURIStart, string(b64Encode(resultBytes))));
	}

	/*******
	* Mint *
	*******/

    // Set whitelist mint active boolean
    function setWhitelistMintActive(bool _active) external onlyOwner {
		whitelistMintActive = _active;
	}

    // Set public mint active boolean
	function setPublicMintActive(bool _active) external onlyOwner {
		publicMintActive = _active;
	}

    // Whitelist mint
	function whitelistMint(uint256 _quantity, bytes calldata _whitelistSignature) external nonReentrant {
        // Verify that the signature has been signed by the owner for valid whitelist mint
		require(verifyOwnerSignature(keccak256(abi.encode(address(this), msg.sender)), _whitelistSignature), "Invalid whitelist signature");
        // Verify that whitelist minting is active
		require(whitelistMintActive, "Whitelist minting not active");
        // Verify quantity minted by sender plus requested quantity is <= max allowed tokens per mint
		require(whitelistAddressMintCount[msg.sender].add(_quantity) <= MAX_TOKEN_WHITELIST_CAP, "Whitelist mint cap exceeded");

        // Add quantity to senders amount minted
		whitelistAddressMintCount[msg.sender] += _quantity;

        // Mint
		_safeMintTokens(_quantity);
	}

    // Public mint
	function publicMint(uint256 _quantity) external {
        // Verify public minting is active
		require(publicMintActive, "Minting not active");
		// Verify quantity is <= max per transaction
        require(_quantity <= MAX_TOKENS_PER_TRAN, "Quantity is more than allowed");

        // Mint
		_safeMintTokens(_quantity);
	}

    // Reserve mint
    function reserveMint(uint256 _quantity) external onlyOwner {
        // Verify quantity is at least 1
        require(_quantity > 0, "Quantity must be at least 1");
        // Verify quantity <= max reserve tokens
		require(reserveSupply.current().add(_quantity) <= RESERVE_TOKENS, "Reserves already minted");

        // Iterate over quanity minting each
        for (uint256 i = 0; i < _quantity; i++) {
            // Increment reserve supply
            reserveSupply.increment();
            // Increment token supply
            tokenSupply.increment();

            // Get new tokenId to mint
            uint256 mintIndex = tokenSupply.current();

            // Mint
			_safeMint(_msgSender(), mintIndex);
        }
	}

    // Safe guarded mint
	function _safeMintTokens(uint256 _quantity) internal {
        // Verify quantity is at least 1
		require(_quantity > 0, "Quantity must be at least 1");
        // Verify that quantity requested does not exceed token cap (minus remaining reseves)
        uint256 reservesLeft = RESERVE_TOKENS.sub(reserveSupply.current());
		require(tokenSupply.current().add(reservesLeft).add(_quantity) <= MAX_TOKENS, "Max token cap exceeded");

        // Iterate over quanity minting each
		for (uint256 i = 0; i < _quantity; i++) {
            // Increment total supply
            tokenSupply.increment();

            // Get new tokenId to mint
			uint256 mintIndex = tokenSupply.current();

            // Mint
			_safeMint(_msgSender(), mintIndex);
		}
	}

    // Sync
    function sync(uint16 _tokenId, string calldata name, string calldata description, uint256[32] calldata _imageData) external {
        // Verify sender is owner of tokenId
        require(_msgSender() == ownerOf(_tokenId), "You do not own this token");

        // Limit name and description as unbounded could cause out of gas exceptions and loss of funds
        // Verify name < 32 characters
        require(bytes(name).length <= 32, "Name must be 32 chars max");
        // Verify description < 128 characters
        require(bytes(description).length <= 128, "Description must be 128 chars max");
        
        // Get reference to image for tokenId
        Image storage image = images[_tokenId];

        // Update name
        image.name = name;

        // Update description
        image.description = description;

        // Iterate over each row of pixels, only updateing the row if its changed to save gas
        for(uint256 i = 0; i < _imageData.length; i++) {
            if(image.data[i] != _imageData[i])
                image.data[i] = _imageData[i];
        }
    }
    
    // Constants used for generation of SVG
    bytes private constant svgStart = '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 32 32">';
    bytes private constant svgEnd = "</svg>";
    bytes private constant pStart = '<path stroke-width="1" stroke="';
    bytes private constant pEnd = '" />';
    bytes private constant pdStart = '" d="';
    bytes private constant pM = "M";
    bytes private constant pS = " ";
    bytes private constant pH1 = " h1 ";

    uint256 private constant PIXEL_SEGMENT_BASE_LENGTH = 6;
    uint256 private constant PATH_SEGMENT_BASE_LENGTH = 47;
	uint256 private constant PATH_SEGMENT_BASE_NOEND_LENGTH = 43;

    // Struct to hold byte length and offset of each path in SVG
	struct ColorMeta {
        uint256 byteLength;
        uint256 byteOffset;
    }

    // SVG generation
    function _generateSVG(Image memory image) private pure returns (bytes memory) {
       
        // Create 256 length ColorMeta[] for all posible colors
        ColorMeta[] memory colorCounts = new ColorMeta[](256);
        // Create incremental total byte length of SVG
        uint256 totalByteLength = svgStart.length + svgEnd.length;
        
        // Create reference for current color index
        uint8 colorIndex = 0;

        // Iterate over rows then pixels for each row
        for(uint256 y = 0; y < 32; y++) {
            // Get reference to row that can be bit-shifted to extract the color indexes
			uint256 row = image.data[y];

            // Get the byte length of the y coord for the row
			uint256 yBytes = y > 9 ? 2 : 1;

            // Row iteration
            for(uint256 x = 0; x < 32; x++) {
                // Extract the next 8 bit color index from the row
                colorIndex = uint8(row & 0xFF);

                // Inverse black (0) and white (255) as white pre-sync would be a more usable background
                // for the image. This way on sync not all rows of data would need to be updated saving gas
                // and spreading the cost across multiple syncs int he future.
                if(colorIndex == 0)
                    colorIndex = 255;
                else if(colorIndex == 255)
                    colorIndex = 0;
                
                // If byteLength for this colorIndex == 0, its the first instance of this color in the image
                // so add the base path length for this colorIndex to the total byte length
                if(colorCounts[colorIndex].byteLength == 0) {
                    totalByteLength += PATH_SEGMENT_BASE_LENGTH;
                }

                // Get byte length of x coord
				uint256 xBytes = x > 9 ? 2 : 1;
                // Increment byte length of color for the text in the SVG representing the pixel in the given path
                colorCounts[colorIndex].byteLength += PIXEL_SEGMENT_BASE_LENGTH;
                colorCounts[colorIndex].byteLength += xBytes + yBytes;

                // Also increment the total byte length for the amount of bytes the pixel represents
                totalByteLength += PIXEL_SEGMENT_BASE_LENGTH;
                totalByteLength += xBytes + yBytes;

                // Bit shift the row by 8 bits so the next iteration gets the next pixels color index
                row >>= 8;
            }
        }
        
        // Get reference to SVG bytes of total calculated length
        bytes memory svg = new bytes(totalByteLength);
        // Write SVG start constant at index 0
        writeBytes(svg, svgStart, 0);
        // Write SVG end constant at last bytes 
        writeBytes(svg, svgEnd, svg.length - svgEnd.length);

        // Create starting byte offset
        uint256 totalColorByteOffset = svgStart.length;
        // Iterate for every potential color
        for(uint256 i = 0; i < 256; i++) {
            // If no pixels defined for color, skip
            if(colorCounts[i].byteLength > 0) {

                // Get a reference to the current byte offset 
				uint256 cbOffset = totalColorByteOffset;

                // Set the byteOffset for the color to be the current byte offset plus the length of the path start
                colorCounts[i].byteOffset = cbOffset + PATH_SEGMENT_BASE_NOEND_LENGTH;
                // Increment the current byte offset to be the total length of the path string for this color
                totalColorByteOffset += PATH_SEGMENT_BASE_LENGTH + colorCounts[i].byteLength;
				
                // Write the path start bytes
                writeBytes(svg, pStart, cbOffset);
                // Wrute the hex value bytes of the color (#RRGGBB)
                writeBytes(svg, getColorBytes(i), cbOffset + pStart.length);
                // Write the d= bytes of the path string
                writeBytes(svg, pdStart, cbOffset + pStart.length + 7);
                // Write the </path> end string bytes
                writeBytes(svg, pEnd, totalColorByteOffset - pEnd.length);
            }
        }
        
        // Iterate over evey pixel, writing the bytes for each into the appropriate path
        // in the bytes for the SVG
        for(uint8 y = 0; y < 32; y++) {
            // Get a reference to the row data
			uint256 row = image.data[y];
			
            // Get the string bytes for the y coord
			bytes memory yb = uint8ToBytes(y);

            // Iterate over the row
            for(uint8 x = 0; x < 32; x++) {
                // Get the 8 bit color index for this pixel
                colorIndex = uint8(row & 0xFF);

                // Inverse black (0) and white (255) as white pre-sync would be a more usable background
                // for the image. This way on sync not all rows of data would need to be updated saving gas
                // and spreading the cost across multiple syncs int he future.
                if(colorIndex == 0)
                    colorIndex = 255;
                else if(colorIndex == 255)
                    colorIndex = 0;
                
                // Get the byte offset for this color index
                uint256 offset = colorCounts[colorIndex].byteOffset;
                // Create a local offset for this pixel
                uint256 localOffset = 0;
                
                // Write "M" bytes
                writeBytes(svg, pM, offset);
                
                // Increment local offset
                localOffset += pM.length;
                
                // Get the string bytes for the x coord
				bytes memory xb = uint8ToBytes(x);
				
                // Write the x coord bytes
				writeBytes(svg, xb, offset + localOffset);
                // Increment local offset
                localOffset += xb.length;
                // Write " " bytes
                writeBytes(svg, pS, offset + localOffset);
                // Increment local offset
                localOffset += pS.length;
                // Write the y coord bytes
                writeBytes(svg, yb, offset + localOffset);
                // Increment local offset
                localOffset += yb.length;
                // Write " h1 " bytes
                writeBytes(svg, pH1, offset + localOffset);
                // Increment local offset
                localOffset += pH1.length;
                // Add the local offset to this colors byte offset
                colorCounts[colorIndex].byteOffset += localOffset;
                
                // Bit shift the row for the next iteration
                row >>= 8;
            }
        }
        
        // Return the SVG base64 encoded
        return b64Encode(svg);
    }

    /********
    * Utils *
    ********/

    // Util to generate bytes representing the hex string of a color index (#RRGGBB)
    bytes private constant hexChars = "0123456789abcdef";
    function getColorBytes(uint256 colorIndex) internal pure returns (bytes memory) {
        // Create reference for bytes
        bytes memory str = new bytes(7);
        
        // First byte always "#"
        str[0] = "#";

        // The color index is assumed to be between 0 and 255, thus only the first 8 bits are used
        // r component is first 3 bits, g component is next 3 bits, b component is last 2 bits

        uint8 r = uint8(((colorIndex >> 5) * 255) / 7);
        str[1] = hexChars[r >> 4];
        str[2] = hexChars[r & 0x0f];
	    uint8 g = uint8((((colorIndex & 31) >> 2) * 255) / 7);
        str[3] = hexChars[g >> 4];
        str[4] = hexChars[g & 0x0f];
	    uint8 b = uint8(((colorIndex & 3) * 255) / 3);
        str[5] = hexChars[b >> 4];
        str[6] = hexChars[b & 0x0f];

        return str;
    }

    // Util to get the string bytes representing a number <= 2 characters in length
    // This function assumes a number no greater than 99 would be passed to it, anything higher
    // would result in malformed strings. There is no need to cater to string results that are
    // of length 3 (100 - 255) as this function is only used to stringify 0-31 coords
	function uint8ToBytes(uint8 _i) internal pure returns (bytes memory) {
        if(_i > 9) {
            // If > 9 return 2 bytes
			bytes memory bstr = new bytes(2);
            // Get mod of _i to for trailing num
			uint8 rem = _i % 10;
            // Add 48 to push num into utf-8 numerical values
			bstr[1] = bytes1(48 + rem);
            // Add 48 to (_i - remainder) / 10 for the multiple of 10 component
			bstr[0] = bytes1(48 + ((_i - rem) / 10));
			return bstr;
		}
		else {
            // Single byte
			bytes memory bstr = new bytes(1);
            // Add 48 to push num into utf-8 numerical values
			bstr[0] = bytes1(48 + _i);
			return bstr;
		}
    }

    // Pure assembly function to copy given bytes over from input bytes to ouput bytes at a given offset
    // THIS FUNCTION IS UNSAFE AND EVERY CODE PERMUTATION THAT USES THIS FUNCTION SHOULD HAVE A CODE COVERAGE
    // TEST TO ENSURE THERE IS NO BUGS AT A HIGHER LEVEL CAUSING WRITES TO UNASSIGNED MEMORY LOCATIONS
    function writeBytes(bytes memory to, bytes memory from, uint256 offset) internal pure {
        
        assembly {
            // Get the length of the array to copy from
            let length := mload(from)

            // If length is less than a single word, perform more gas optimal operation
            // by skipping setup for work chunk copying
            switch lt(length, 32) 
            case 0 {
                // Chunk + remainder copy

                // Get the remaining bytes for after copying whole chunks
                let rem := mod(length, 32)

                // Get pointer for the start of the receiving array + byte offset
                let mc := add(add(to, 32), offset)
                // Get the end length pointer for the receiving array minus remainder
                let end := add(mc, sub(length, rem))
                
                // Set a pointer for the data position to start copying from
                let cc := add(from, 32)

                // Loop while receiving pointer is less than the end pointer
                for {} lt(mc, end) {
                    mc := add(mc, 32)
                    cc := add(cc, 32)
                } {
                    mstore(mc, mload(cc))
                }

                // Chunks copied, now need to copy single bytes for the remainder

                // Subtract 31 from the copy pointer as mstore8 will grab the last byte from the specified
                // 32 byte word
                cc := sub(cc, 31)
                // Set end to be the current pointer position of the receiving array after chunking
                // plus the remaining bytes
                end := add(mc, rem)

                // Loop in the same manner as before except only incrementing pointers by 1 byte at a time
                // and use mstore8 instead to only copy that single byte per iteration
                for {
                } lt(mc, end) {
                    mc := add(mc, 1)
                    cc := add(cc, 1)
                } {
                    mstore8(mc, mload(cc))
                }
            }
            case 1 {
                // Get pointer for the start of the receiving array + byte offset
                let mc := add(add(to, 32), offset)
                // Set end to be recieving array start position + length of array to copy
                let end := add(mc, length)
                
                // Loop while receiving pointer is less than end, incrementing by 1 byte at a time
                // and use mstore8 to copy that single byte
                for {
                    // Set the pointer for the array to copy from to be 1 byte from the start
                    // since mstore8 copies the last byte of the word and the first word in memory for a
                    // bytes is its length, simply offset by one to target the first byte in the actual data
                    let cc := add(from, 1)
                } lt(mc, end) {
                    mc := add(mc, 1)
                    cc := add(cc, 1)
                } {
                    mstore8(mc, mload(cc))
                }
            }
        }
    }

    bytes private constant B64TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    // [MIT License]
    // @title Base64
    // @notice Provides a function for encoding some bytes in base64
    // @author Brecht Devos <brecht@loopring.org>
    function b64Encode(bytes memory data) internal pure returns (bytes memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = B64TABLE;

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
        return result;
    }

    // Util to verify the given signature was signed by the owner of the contract
    function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns (bool) {
		return hash.toEthSignedMessageHash().recover(signature) == owner();
	}
}