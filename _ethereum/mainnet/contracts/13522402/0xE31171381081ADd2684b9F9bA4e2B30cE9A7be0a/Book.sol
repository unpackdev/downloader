// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract Book is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    mapping (address => bool) _hasMinted;
    uint256 public premineRemaining = 19;

    constructor() ERC721("The Emperor's Password", "BOOK") {
        _hasMinted[msg.sender] = true;
        _mint(msg.sender, 0);
    }

    function mint(bytes32 hash) external {
        require(!_hasMinted[msg.sender]);
        require(totalSupply() + premineRemaining < 500);
        require(hash == sha256(abi.encodePacked(msg.sender, "emperor")));

        _hasMinted[msg.sender] = true;
        _mint(msg.sender, totalSupply());
    }

    function premineMint(address to) external {
        require(msg.sender == owner());
        require(premineRemaining > 0);
        premineRemaining -= 1;

        _mint(to, totalSupply());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function contractURI() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{"
                            '"name":"The Emperor\'s Password",'
                            '"description":"Only the wise can read the password.",'
                            '"image":"data:image/svg+xml;base64,',
                            Base64.encode(getClosedSVG()),
                            '"}'
                        )
                    )
                )
            );
    }

    bytes constant PASSWORD_CHARS = "abcdefghijklmnopqrstuvwxyz234567";

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId < totalSupply());
        for (uint256 i = 1; i < 6; i++) {
            uint256 hash = uint256(blockhash(block.number - i));
            if ((hash % 256) / 2 == 0x77) {
                bytes memory password = new bytes(10);
                for (uint256 j = 0; j < 10; j++) {
                    password[j] = PASSWORD_CHARS[hash % 32];
                    hash /= 32;
                }
                return getMetadata(password);
            }
        }
        return getMetadata("");
    }

    bytes constant OPEN =
        hex"00f80000043f00002007001f0007008800060440000fe200003f100001f880000f4400007a200003d100001e880000f4400007a200003d100001e880000f4400007a200003d100001e880000f4400007a200003d100001e880000f4400007a200003d100001e8f8000f403f007a000703dff0071e007e06f0000fcf800001bffffffeffffffe7fffffe0";
    bytes constant CLOSED =
        hex"03021e1d03042020a105011a881f1a03851f0203842004018323010187230101841c0102840a010e84040102880401029f0401029f1c01029e1d01019e0401018904010187020101881c0102891d0101";
    bytes constant WHITE = "FFFFFF";
    bytes constant BLACK = "000000";

    function getClosedSVG() internal pure returns (bytes memory) {
        bytes memory svg;

        for (uint256 i = 0; i < CLOSED.length / 4; i++) {
            uint256 x = uint8(CLOSED[i * 4]);
            bool white = x >= 128;
            x = x % 128;
            uint256 y = uint8(CLOSED[i * 4 + 1]);
            uint256 w = uint8(CLOSED[i * 4 + 2]);
            uint256 h = uint8(CLOSED[i * 4 + 3]);
            svg = abi.encodePacked(
                svg,
                '<rect fill="#',
                white ? WHITE : BLACK,
                '" x="',
                itoa(x),
                '" y="',
                itoa(y),
                '" width="',
                itoa(w),
                '" height="',
                itoa(h),
                '"/>'
            );
        }
        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" preserveAspectRatio="xMinYMin meet" viewBox="0 0 38 38" shape-rendering="crispEdges">',
                svg,
                '</svg>'
            );
    }

    function getOpenSVG() internal pure returns (bytes memory) {
        bytes memory svg;

        uint256 xstart = 0;
        uint256 len = 0;
        uint256 ystart = 0;

        for (uint256 y = 0; y < 38; y++) {
            for (uint256 x = 0; x < 29; x++) {
                uint256 coord = y * 29 + x;
                bool on = uint8(OPEN[coord / 8]) & (1 << (7 - (coord % 8))) > 0;
                if ((!on || y != ystart) && len > 0) {
                    svg = abi.encodePacked(
                        svg,
                        '<rect class="f" x="',
                        itoa(xstart),
                        '" y="',
                        itoa(ystart),
                        '" width="',
                        itoa(len),
                        '"/>'
                    );
                    len = 0;
                }
                if (on) {
                    if (len == 0) {
                        xstart = x;
                        ystart = y;
                    }
                    len += 1;
                }
            }
        }

        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" preserveAspectRatio="xMinYMin meet" viewBox="0 0 57 38" shape-rendering="crispEdges"><style>rect.f{fill:#000000;height:1px;}</style><rect x="0" y="0" width="57" height="38" fill="#FFFFFF"/><g id="left">',
                svg,
                '</g><use href="#left" transform="translate(57,0) scale(-1, 1)"/></svg>'
            );
    }

    function itoa(uint256 n) internal pure returns (bytes memory) {
        if (n == 0) {
            return "0";
        }
        uint256 len = 0;
        uint256 m = n;
        while (m > 0) {
            len += 1;
            m /= 10;
        }

        bytes memory ret = new bytes(len);
        for (uint256 i = len; i > 0; i--) {
            ret[i - 1] = bytes1(uint8(48 + (n % 10)));
            n /= 10;
        }

        return ret;
    }

    function getMetadata(bytes memory password)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"The Emperor\'s Password",'
                            '"description":"This book holds the Emperor\'s secret password. It\'s written in the same ink used to dye his clothes. You\'ll need good timing, and watch out for caching!",'
                            '"image":"data:image/svg+xml;base64,',
                            Base64.encode(
                                password.length > 0
                                    ? getOpenSVG()
                                    : getClosedSVG()
                            ),
                            '","attributes":[',
                            password.length > 0
                                ? abi.encodePacked(
                                    '{"trait_type":"password","value":"',
                                    password,
                                    '"}'
                                )
                                : bytes(
                                    '{"trait_type":"patience","display_type":"boost_number","value":100}'
                                ),
                            "]}"
                        )
                    )
                )
            );
    }
}
