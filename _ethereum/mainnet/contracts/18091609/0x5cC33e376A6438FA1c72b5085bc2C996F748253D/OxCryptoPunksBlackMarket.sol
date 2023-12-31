// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title: OxCryptoPunks™
/// @author: Takuhatsu

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";

/****************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░████████████░░██░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░██████████████████░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░████████████████████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░████████████████████████░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░██████████████░░██████░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░██████░░██░░░░██░░░░██████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░████░░░░░░██░░░░░░██░░░░▒▒░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░██░░░░▒▒░░░░░░░░ *
 * ░░░░░░░░░░░░██░░░░▓▓▓▓░░░░░░▓▓▓▓██░░░░▒▒░░░░░░░░ *
 * ░░░░░░░░░░░░██░░░░██▒▒░░░░░░██▒▒██░░░░▒▒░░░░░░░░ *
 * ░░░░░░░░░░░░████░░░░░░░░░░░░░░░░██░░░░▒▒░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░██░░░░▒▒░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░░░░░░░██░░░░░░██░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░░░░░░░░░░░████████████░░░░░░░░ *
 * ░░░░░░░░░░░░░░██░░░░░░██████░░░░░░░░░░▓▓██░░░░░░ *
 * ░░░░░░░░░░░░░░░░██░░░░░░░░░░████████████░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░██░░██░░░░░░██░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░██░░░░██████░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░██░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░██░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 *                              OxCryptoPunks™ 2023 *
 ****************************************************/

// OxCryptoPunks™ is a programming experiment which combines two ways of storing NFT data:
// IPFS files and on-chain image bytes with accessories stored as array

contract OxCryptoPunksBlackMarket is ERC721, ERC721Enumerable, Ownable {
    // You can use this hash to verify the image file containing all the oxpunks
    string public imageHash =
        "b682ed0cd8072dd7b38bd85f0f301970c0fa3f595fdb9256bf14d6cc0686f438";

    string internal nftName = "OxCRYPTOPUNKS";
    string internal nftSymbol = unicode"OxϾ";

    string _baseTokenURI;

    uint16 public constant totalPunks = 10000;
    uint16 private punkAttributesCount;
    uint128 public constant punkPrice = 5000000000000000; // 0.005 ether

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    using Strings for uint256;
    using SafeMath for uint256;

    constructor() ERC721(nftName, nftSymbol) {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPunkDev(address to, uint16 numPunks) public onlyOwner {
        require(
            numPunks <= 20,
            "You can mint 20 punks max, in each transaction"
        ); // Limit to mint 50 punks per transaction
        require(
            totalSupply().add(numPunks) < totalPunks,
            "All punks are minted"
        );
        for (uint16 i = 0; i < numPunks; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function getPunk(uint16 numPunks) public payable {
        require(
            numPunks <= 20,
            "You can mint 20 punks max, in each transaction"
        );
        require(msg.value == numPunks * punkPrice, "Incorrect amount of funds");
        require(
            totalSupply().add(numPunks) <= totalPunks,
            "All punks are minted"
        );
        for (uint16 i = 0; i < numPunks; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function punksRemained() public view returns (uint256) {
        uint256 punksMinted = totalSupply();
        uint256 _punksRemained = uint256(totalPunks).sub(punksMinted);
        if (punksMinted == 0) {
            return totalPunks;
        } else {
            return _punksRemained;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
    }

    // OxCryptoPunks on-chain implementation inspired by "CryptoPunks: Data" by Larva Labs
    // https://etherscan.io/address/0x16f5a35647d6f03d5d3da7b35409d65ba03af3b2

    string internal constant SVG_HEADER =
        'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">';
    string internal constant SVG_FOOTER = "</svg>";

    bytes[] private punkImageBytesVault; // Storage for storing each punk's image byte data
    mapping(uint256 => uint8[]) private punkAttributesVault; // Storage for storing each punk's attributes
    string[] private punkAttributesList; // Storage for the list of all available attributes

    bool private contractSealed;

    // Seal the contract once punkImageBytesVault and punkAttributesVault are populated
    modifier unsealed() {
        require(!contractSealed, "Contract sealed");
        _;
    }

    // Check if user owns a particular punk
    modifier onlyPunkOwner(uint16 index) {
        require(
            ownerOf(index) == msg.sender,
            "Only the owner of the given punk is allowed to run this function"
        );
        _;
    }

    function addPunkAttributesList(
        string[] memory input
    ) external onlyOwner unsealed {
        for (uint256 i = 0; i < input.length; i++) {
            punkAttributesList.push(input[i]);
        }
    }

    // Emergency function which can override punk image data at any index
    function addPunkImageDev(
        uint16 _index,
        bytes memory _data
    ) external onlyOwner unsealed {
        require(_index < totalPunks, "Index out of range"); // Make sure index is within bounds
        if (_index >= punkImageBytesVault.length) {
            // If the index is greater than or equal to the length of the array, we need to add elements to the array
            uint256 elementsToAdd = (_index - punkImageBytesVault.length) + 1;
            for (uint256 i = 0; i < elementsToAdd; i++) {
                punkImageBytesVault.push("");
            }
        }
        punkImageBytesVault[_index] = _data; // Set the data for the given index
    }

    // Emergency function which can override punk attributes data at any index
    function addToPunkAttributesVaultDev(
        uint16[] memory indexes,
        uint8[][] memory attributeIndices
    ) external onlyOwner unsealed {
        require(
            indexes.length == attributeIndices.length,
            "Arrays length mismatch"
        );

        for (uint16 i = 0; i < indexes.length; i++) {
            uint16 index = indexes[i];
            uint8[] memory indices = attributeIndices[i];

            punkAttributesVault[index] = indices;

            if (index >= punkAttributesCount) {
                punkAttributesCount = index + 1;
            }
        }
    }

    function addPunkImage(
        uint16 index,
        bytes memory _data
    ) external onlyPunkOwner(index) unsealed {
        require(index < totalPunks, "Index out of range"); // Make sure index is within bounds
        if (index >= punkImageBytesVault.length) {
            // If the index is greater than or equal to the length of the array, we need to add elements to the array
            uint256 elementsToAdd = (index - punkImageBytesVault.length) + 1;
            for (uint256 i = 0; i < elementsToAdd; i++) {
                punkImageBytesVault.push("");
            }
        }
        punkImageBytesVault[index] = _data; // Set the data for the given index
    }

    function addToPunkAttributesVault(
        uint16 index,
        uint8[] memory attributeIndices
    ) external unsealed onlyPunkOwner(index) {
        require(
            attributeIndices.length > 0,
            "Attribute indices array is empty"
        );

        punkAttributesVault[index] = attributeIndices;

        if (index >= punkAttributesCount) {
            punkAttributesCount = index + 1;
        }
    }

    // Seal the contract once punkImageBytesVault and punkAttributesVault are populated
    function sealContract() external onlyOwner unsealed {
        contractSealed = true;
    }

    // Returns punk image bytes
    function getPunkImage(uint16 _index) public view returns (bytes memory) {
        require(
            _index < punkImageBytesVault.length,
            "OxCryptoPunks: index out of range"
        );
        return punkImageBytesVault[_index];
    }

    // Returns punk image in SVG
    function getPunkImageSvg(
        uint16 index
    ) external view returns (string memory svg) {
        bytes memory pixels = getPunkImage(index);
        svg = string(abi.encodePacked(SVG_HEADER));
        bytes memory buffer = new bytes(8);
        for (uint256 y = 0; y < 24; y++) {
            for (uint256 x = 0; x < 24; x++) {
                uint256 p = (y * 24 + x) * 4;
                if (uint8(pixels[p + 3]) > 0) {
                    for (uint256 i = 0; i < 4; i++) {
                        uint8 value = uint8(pixels[p + i]);
                        buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    svg = string(
                        abi.encodePacked(
                            svg,
                            '<rect x="',
                            toString(x),
                            '" y="',
                            toString(y),
                            '" width="1" height="1" shape-rendering="crispEdges" fill="#',
                            string(buffer),
                            '"/>'
                        )
                    );
                }
            }
        }
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    function getPunkAttributes(
        uint16 index
    ) external view returns (string memory text) {
        require(index < punkAttributesCount, "Invalid index");

        uint8[] memory attributeIndices = punkAttributesVault[index];
        string memory result;

        for (uint16 i = 0; i < attributeIndices.length; i++) {
            uint8 attributeIndex = attributeIndices[i];
            require(
                attributeIndex < punkAttributesList.length,
                "Invalid attribute index"
            );
            if (i > 0) {
                result = string(
                    abi.encodePacked(
                        result,
                        ", ",
                        punkAttributesList[attributeIndex]
                    )
                );
            } else {
                result = punkAttributesList[attributeIndex];
            }
        }

        require(bytes(result).length > 0, "Attributes not added");

        return result;
    }

    // Helper function to split a string by a delimiter
    function split(
        string memory input,
        string memory delimiter
    ) internal pure returns (string[] memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory delimiterBytes = bytes(delimiter);
        uint16 delimiterCount = 1;

        // Count the number of delimiters in the input string
        for (
            uint16 i = 0;
            i < inputBytes.length - delimiterBytes.length + 1;
            i++
        ) {
            bytes memory currentBytes;
            for (uint16 j = 0; j < delimiterBytes.length; j++) {
                currentBytes = abi.encodePacked(
                    currentBytes,
                    inputBytes[i + j]
                );
            }
            if (keccak256(currentBytes) == keccak256(delimiterBytes)) {
                delimiterCount++;
                i += uint16(delimiterBytes.length) - 1;
            }
        }

        // Split the input string into an array
        string[] memory tokens = new string[](delimiterCount);
        uint16 tokenIndex = 0;
        uint16 start = 0;

        for (
            uint16 i = 0;
            i < inputBytes.length - delimiterBytes.length + 1;
            i++
        ) {
            bytes memory currentBytes;
            for (uint16 j = 0; j < delimiterBytes.length; j++) {
                currentBytes = abi.encodePacked(
                    currentBytes,
                    inputBytes[i + j]
                );
            }
            if (keccak256(currentBytes) == keccak256(delimiterBytes)) {
                tokens[tokenIndex] = substring(input, start, i);
                start = uint16(i) + uint16(delimiterBytes.length);
                tokenIndex++;
                i += uint16(delimiterBytes.length) - 1;
            }
        }

        tokens[tokenIndex] = substring(input, start, uint16(inputBytes.length));
        return tokens;
    }

    // Helper function to get a substring from a string
    function substring(
        string memory str,
        uint16 startIndex,
        uint16 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint16 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    // String stuff from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // OVERRIDES

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
