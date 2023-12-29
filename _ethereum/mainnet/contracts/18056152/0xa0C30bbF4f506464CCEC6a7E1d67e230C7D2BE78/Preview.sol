// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Base64.sol";

interface IFont {
    function font() external view returns (string memory);
}

contract Preview is ERC721, ERC2981, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    struct TokenContext {
        uint256 color;
        uint256 bg;
        address creator;
    }

    uint256 private _tokenSupply;
    uint256 public price = 0.01 ether;
    uint256 public artistPercentage = 33;
    bool public isActive;
    string public description;
    string private _baseExternalURI;
    address public artistAddress;
    address public additionalAddress;
    mapping(uint256 => TokenContext) public tokenContexts;
    mapping(address => bool) public allowlist;
    mapping(uint256 => bool) private mintedColors;

    IFont private font;

    event Mint(address _address, uint256 _tokenId, string _color, string _background);

    constructor(address _fontAddress, string memory _description) ERC721("Preview", "PRV") {
        font = IFont(_fontAddress);
        description = _description;
    }

    function _mint(string memory color, string memory background) private {
        require(isActive, "inactive");
        uint256 c = hexToInt(color);
        uint256 b = hexToInt(background);
        require(c != b, "minted colors");
        require(mintedColors[c] == false, "minted colors");
        require(mintedColors[b] == false, "minted colors");
        tokenContexts[_tokenSupply] = TokenContext(c, b, _msgSender());
        mintedColors[c] = true;
        mintedColors[b] = true;
        _safeMint(_msgSender(), _tokenSupply);
        emit Mint(_msgSender(), _tokenSupply, color, background);
        _tokenSupply++;
    }

    // @dev color = 000, background = FFF
    function mint(string memory color, string memory background) external payable nonReentrant {
        require(msg.value >= price, "Not enough ETH sent; check price!");
        _mint(color, background);
        uint256 artistAmount = price.div(100).mul(artistPercentage);
        payable(artistAddress).transfer(artistAmount);
        payable(additionalAddress).transfer(msg.value.sub(artistAmount));
    }

    // @dev color = 000, background = FFF
    function mintBNN(string memory color, string memory background) external nonReentrant {
        require(allowlist[_msgSender()], "only allowlist");
        allowlist[_msgSender()] = false;
        _mint(color, background);
    }

    // @dev color = 000, background = FFF
    function preview(string memory color, string memory background)
        external
        view
        returns (
            bool isColorOK,
            bool isBackgroundOK,
            string memory html,
            string memory svg
        )
    {
        isColorOK = !mintedColors[hexToInt(color)];
        isBackgroundOK = !mintedColors[hexToInt(background)];
        svg = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(tokenSVG(color, background)))
            )
        );
        html = string(
            abi.encodePacked(
                "data:text/html;base64,",
                Base64.encode(bytes(tokenHTML(color, background)))
            )
        );
    }

    function colorTable() external view returns (bool[] memory) {
        bool[] memory colors = new bool[](4096);
        for (uint256 i; i <= 4095; i++) {
            colors[i] = mintedColors[i];
        }
        return colors;
    }

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setDescription(string memory desc) external onlyOwner {
        description = desc;
    }

    function setBaseExternalURI(string memory URI) external onlyOwner {
        _baseExternalURI = URI;
    }

    function addAddressesToAllowlist(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            allowlist[addrs[i]] = true;
        }
    }

    function removeAddressesFromAllowlist(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            allowlist[addrs[i]] = false;
        }
    }

    function setPaymentAddresses(
        address _artistAddress,
        address _additionalAddress,
        uint256 _artistPercentage
    ) external onlyOwner {
        artistAddress = _artistAddress;
        additionalAddress = _additionalAddress;
        artistPercentage = _artistPercentage;
    }

    function intToHex(uint256 value) public pure returns (string memory) {
        bytes memory buffer = new bytes(3);
        bytes16 symbols = "0123456789abcdef";
        uint256 i = 3;
        do {
            i--;
            buffer[i] = symbols[value & 0xf];
            value >>= 4;
        } while (i > 0);
        require(value == 0);
        return string(buffer);
    }

    function byteToInt(bytes1 b) private pure returns (uint8) {
        if (b >= "0" && b <= "9") {
            return uint8(b) - uint8(bytes1("0"));
        } else if (b >= "A" && b <= "F") {
            return 10 + uint8(b) - uint8(bytes1("A"));
        } else if (b >= "a" && b <= "f") {
            return 10 + uint8(b) - uint8(bytes1("a"));
        }
        revert("invalid character");
    }

    function hexToInt(string memory str) public pure returns (uint256) {
        bytes memory b = bytes(str);
        require(b.length == 3, "invalid color");
        uint256 number = 0;
        for (uint256 i = 0; i < 3; i++) {
            number = number << 4;
            number |= byteToInt(b[i]);
        }
        require(number >= 0 && number <= 4095, "invalid color");
        return number;
    }

    function svgStyle(string memory _color, string memory _bg)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<style>",
                    "@font-face {font-family:'HASH';font-display:block;src:url(",
                    font.font(),
                    ") format('woff2');}",
                    "html,body{width:100%;height:100%;overflow:hidden;background-color:black}*{margin:0;padding:0;box-sizing:border-box;line-height:1;font-family:'HASH',monospace}.w{x:0;y:0;width:100%;height:100%}text,p{dominant-baseline:text-before-edge;fill:",
                    "#",
                    _color,
                    ";stroke:#",
                    _color,
                    ";color:#",
                    _color,
                    "}.bg{fill:#",
                    _bg,
                    ";background-color:#",
                    _bg,
                    "}p{display:inline-block;white-space:nowrap;position:absolute}",
                    ".rtl{animation:rtl 5s linear infinite}@keyframes rtl{from{transform:translateX(0%)}to{transform:translateX(-100%)}}.rtl2{animation:rtl2 5s linear infinite}@keyframes rtl2{from{transform:translateX(100%)}to{transform:translateX(0%)}}.ltr{animation:ltr 5s linear infinite}@keyframes ltr{from{transform:translateX(-100%)}to{transform:translateX(0%)}}.ltr2{animation:ltr2 5s linear infinite}@keyframes ltr2{from{transform:translateX(0%)}to{transform:translateX(100%)}}"
                    "</style>"
                )
            );
    }

    string constant TEXT = "The quick brown fox jumps over the lazy dog.1234567890";

    string[7] SVGsizes = ["60", "70", "80", "110", "140", "170", "200"];
    string[7] SVGtops = ["15", "90", "175", "270", "400", "565", "765"];
    uint256[7] SVGwidths = [2050, 2392, 2734, 3759, 4784, 5810, 6835];

    string[7] HTMLheights = ["7.5", "8.5", "9.5", "13", "16.5", "20", "22.5"];
    string[7] HTMLsizes = ["6", "7", "8", "11", "14", "17", "20"];
    string[2] HTMLdirections = ["ltr", "rtl"];

    function tokenSVG(string memory _color, string memory _bg) public view returns (string memory) {
        string memory body;
        uint256 seed = uint256(keccak256(abi.encodePacked(_color, _bg)));
        for (uint256 i = 0; i < 7; i++) {
            body = string(
                abi.encodePacked(
                    body,
                    "<text x='-",
                    Strings.toString(seed % (SVGwidths[i] - 1000)),
                    "' y='",
                    SVGtops[i],
                    "' font-size='",
                    SVGsizes[i],
                    "'>",
                    TEXT,
                    "</text>"
                )
            );
            seed = uint256(keccak256(abi.encodePacked(seed)));
        }

        return
            string(
                abi.encodePacked(
                    "<svg viewBox='0 0 1000 1000' width='1000px' height='1000px' fill='none' preserveAspectRatio='xMidYMid meet' version='2' xmlns='http://www.w3.org/2000/svg'>",
                    svgStyle(_color, _bg),
                    "<rect class='bg w'/>",
                    body,
                    "</svg>"
                )
            );
    }

    function tokenHTML(string memory _color, string memory _bg)
        public
        view
        returns (string memory)
    {
        string memory body;
        uint256 seed = uint256(keccak256(abi.encodePacked(_color, _bg)));
        for (uint256 i = 0; i < 7; i++) {
            string memory speed = Strings.toString(20 + (seed % 30));
            seed = uint256(keccak256(abi.encodePacked(seed)));
            string memory direction = HTMLdirections[seed % HTMLdirections.length];
            seed = uint256(keccak256(abi.encodePacked(seed)));
            string memory animationFunction = string(
                abi.encodePacked(
                    "animation-timing-function:cubic-bezier(",
                    "0.",
                    Strings.toString(uint256(keccak256(abi.encodePacked(seed, "af1"))) % 10),
                    ",0.",
                    Strings.toString(uint256(keccak256(abi.encodePacked(seed, "af2"))) % 10),
                    ",0.",
                    Strings.toString(uint256(keccak256(abi.encodePacked(seed, "af3"))) % 10),
                    ",0.",
                    Strings.toString(uint256(keccak256(abi.encodePacked(seed, "af4"))) % 10),
                    ")"
                )
            );
            seed = uint256(keccak256(abi.encodePacked(seed)));
            body = string(
                abi.encodePacked(
                    body,
                    "<div style='height:",
                    HTMLheights[i],
                    "vh; font-size:",
                    HTMLsizes[i],
                    "vh'>",
                    "<p class='",
                    direction,
                    "' style='animation-delay:500ms;animation-duration:",
                    speed,
                    "s;",
                    animationFunction,
                    "'>",
                    TEXT,
                    "&nbsp;",
                    "</p>",
                    "<p class='",
                    direction,
                    "2' style='animation-delay:500ms;animation-duration:",
                    speed,
                    "s;",
                    animationFunction,
                    "'>",
                    TEXT,
                    "&nbsp;",
                    "</p></div>"
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    "<!DOCTYPE html><html><head><meta name='format-detection' content='telephone=no'/>",
                    "<link rel='preload' href='",
                    font.font(),
                    "' as='font' type='font/woff2'/>",
                    svgStyle(_color, _bg),
                    "</head><body xmlns='http://www.w3.org/1999/xhtml'><div style='padding-top:1.5vh;height:100%;max-width:200vh;position:relative;overflow:hidden;margin:0 auto;' class='bg'>",
                    body,
                    "</div></body></html>"
                )
            );
    }

    function getMetaData(uint256 _tokenId) private view returns (string memory) {
        TokenContext memory ctx = tokenContexts[_tokenId];
        string memory _color = intToHex(ctx.color);
        string memory _bg = intToHex(ctx.bg);
        return
            string(
                abi.encodePacked(
                    '{"name":"Preview #',
                    _color,
                    " #",
                    _bg,
                    '","description":"',
                    description,
                    '","image":"data:image/svg+xml;base64,',
                    Base64.encode(bytes(tokenSVG(_color, _bg))),
                    '","animation_url":"data:text/html;base64,',
                    Base64.encode(bytes(tokenHTML(_color, _bg))),
                    '","external_url":"',
                    _baseExternalURI,
                    Strings.toString(_tokenId),
                    '","attributes":[{"trait_type":"New Creator","value":"',
                    Strings.toHexString(ctx.creator),
                    '"},{"trait_type":"Color","value":"',
                    _color,
                    '"},{"trait_type":"Background","value":"',
                    _bg,
                    '"}]}'
                )
            );
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("data:application/json;utf8,", getMetaData(_tokenId)));
    }

    function totalSupply() external view returns (uint256) {
        return _tokenSupply;
    }

    function setRoyaltyInfo(address receiver_, uint96 royaltyBps_) external onlyOwner {
        _setDefaultRoyalty(receiver_, royaltyBps_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
