pragma solidity ^0.8.6;
//SPDX-License-Identifier: MIT

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

/* IN COLLABORATION WITH */

/*
  ____  _  _                 _        
 / ___|(_)| |_   ___   ___  (_) _ __  
| |  _ | || __| / __| / _ \ | || '_ \ 
| |_| || || |_ | (__ | (_) || || | | |
 \____||_| \__| \___| \___/ |_||_| |_|
 
   Made by nowonder
   https://twitter.com/nowonderer

 */

import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";

contract GTC_UBER_NOUNS is ERC721, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Gitcoin multi-sig address, called on buy
    // 100% to Gitcoin for GR12
    address payable public constant gitcoin =
        payable(0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6);

    // Gitcoin maintainer address, receives 4/5 of this collection,
    // To be donated to selected GR12 participants
    address payable public constant Owocki =
        payable(0x00De4B13153673BCAE2616b67bf822500d325Fc3);

    // Structs from Noun gen process
    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Rect {
        uint8 length;
        uint8 colorIndex;
    }

    struct DecodedImage {
        uint8 paletteIndex;
        ContentBounds bounds;
        Rect[] rects;
    }

    struct TokenURIParams {
        string name;
        string description;
        bytes[] parts;
        string background;
    }

    /**
     * @notice Auction variables
     */

    uint256 private startingPrice = 999999 ether;

    uint256 private startAt;

    uint256 private mintDeadline;

    uint256 private constant limit = 5;

    uint256 private priceDeductionRate = 1.9289 ether;

    bool private auctionStarted;

    bool private publicGoodsFunded;

    // Palettes for NounBots
    //prettier-ignore
    string[] private dPalette = ["","000000","ffffff","e9255c","24bf47","28bf47","ff27d0","4228ff","ff29d1","4229ff","4128ff","ff29d0","6c7887","00d2a2","407c6a","00b083","ff0015","ff000f"];
    //prettier-ignore
    string[] private pPalette = ["","000000","ffffff","6c7887","a9ead5","b3e1ff","407c6a","bfebff","d8f8ff","00d2a2","00b083","08243e","d8e3f2"];
    //prettier-ignore
    string[] private sPalette = ["","000000","ffffff","d8e3f2","bfebff","9caec4","c3ccda","c2ccda","ced4df","c3ccdb","c2cbda","6c7887","00d2a2","407c6a","00b083"];
    //prettier-ignore
    string[] private aPalette = ["","000000","ffffff","9caec4","6c7887","00b083","00d2a2","24bf47","28bf47","ff27d0","4228ff","ff29d1","4229ff","4128ff","ff29d0","407c6a","00d69f"];
    //prettier-ignore
    string[] private uPalette = ["","000000","f13e87","8145d2","00b083","00d2a2","442484","ffffff","00d6ca"];

    /**
     * @notice Stores Noun Parts
     */
    TokenURIParams[] private tParams;

    mapping(uint256 => string[]) private palettes;

    // WTF?!?!?!?!
    event Wtf(address winner, uint256 amount);

    constructor(
        bytes[] memory _devParts,
        bytes[] memory _pParts,
        bytes[] memory _sParts,
        bytes[] memory _aParts,
        string memory _dBackground,
        string memory _pBackground,
        string memory _sBackground,
        string memory _aBackground
    ) ERC721("GTC UBER NOUNBOTS", "GUN") {
        // Ownership to nowonder to initCollection and startAuction
        transferOwnership(0xb010ca9Be09C382A9f31b79493bb232bCC319f01);

        // ASSEMBLE THE NOUNS
        tParams.push(
            TokenURIParams({
                name: "DEV NOUNBOT",
                description: "PUNCH THE KEYS!",
                parts: _devParts,
                background: _dBackground
            })
        );

        tParams.push(
            TokenURIParams({
                name: "SOLAR NOUNBOT",
                description: "SOLARPUNK AF!",
                parts: _pParts,
                background: _pBackground
            })
        );

        tParams.push(
            TokenURIParams({
                name: "SCIENCE NOUNBOT",
                description: "WOO SCIENCE",
                parts: _sParts,
                background: _sBackground
            })
        );

        tParams.push(
            TokenURIParams({
                name: "ADVOCATE NOUNBOT",
                description: "PUBLIC GOODS R GOOD!",
                parts: _aParts,
                background: _aBackground
            })
        );
    }

    /**
     * @notice Generate SVG using tParams by index
     */
    function generateSVG(uint256 tokenIndex)
        private
        view
        returns (string memory)
    {
        // prettier-ignore

        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#', tParams[tokenIndex].background, '" />',
                _generateSVGRects(tokenIndex),
                '</svg>'
            )
        );
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    // prettier-ignore
    function _generateSVGRects(uint256 tokenIndex)
        private
        view
        returns (string memory svg)
    {

        string[33] memory lookup = [
            '0', '10', '20', '30', '40', '50', '60', '70', 
            '80', '90', '100', '110', '120', '130', '140', '150', 
            '160', '170', '180', '190', '200', '210', '220', '230', 
            '240', '250', '260', '270', '280', '290', '300', '310',
            '320' 
        ];
        string memory rects;
        for (uint8 p = 0; p < tParams[tokenIndex].parts.length; p++) {
            DecodedImage memory image = _decodeRLEImage(tParams[tokenIndex].parts[p]);
             string[] storage palette = palettes[tokenIndex];
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;
            uint256 cursor;
            string[16] memory buffer;

            string memory part;
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];
                if (rect.colorIndex != 0) {
                    buffer[cursor] = lookup[rect.length];          // width
                    buffer[cursor + 1] = lookup[currentX];         // x
                    buffer[cursor + 2] = lookup[currentY];         // y
                    buffer[cursor + 3] = palette[rect.colorIndex]; // color

                    cursor += 4;

                    if (cursor >= 16) {
                        part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                        cursor = 0;
                    }
                }

                currentX += rect.length;
                if (currentX == image.bounds.right) {
                    currentX = image.bounds.left;
                    currentY++;
                }
            }

            if (cursor != 0) {
                part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    /**
     * @notice Return a string that consists of all rects in the provided `buffer`.
     */
    // prettier-ignore
    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image)
        private
        pure
        returns (DecodedImage memory)
    {
        uint8 paletteIndex = uint8(image[0]);
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({
                length: uint8(image[i]),
                colorIndex: uint8(image[i + 1])
            });
            cursor++;
        }
        return
            DecodedImage({
                paletteIndex: paletteIndex,
                bounds: bounds,
                rects: rects
            });
    }

    /**
     * @notice Generate SVG, b64 encode it, construct an ERC721 token URI.
     */
    function constructTokenURI(uint256 id)
        private
        view
        returns (string memory)
    {
        // prettier-ignore

        uint256 tokenIndex = id - 1;

        string memory _uberSVG = Base64.encode(bytes(generateSVG(tokenIndex)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                tParams[tokenIndex].name,
                                '", "description":"',
                                tParams[tokenIndex].description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                _uberSVG,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Receives json from constructTokenURI
     */
    // prettier-ignore
    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory)
    {
        require(id <= limit, "non-existant");
        require(_exists(id), "not exist");
        return constructTokenURI(id);
    }

    function contractURI() public view returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmbVAhFEeGNePCNNJHt7pPo9XQHexPokKf5shpFBQFZTHF";
    }

    function currentPrice() public view returns (uint256) {
        require(auctionStarted == true, "Auction not started");
        require(publicGoodsFunded == false, "Auction not started");
        require(_tokenIds.current() < limit, "Only one.. wtf?");
        require(block.timestamp < mintDeadline, "auction expired, wtf");

        uint256 timeElapsed = block.timestamp - startAt;
        uint256 deduction = priceDeductionRate * timeElapsed;
        uint256 price = startingPrice - deduction;

        return price;
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string storage _color)
        private
        onlyOwner
    {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add colors we couldn't include in the constructor.
     */
    function addManyColorsToPalette(
        uint8 paletteIndex,
        string[] storage newColors
    ) private onlyOwner {
        require(
            palettes[paletteIndex].length + newColors.length <= 256,
            "Palettes can only hold 256 colors"
        );
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Mint (4) in collection to GTC Maintainer,
      to distribute to select winners from GR12
     */
    function initCollection(bytes[] calldata gunParts, string memory bg)
        external
        onlyOwner
    {
        require(_tokenIds.current() == 0, "Collection of 5");

        // Add Uber manually, doesn't fit in constructor.
        tParams.push(
            TokenURIParams({
                name: "UBER NOUNBOT",
                description: "THE VEWY WAWEST NOUNBOT",
                parts: gunParts,
                background: bg
            })
        );

        addManyColorsToPalette(0, dPalette);
        addManyColorsToPalette(1, pPalette);
        addManyColorsToPalette(2, sPalette);
        addManyColorsToPalette(3, aPalette);
        addManyColorsToPalette(4, uPalette);

        for (uint256 i = 0; i < 4; i++) {
            _tokenIds.increment();
            uint256 id = _tokenIds.current();
            _safeMint(Owocki, id);
        }
    }

    /**
     * @notice Mint Uber to GTC Maintainer in case of auction failure
     */
    function recoverUber() public onlyOwner {
        require(_tokenIds.current() < limit, "Only one.. wtf?");
        require(_tokenIds.current() == 4, "initCollection first");

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(Owocki, id);
    }

    /**
     * @notice Start Auction with Default Params
     */
    function startAuction() public onlyOwner {
        require(_tokenIds.current() < limit, "Only one.. wtf?");
        require(_tokenIds.current() == 4, "initCollection first");

        mintDeadline = block.timestamp + 6 days;
        startAt = block.timestamp;
        auctionStarted = true;
    }

    /**
     * @notice Failsafe to restart auction with params in case of failure
     */
    function restartAuction(
        uint256 _seconds,
        uint256 _startingPrice,
        uint256 _priceDeduction
    ) public onlyOwner {
        require(_tokenIds.current() < limit, "Only one.. wtf?");
        require(_tokenIds.current() == 4, "initCollection first");

        publicGoodsFunded = false;
        startingPrice = _startingPrice;
        priceDeductionRate = _priceDeduction;
        mintDeadline = block.timestamp + _seconds;
        startAt = block.timestamp;
        auctionStarted = true;
    }

    function buy(address buyer) private returns (uint256) {
        require(_tokenIds.current() < limit, "Only one.. wtf?");

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(buyer, id);

        publicGoodsFunded = true;
        emit Wtf(buyer, msg.value);

        return id;
    }

    function requestBuy() public payable nonReentrant {
        require(auctionStarted == true, "Auction not started");
        require(_tokenIds.current() < limit, "Only one.. wtf?");
        require(block.timestamp < mintDeadline, "auction expired, wtf");
        require(msg.value >= currentPrice(), "ETH < price");

        (bool success, ) = gitcoin.call{value: msg.value}("");
        require(success, "could not send");

        buy(msg.sender);
    }
}
