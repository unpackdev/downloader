// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *  /$$$$$$$                                      /$$ /$$                                                      
 * | $$__  $$                                    | $$|__/                                                      
 * | $$  \ $$  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$$ /$$ /$$$$$$$   /$$$$$$                                   
 * | $$$$$$$  /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$| $$__  $$ /$$__  $$                                  
 * | $$__  $$| $$  \__/| $$$$$$$$| $$$$$$$$| $$  | $$| $$| $$  \ $$| $$  \ $$                                  
 * | $$  \ $$| $$      | $$_____/| $$_____/| $$  | $$| $$| $$  | $$| $$  | $$                                  
 * | $$$$$$$/| $$      |  $$$$$$$|  $$$$$$$|  $$$$$$$| $$| $$  | $$|  $$$$$$$                                  
 * |_______/ |__/       \_______/ \_______/ \_______/|__/|__/  |__/ \____  $$                                  
 *                                                                  /$$  \ $$                                  
 *                                                                 |  $$$$$$/                                  
 *                                                                  \______/                                   
 *   /$$$$$$                        /$$     /$$  /$$$$$$  /$$                       /$$                        
 *  /$$__  $$                      | $$    |__/ /$$__  $$|__/                      | $$                        
 * | $$  \__/  /$$$$$$   /$$$$$$  /$$$$$$   /$$| $$  \__/ /$$  /$$$$$$$  /$$$$$$  /$$$$$$    /$$$$$$   /$$$$$$$
 * | $$       /$$__  $$ /$$__  $$|_  $$_/  | $$| $$$$    | $$ /$$_____/ |____  $$|_  $$_/   /$$__  $$ /$$_____/
 * | $$      | $$$$$$$$| $$  \__/  | $$    | $$| $$_/    | $$| $$        /$$$$$$$  | $$    | $$$$$$$$|  $$$$$$ 
 * | $$    $$| $$_____/| $$        | $$ /$$| $$| $$      | $$| $$       /$$__  $$  | $$ /$$| $$_____/ \____  $$
 * |  $$$$$$/|  $$$$$$$| $$        |  $$$$/| $$| $$      | $$|  $$$$$$$|  $$$$$$$  |  $$$$/|  $$$$$$$ /$$$$$$$/
 *  \______/  \_______/|__/         \___/  |__/|__/      |__/ \_______/ \_______/   \___/   \_______/|_______/ 
 * 
 *
 * Breeding Certificates allow Holders to breed a Baby Hipster, without owning a
 * Crypto Punk
 *
 * Anyone that owns a Crypto Punk can mint one of these Breeding Certificates.
 * Breeding Certificates encapsulate Punk's DNA (attributes).
 * You can transfer them to anyone who wants your Punk's DNA in their Baby Hipster.
 * Each Breeding certificate can only be used once.
 * All information and image related to these Breeding Certificates is stored on-chain.
 *
 * Inspired by CryptoPunks, CryptoPunksData, Avastars and Loot,
 * but not affiliated with any of them.
 *
 */

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";

/**************************/
/***     Interfaces     ***/
/**************************/

interface ICryptoPunks {
    function punkIndexToAddress(uint256 index) external view returns (address);
}

interface ICryptoPunksData {
    function punkAttributes(uint16 index) external view returns (string memory text);

    function punkImageSvg(uint16 index) external view returns (string memory svg);
}

contract CryptoPunksBreedingCertificates is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    address internal constant CRYPTO_PUNKS_ADDR = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address internal constant WRAPPED_CRYPTO_PUNKS_ADDR = 0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6;
    address internal constant CRYPTO_PUNKS_DATA_ADDR = 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2;

    address internal babyHipstersAddr;

    mapping(uint256 => uint256) internal _certificateIdToPunkIndex;

    mapping(uint256 => string) internal _certificateIdToPunkAttributes;

    mapping(uint256 => address) internal _certificateIdToMinter;

    constructor() ERC721("Crypto Punks Breeding Certificates", "BCERT") Ownable() {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * Strings Library (author James Lockhart: james at n3tw0rk.co.uk)
     *
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
	function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }
    
    /**
     * Strings Library (author James Lockhart: james at n3tw0rk.co.uk)
     * 
     * Modified String Split:
     * String splitByComaAndSpace
     *
     * Splits a string into an array of strings based off the delimiter value, in this case ",".
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string value to be split.
     * 
     * @return splitArr
     */	
	function _splitByComaAndSpace(string memory _base) internal pure returns (string[] memory splitArr) {
	    bytes memory _baseBytes = bytes(_base);
	    string memory _value = ",";
	    
	    uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);
        
        _offset = 0;
        _splitsCount = 0;
        
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int(_baseBytes.length);
            }
            
            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);
            
            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            
            _offset = uint(_limit) + 2;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
	}

    function checkCryptoPunksIndexToAddress(uint256 punkIndex)
        internal
        view
        returns (address)
    {
        return ICryptoPunks(CRYPTO_PUNKS_ADDR).punkIndexToAddress(punkIndex);
    }

    function checkWrappedCryptoPunks(uint256 punkIndex)
        internal
        view
        returns (address owner)
    {
        return ERC721(WRAPPED_CRYPTO_PUNKS_ADDR).ownerOf(punkIndex);
    }

    function checkOwnership(uint256 punkIndex) internal view returns (address owner) {
        if (checkCryptoPunksIndexToAddress(punkIndex) == WRAPPED_CRYPTO_PUNKS_ADDR) {
            return checkWrappedCryptoPunks(punkIndex);
        } else {
            return checkCryptoPunksIndexToAddress(punkIndex);
        }
    }

    function getCryptoPunkAttributes(uint256 _punkIndex)
        internal
        view
        returns (string memory)
    {
        return
            ICryptoPunksData(CRYPTO_PUNKS_DATA_ADDR).punkAttributes(
                uint16(_punkIndex)
            );
    }

        function generateImage(uint256 tokenId) internal view returns (string memory) {
        string memory output = string(abi.encodePacked(
            '<svg class="svgBody" width="240" height="240" viewBox="0 0 240 240" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="240" height="240" rx="10" style="fill:#ff05a0" />',
            '<rect y="175" width="240" height="65" rx="10" style="fill:#ff05a0" />',
            '<rect y="50" width="240" height="131" style="fill:#FFDDF2" />',
            '<rect y="180" width="240" height="20" style="fill:#FFC1E8" />',
            '<rect x="10" y="60" width="72" height="72" style="fill:white;opacity:0.5"/>',
            '<text x="20" y="100" class="smallermid" opacity="0.2">HEADSHOT</text>',
            '<text x="20" y="110" class="small" opacity="0.2">(OFF-CHAIN)</text>',
            '<text x="10" y="25" class="large white">BREEDING CERTIFICATE</text>',
            '<text x="10" y="40" class="medium" opacity="0.4">#',uint2str(tokenId),'</text>',
            '<text x="10" y="145" class="small">PUNK ID:</text>',
            '<text x="10" y="160" class="large">',uint2str(_certificateIdToPunkIndex[tokenId]),'</text>',
            '<text x="90" y="65" class="small">ATTRIBUTES:</text>',
            getAttributesForSvg(tokenId),
            '<text x="10" y="210" class="tiny white">This Breeding Certificate Entitles The Bearer To Breed </text>',
            '<text x="10" y="220" class="tiny white">A Baby Hipster, Using This Crypto Punk (ID: ',uint2str(_certificateIdToPunkIndex[tokenId]),') As One</text>',
            '<text x="10" y="230" class="tiny white"> Of The Parents. If Used, This Certificate Will Be Destroyed.</text>',
            '<style>.white{fill:white}.svgBody {font-family: "Courier New"} .tiny {font-size:6px} .small {font-size:8px} .smallermid {font-size:11px} .medium {font-size:12px}.large {font-size:18px}</style>',
            '</svg>'
            )
        );

        return output;
    }

    function getAttributesForSvg(uint256 tokenId) internal view returns (string memory) {
        string[] memory punkAttributesArray = _splitByComaAndSpace(_certificateIdToPunkAttributes[tokenId]);
        string memory output;
        uint yPosition = 75;
        output = string(abi.encodePacked('<text x="90" y="75" class="smallermid">', punkAttributesArray[0], '</text>'));
        
        for (uint256 i = 1; i < punkAttributesArray.length; i++) {
            string memory y = uint2str(yPosition + i * 10);
            output = string(abi.encodePacked(output, '<text x="90" y="', y , '" class="smallermid">', punkAttributesArray[i], '</text>'));
        }
        
        return output;
    }

    /**************************/
    /***  Public Functions  ***/
    /**************************/

    function setBabyHipstersAddr(address _babyHipstersAddr) public onlyOwner {
        babyHipstersAddr = _babyHipstersAddr;
    }

    function getPunkIndexFromCertificateId(uint256 _certificateId)
        public
        view
        returns (uint256)
    {
        return _certificateIdToPunkIndex[_certificateId];
    }

    function getPunkAttributesFromCertificateId(uint256 _certificateId)
        public
        view
        returns (string memory)
    {
        return _certificateIdToPunkAttributes[_certificateId];
    }

    function getMinterFromCertificateId(uint256 _certificateId)
        public
        view
        returns (address)
    {
        return _certificateIdToMinter[_certificateId];
    }

    function createCertificate(address to, uint256 punkIndex) public nonReentrant whenNotPaused {
        require(msg.sender == checkOwnership(punkIndex), "CPBreedingCerts: You don't own that punk");
        
        uint256 id = _tokenIdTracker.current();

        _certificateIdToPunkIndex[id] = punkIndex;
        _certificateIdToPunkAttributes[id] = getCryptoPunkAttributes(punkIndex);
        _certificateIdToMinter[id] = msg.sender;
        
        safeMint(to, id);

        _tokenIdTracker.increment();
    }

    function useCertificate(uint _certificateId) public nonReentrant whenNotPaused {
        require(msg.sender == ERC721.ownerOf(_certificateId) || msg.sender == babyHipstersAddr, "CPBreedingCerts: You can't use this certificate");
        _burn(_certificateId);
    }


    /**************************/
    /***      ERC-721       ***/
    /**************************/

    function safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "Crypto Punk Breeding Certificate #', 
                            uint2str(tokenId), 
                            '", "description": "Crypto Punks Breeding Certificates allow you to breed Baby Hipsters without owning a Crypto Punk", "image": "data:image/svg+xml;base64,', 
                            Base64.encode(bytes(generateImage(tokenId))),
                             '"}'
                        )
                    )
                )
            )
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    bytes16 private constant _ALPHABET = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "HEX_L");
        return string(buffer);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
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
