pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: UNLICENSE

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./base64.sol";
import "./ToColor.sol";
import "./strings.sol";

contract SvgPunks {
    function punkImage(uint16 index) public view returns (bytes memory) {}

    function punkAttributes(uint16 index)
        external
        view
        returns (string memory text)
    {}

    function punkImageSvg(uint16 index)
        external
        view
        returns (string memory svg)
    {}
}

contract CryptoChunks is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint16;
    using Strings for uint256;
    using ToColor for bytes3;
    using strings for *;

    uint256 private constant limit = 9999;

    Counters.Counter private _tokenIds;

    string _symbol = unicode"OϾ";

    SvgPunks svgP;

    bool private auctionStarted;

    mapping(uint16 => bool) public isNormied;

    mapping(uint256 => bytes3) public color;

    string internal constant SVG_HEADER_NORMIE =
        '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.2" viewBox="0 0 24 24"';

    // get Phunked (on-chain)
    string internal constant SVG_HEADER =
        '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.2" viewBox="0 0 24 24" transform="scale (-1, 1)" transform-origin="center"';

    // larva labs has a foot fetish
    string internal constant SVG_FOOTER = "</svg>";

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    constructor(address chainPunks)
        ERC721("CryptoChunks, Phunks On-Chained!", _symbol)
    {
        svgP = SvgPunks(chainPunks);
        transferOwnership(0xb010ca9Be09C382A9f31b79493bb232bCC319f01);
    }

    /**
     * @notice Mint pricing scheme borrowed from Phunks.
     */
    function getCostForMinting(uint256 _numToMint)
        private
        view
        returns (uint256)
    {
        require(
            _tokenIds.current() + _numToMint <= limit,
            "There aren't that many left."
        );
        if (_numToMint == 1) {
            return 0.02 ether;
        } else if (_numToMint == 3) {
            return 0.05 ether;
        } else if (_numToMint == 5) {
            return 0.07 ether;
        } else if (_numToMint == 10) {
            return 0.10 ether;
        } else {
            revert("Unsupported mint amount");
        }
    }

    /**
     * @notice Supporting tyranny isn't cheap. Flip to "punk" for 10 ETH
     */
    function setNormied(uint16 index, bool isNormie) public payable {
        require(msg.value >= 10 ether, "don't be cheap");
        require(ownerOf(index) == msg.sender, "Not Owner");

        isNormied[index] = isNormie;
    }

    /**
     * @notice Change your BG color for 1 ETH.
     */
    function randomizeBackground(uint16 index) public payable {
        require(msg.value >= 1 ether, "don't be cheap");
        require(ownerOf(index) == msg.sender, "Not Owner");

        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                address(this),
                index
            )
        );
        color[index] =
            bytes2(predictableRandom[0]) |
            (bytes2(predictableRandom[1]) >> 8) |
            (bytes3(predictableRandom[2]) >> 16);
    }

    /**
     * @notice Sets a string value "normied" for use in JSON.
     */
    function checkIsNormied(uint16 index) public view returns (string memory) {
        if (isNormied[index] == true) {
            string memory normie = "true";
            return normie;
        } else {
            string memory normie = "false";
            return normie;
        }
    }

    /**
     * @notice Improved version of CryptoPunks:Data, reduces gas significantly..
     */
    function getPunkImage(uint16 index)
        private
        view
        returns (string memory svg)
    {
        bytes memory pixels = svgP.punkImage(index);

        if (isNormied[index] == true) {
            svg = string(
                abi.encodePacked(
                    SVG_HEADER_NORMIE,
                    ' style="background-color:#',
                    color[index].toColor(),
                    '">'
                )
            );
        } else {
            svg = string(
                abi.encodePacked(
                    SVG_HEADER,
                    ' style="background-color:#',
                    color[index].toColor(),
                    '">'
                )
            );
        }

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
                            x.toString(),
                            '" y="',
                            y.toString(),
                            '" width="1" height="1" fill="#',
                            string(buffer),
                            '"/>'
                        )
                    );
                }
            }
        }
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    /**
     * @notice Assemble these phunkers.
     */
    // prettier-ignore
    function constructTokenURI(uint16 id) private view returns (string memory) {

        string memory _punkSVG = Base64.encode(bytes(getPunkImage(id)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                'OC',
                                ' Phunk #',
                                id.toString(),
                                '", "attributes": "',
                                svgP.punkAttributes(id),
                                '", "color": "',
                                color[id].toColor(),
                                '", "normied": "',
                                checkIsNormied(id),
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                _punkSVG,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Type conversion, uint256 to uint16
     */
    function convert(uint256 _a) private pure returns (uint16) {
        return uint16(_a);
    }

    /**
     * @notice Receives json from constructTokenURI
     */
    // prettier-ignore
    function tokenURI(uint256 _id)
        public
        view
        override     
        returns (string memory)
    {
        require(_id <= limit, "non-existant");
        require(_exists(_id), "not exist");

        uint16 id = convert(_id);

        return constructTokenURI(id);
    }

    /**
     * @notice Mints 0id to owner, mints first 100 to owner.
     */
    function initCollection() public payable onlyOwner {
        require(_tokenIds.current() == 0, "only to init collection");

        uint256 id0 = _tokenIds.current();
        _mint(msg.sender, id0);

        for (uint256 i = 0; i < 100; i++) {
            _tokenIds.increment();

            uint256 id = _tokenIds.current();
            _mint(msg.sender, id);

            bytes32 predictableRandom = keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    msg.sender,
                    address(this),
                    id
                )
            );
            color[id] =
                bytes2(predictableRandom[0]) |
                (bytes2(predictableRandom[1]) >> 8) |
                (bytes3(predictableRandom[2]) >> 16);
        }

        isNormied[0] = true;
    }

    /**
     * @notice Mints item, assigns pseudo-random color value.
     */
    function mintItem(uint256 _numToMint) public payable nonReentrant {
        require(_tokenIds.current() < limit, "mint limit met");
        require(auctionStarted == true, "auction not started");
        require(
            _tokenIds.current() + _numToMint <= limit,
            "There aren't that many left."
        );
        uint256 costForMinting = getCostForMinting(_numToMint);
        require(
            msg.value >= costForMinting,
            "Too little sent, please send more eth."
        );

        for (uint256 i = 0; i < _numToMint; i++) {
            _tokenIds.increment();

            uint256 id = _tokenIds.current();
            _mint(msg.sender, id);

            bytes32 predictableRandom = keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    msg.sender,
                    address(this),
                    id
                )
            );
            color[id] =
                bytes2(predictableRandom[0]) |
                (bytes2(predictableRandom[1]) >> 8) |
                (bytes3(predictableRandom[2]) >> 16);
        }
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function startAuction() public onlyOwner {
        auctionStarted = true;
    }

    function pauseAuction() public onlyOwner {
        auctionStarted = false;
    }

    /**
     * @notice Fallback for accepting eth
     */
    receive() external payable {}
}
