// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";
import "./Strings.sol";

/// @author bk-lab.eth
/// @title Experiment project with random color
/**
 * @dev This is an experiment project for generating random colors.
 * We'll donate 95% income to help Ukraine fight for freedom.
 * So feel free to mint and enjoy your own colors.
 */
contract DonateColorU is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    string private constant _DESCRIPTION = "The Donation Souvenir";

    // Ukraine eth address
    address public _donateAddress = 0x165CD37b4C644C2921454429E7F9358d18A45e14;

    // Current incremental token id
    uint256 public _tokenIdCounter = 0;

    // Mapping from token id to the donor
    mapping(uint256 => address) private _donors;

    // Mapping from token id to the donate time
    mapping(uint256 => uint256) private _donateTime;

    // Mapping from token id to the donate amounts
    mapping(uint256 => uint256) private _donateAmounts;

    constructor() ERC721("Donate Color U", "DCU") {}

    /**
     * @dev External function to mint your NFT(at least 0.01 ether), we'll donate 95% to help Ukraine.
     * @param to address representing the new owner of the given token ID
     */
    function mint(address to) external payable nonReentrant {
        require(msg.value >= 0.01 ether, "At least 0.01 ether");

        uint256 donate = (msg.value * 95) / 100;
        (bool sent, ) = _donateAddress.call{value: donate}("");
        require(sent, "Donate failed");

        _tokenIdCounter += 1;
        _donors[_tokenIdCounter] = tx.origin;
        _donateTime[_tokenIdCounter] = block.timestamp;
        _donateAmounts[_tokenIdCounter] = msg.value;
        _safeMint(to, _tokenIdCounter);
    }

    /**
     * @dev Public function to take the NFT infomations
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     * @return string whether the call correctly returned the expected colors and traits. (Following opensea metadata standards)
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string[3] memory colors;
        uint256 seed = uint256(
            keccak256(abi.encodePacked(_donateAmounts[tokenId], ",", tokenId.toString(), _donors[tokenId]))
        );

        bool isHorizontal = seed % 2 == 1;
        seed >>= 1;

        colors[0] = getColorHex(seed);
        seed >>= 24;

        colors[1] = getColorHex(seed);
        seed >>= 24;

        bool isInThirds = seed % 2 == 1;
        seed >>= 1;

        uint8 colorCounts = 2;
        if (isInThirds) {
            colors[2] = getColorHex(seed);
            colorCounts = 3;
        }
        string memory svg = isHorizontal
            ? drawHorizontalColor(colors, colorCounts)
            : drawVerticalColor(colors, colorCounts);
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "DonateColorU #',
                tokenId.toString(),
                '", "description": "',
                _DESCRIPTION,
                '", "image_data": "',
                svg,
                '", "attributes": ',
                packAttributes(tokenId),
                "}"
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function packAttributes(uint256 tokenId)
        private
        view
        returns (string memory)
    {
        string memory addressHex = Strings.toHexString(uint256(uint160(_donors[tokenId])), 20);
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "Thanks for", "value": "',
                    addressHex,
                    '"}, {"display_type": "boost_number", "trait_type": "Amounts", "value": ',
                    _donateAmounts[tokenId].toString(),
                    '}, {"display_type": "date", "trait_type": "Donate time", "value": ',
                    _donateTime[tokenId].toString(),
                    "}]"
                )
            );
    }

    /**
     * @dev Public function withdraw the NFT income.
     */
    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

    /**
     * @dev Private function to generate color from seed.
     * @param seed uint256 seed for generating random color
     * @return string whether the call correctly returned color string(ex. 02a637)
     */
    function getColorHex(uint256 seed) private pure returns (string memory) {
        uint256 color = seed % (2**24);
        return toHexString(color, 3);
    }

    /**
     * @dev Private function to convert integer into hex string. (Refer from Strings.toHexString)
     * @param value uint256 value we need to be convert
     * @param length uint256 length of the bytes we need to convert
     * @return string whether the call correctly returned the hex string
     */
    function toHexString(uint256 value, uint256 length)
        private
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = 2 * length; i > 0; --i) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Private function to draw the colors with horizontal layout.
     * @param colors Array of colors to be draw (at most 3 colors)
     * @param length uint8 length of colors will be draw
     * @return string whether the call correctly returned result image into svg format
     */
    function drawHorizontalColor(string[3] memory colors, uint8 length)
        private
        pure
        returns (string memory)
    {
        uint256 width = 360;
        uint256 heights = 240;

        uint256 pos_y = 0;
        uint256 step_y = heights / length;

        bytes memory svg = abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 ",
            width.toString(),
            " ",
            heights.toString(),
            "'>"
        );
        for (uint8 idx = 0; idx < length; idx++) {
            svg = abi.encodePacked(
                svg,
                "<rect x='0' y='",
                pos_y.toString(),
                "' width='100%' height='",
                step_y.toString(),
                "' fill='#",
                colors[idx],
                "' />"
            );
            pos_y += step_y;
        }
        svg = abi.encodePacked(svg, "</svg>");
        return string(svg);
    }

    /**
     * @dev Private function to draw the colors with vertical layout.
     * @param colors Array of colors to be draw (at most 3 colors)
     * @param length uint8 length of colors will be draw
     * @return string whether the call correctly returned result image into svg format
     */
    function drawVerticalColor(string[3] memory colors, uint8 length)
        private
        pure
        returns (string memory)
    {
        uint256 width = 360;
        uint256 heights = 240;

        uint256 pos_x = 0;
        uint256 step_x = width / length;

        bytes memory svg = abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 ",
            width.toString(),
            " ",
            heights.toString(),
            "'>"
        );
        for (uint8 idx = 0; idx < length; idx++) {
            svg = abi.encodePacked(
                svg,
                "<rect x='",
                pos_x.toString(),
                "' y='0' width='",
                step_x.toString(),
                "' height='100%' fill='#",
                colors[idx],
                "' />"
            );
            pos_x += step_x;
        }
        svg = abi.encodePacked(svg, "</svg>");
        return string(svg);
    }
}
