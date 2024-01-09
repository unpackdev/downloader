// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./base64.sol";

/**
* sarape NFT, 2021-12-29.
* ----------------------------------------------------------------------------
* Crafted following centuries-old traditional Mexican design and artisanal
* aesthetics, "sarape original" is a limited edition NFT collection generated
* 100% on-chain. Each sarape token is a truly unique (1/1) digital artwork.
* Only 256 tokens will be minted and exist forever in the ethereum blockchain.
* ----------------------------------------------------------------------------
*/

// Interfaces
interface Colorverse {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenNameById(uint256 tokenId) external view returns (string memory);
}

contract sarapeNFT is ERC721Enumerable {

    // Global variables

    /// Constants
    uint256 constant public MAX_SUPPLY = 256;
    uint256 constant public MAX_CLAIM_SUPPLY = 64;
    uint256 constant public LAST_ITEMS_SUPPLY = 32;
    uint256 constant public OWNER_MAX_CLAIM = 1;

    uint256 constant public INITIAL_PRICE = 16 * (10 ** 15);    //// 0.016 ether
    uint256 constant public FINAL_PRICE = 8 * (10 ** 16);       //// 0.080 ether

    /// Addresses
    address public immutable ARTIST_ADDRESS;
    address public COLORVERSE_ADDRESS;

    /// Minting
    uint256 public nextId;
    mapping(string => bool) public _colorPairExists;
    mapping(string => bool) public _invertedColorPairExists;
    mapping(address => bool) public _addressClaimedToken;

    /// Struct: sarape traits (color pair, minter)
    struct sarapeTraits {
        uint256 _c1;
        uint256 _c2;
        address _mintedBy;
    }
    mapping(uint256 => sarapeTraits) _sarapeTraits;

    /// Struct: claimed token color name status
    struct claimedTokenStatus {
        string _claimedTokenName;
        bool _isNamed;
    }

    /// Struct: parameters for svg rectangles
    struct rectParams {
        uint256 _x;
        uint256 _y;
        uint256 _w;
        uint256 _h;
        uint256 _f;
    }

    constructor() ERC721("sarape NFT", "SARP")
    {
        ARTIST_ADDRESS = 0x033301034e6d80dEf56d37F270e0DeE29F92ed3a;
        COLORVERSE_ADDRESS = 0xfEe27FB71ae3FEEEf2c11f8e02037c42945E87C4;
        nextId = 1;
    }

    // Public functions

    /// returns the current price
    function getCurrentPrice() public view returns (uint256 currentPrice) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply < MAX_CLAIM_SUPPLY) {
            currentPrice = 0;
        } else if (_totalSupply >= MAX_CLAIM_SUPPLY && _totalSupply < (MAX_SUPPLY - LAST_ITEMS_SUPPLY)) {
            currentPrice = INITIAL_PRICE;
        } else if (_totalSupply >= (MAX_SUPPLY - LAST_ITEMS_SUPPLY)) {
            currentPrice = FINAL_PRICE;
        }
    }

    /// returns the sarape color pair
    function sarapeColorPair(uint256 tokenId) public view returns (uint256, uint256) {
        require(_exists(tokenId), "Nonexistent token.");
        sarapeTraits storage st = _sarapeTraits[tokenId];
        return (st._c1, st._c2);
    }

    /// returns the sarape minter address
    function sarapeMintedBy(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Nonexistent token.");
        sarapeTraits storage st = _sarapeTraits[tokenId];
        return Strings.toHexString(uint256(uint160(st._mintedBy)));
    }

    /// returns sarape svg string
    function sarapeSVG(uint256 tokenId, bool viewBox) public view returns (string memory _sarapeSVG) {

        require(_exists(tokenId), "SVG query for nonexistent token.");

        sarapeTraits storage st = _sarapeTraits[tokenId];
        claimedTokenStatus memory _claimedToken = colorTokenNames(st._c1, st._c2);
        string memory svg;

        //// optionally, generate svg without a specified background color
        //// and with viewBox instead of fixed width and height (e.g. for website display)
        if (viewBox == true) {
            svg = "<svg viewBox='0 0 1080 1960' xmlns='http://www.w3.org/2000/svg'>";
        } else {
            svg = "<svg width='1080' height='1960' xmlns='http://www.w3.org/2000/svg' style='background-color:#808080'>";
        }

        //// set the sarape name string: if the token was claimed, get the color names, otherwise use the color hex codes
        string memory _sarapeName;
        if (tokenId <= MAX_CLAIM_SUPPLY) {
            _sarapeName = _claimedToken._claimedTokenName;
        } else {
            _sarapeName = string(abi.encodePacked(hexColor(st._c1), ".", hexColor(st._c2)));
        }

        //// Block scoping sarape sections to prevent 'stack too deep' error

        {   //// rainbow pattern, main sections
            uint256[39] memory _rainbow = rainbow(st._c1, st._c2);
            uint256[4] memory _ycoord = [uint256(291), 675, 1059, 1442];
            for(uint256 i = 0; i < _ycoord.length; i++) {
                for(uint256 ii = 0; ii < _rainbow.length; ii++) {
                    uint256 _y = _ycoord[i] + (ii * 4);
                    uint256 _f = _rainbow[ii];
                    string memory svgR = rectStr(rectParams(90, _y, 900, 4, _f));
                    svg = string(abi.encodePacked(svg, svgR));
                }
            }
        }

        {   //// intermediate sections
            uint256[7] memory _rainbowInter = [st._c1, accessoryInt(st._c1), 16777215, 0, 16777215, accessoryInt(st._c2), st._c2];
            uint256[3] memory _ycoordInter = [uint256(547), 931, 1314];
            for(uint256 i = 0; i < _ycoordInter.length; i++) {
                for(uint256 ii = 0; ii < _rainbowInter.length; ii++) {
                    uint256 _y = _ycoordInter[i] + (ii * 4);
                    uint256 _f = _rainbowInter[ii];
                    string memory svgRint = rectStr(rectParams(90, _y, 900, 4, _f));
                    svg = string(abi.encodePacked(svg, svgRint));
                }
            }
        }

        {   //// band pattern (black) , main sections
            uint256[8] memory _ycoordMain = [uint256(191), 447, 575, 831, 959, 1214, 1342, 1598];
            for(uint256 i = 0; i < _ycoordMain.length; i++) {
                string memory svgRmain = rectStr(rectParams(90, _ycoordMain[i], 900, 100, 0));
                svg = string(abi.encodePacked(svg, svgRmain));
            }
        }

        {   //// dotted pattern (black), main sections
            string memory svgDot1 = "<line x1='91' x2='989' y1='369' y2='369' stroke='#000000' stroke-width='10' stroke-dasharray='8,2' />";
            string memory svgDot2 = "<line x1='91' x2='989' y1='753' y2='753' stroke='#000000' stroke-width='10' stroke-dasharray='8,2' />";
            string memory svgDot3 = "<line x1='91' x2='989' y1='1137' y2='1137' stroke='#000000' stroke-width='10' stroke-dasharray='8,2' />";
            string memory svgDot4 = "<line x1='91' x2='989' y1='1520' y2='1520' stroke='#000000' stroke-width='10' stroke-dasharray='8,2' />";
            svg = string(abi.encodePacked(svg, svgDot1, svgDot2, svgDot3, svgDot4));
        }

        {   //// frame (white), fringe
            string memory svgRfringetopfirst = "<rect x='90' y='145' width='2' height='46' fill='#ffffff'/>";
            string memory svgRfringebotfirst = "<rect x='90' y='1698' width='2' height='46' fill='#ffffff'/>";
            string memory svgLfringetop = "<line x1='120' x2='990' y1='168' y2='168' stroke='#ffffff' stroke-width='46' stroke-dasharray='2,29' />";
            string memory svgLfringebot = "<line x1='120' x2='990' y1='1722' y2='1722' stroke='#ffffff' stroke-width='46' stroke-dasharray='2,29' />";
            string memory svgEndtop = "<rect x='90' y='190' width='900' height='1' fill='#ffffff'/>";
            string memory svgEndbot = "<rect x='90' y='1698' width='900' height='1' fill='#ffffff'/>";
            svg = string(abi.encodePacked(svg, svgLfringetop, svgLfringebot, svgRfringetopfirst, svgRfringebotfirst, svgEndtop, svgEndbot));
        }

        {   //// token Id and token name (sarape title)
            string memory _svgTokenTitle = string(abi.encodePacked(
                "<text x='540px' y='1940px' fill='#f0f0f0' font-family='AndaleMono, Andale Mono, monospace' font-size='16px' text-anchor='middle' text-rendering='optimizeLegibility'>sarape ",
                Strings.toString(tokenId), "   |   ", '"', _sarapeName, '"', "   |   1/1</text>"
            ));
            svg = string(abi.encodePacked(svg, _svgTokenTitle, "</svg>"));
        }

        //// sarape svg string
        return svg;

    }

    /// returns sarape metadata: Base64 encoded ERC721 Metadata JSON Schema [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md]
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        require(_exists(tokenId), "URI query for nonexistent token.");

        sarapeTraits storage st = _sarapeTraits[tokenId];

        claimedTokenStatus memory _claimedToken = colorTokenNames(st._c1, st._c2);
        string memory _claimedTokenName = _claimedToken._claimedTokenName;
        bool _isNamed = _claimedToken._isNamed;
        string memory _traitSarapeName;

        string memory _traitColor1 = string(abi.encodePacked('#', hexColor(st._c1)));
        string memory _traitColor2 = string(abi.encodePacked('#', hexColor(st._c2)));
        string memory _traitTitle;
        string memory _traitMintedBy = sarapeMintedBy(tokenId);
        string memory _svg = sarapeSVG(tokenId, false);

        if (tokenId <= MAX_CLAIM_SUPPLY && _isNamed == true) {
            _traitSarapeName = _claimedTokenName;
            _traitTitle = 'color names';
        } else {
            _traitSarapeName = string(abi.encodePacked(hexColor(st._c1), '.', hexColor(st._c2)));
            _traitTitle = 'color hex codes';
        }

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "',
                                _traitSarapeName,
                                '","description": "Traditional. Original. Unique. Generated 100% on-chain.","image": "data:image/svg+xml;base64,',
                                Base64.encode(bytes(_svg)),
                                '","attributes": [{"trait_type": "Color 1", "value": "',
                                _traitColor1,
                                '"},{"trait_type": "Color 2","value": "',
                                _traitColor2,
                                '"},{"trait_type": "Title pattern","value": "',
                                _traitTitle,
                                '"},{"trait_type": "Minted by","value": "',
                                _traitMintedBy,
                                '"}]}'
                            )
                        )
                    )
                )
        );

    }

    /// returns the url for the contract metadata (JSON) [https://docs.opensea.io/docs/contract-level-metadata]
    function contractURI() public view returns (string memory) {
        return "https://sarape.io/nft/contract-metadata.json";
    }


    // External functions

    /// mints a token for the current price
    function mint(uint256 _c1, uint256 _c2) external payable {

        require(_c1 < 16777216 && _c2 < 16777216, "24-bit color exceeded.");

        string memory _colorPair = string(abi.encodePacked(Strings.toString(_c1), '.', Strings.toString(_c2)));
        string memory _invertedColorPair = string(abi.encodePacked(Strings.toString(_c2), '.', Strings.toString(_c1)));
        require(!_colorPairExists[_colorPair] && !_invertedColorPairExists[_invertedColorPair], "Color pair already used.");

        if (totalSupply() < MAX_CLAIM_SUPPLY) {
            require(!_addressClaimedToken[msg.sender], "Only one token per address can be claimed.");
            require(msg.sender == Colorverse(COLORVERSE_ADDRESS).ownerOf(_c1), "Address does not own color.");
            require(msg.sender == Colorverse(COLORVERSE_ADDRESS).ownerOf(_c2), "Address does not own color.");
            _addressClaimedToken[msg.sender] = true;
        } else {
            require(totalSupply() < MAX_SUPPLY, "All tokens minted.");
            require(msg.value >= getCurrentPrice(), "Insufficient ETH amount.");
        }

        sarapeTraits storage st = _sarapeTraits[nextId];
        st._c1 = _c1;
        st._c2 = _c2;
        st._mintedBy = msg.sender;

        _colorPairExists[_colorPair] = true;
        _invertedColorPairExists[_invertedColorPair] = true;

        _safeMint(msg.sender, nextId);

        nextId++;

    }

    /// withdraws balance
    function withdraw() external {
        uint256 balance = address(this).balance;
        payable(ARTIST_ADDRESS).transfer(balance);
    }

    /// changes Colorverse contract address (makes this contract future proof)
    function changeColorverseContractAddress(address newAddress) external {
        require(msg.sender == ARTIST_ADDRESS, 'Only the artist can change the Colorverse contract address.');
        COLORVERSE_ADDRESS = newAddress;
    }


    // Internal functions

    /// creates rgb array from color integer value
    function rgbColor(uint256 _colorInt) internal pure returns (uint256[3] memory) {
        uint256 r = _colorInt/(256**2);
        uint256 g = (_colorInt/256)%256;
        uint256 b = _colorInt%256;
        return [r, g, b];
    }

    /// converts color integer to hex value
    function hexColor(uint256 _colorInt) internal pure returns (string memory) {
        string memory _cHex = Strings.toHexString(_colorInt, 3);
        bytes memory b = bytes(_cHex);
        return string(bytes.concat(b[2], b[3], b[4], b[5], b[6], b[7]));
    }

    /// calculates accessory color from main color
    function accessoryInt(uint256 _c) internal pure returns (uint256) {

        //// get color rgb channels
        uint256[3] memory _rgbArray = rgbColor(_c);
        uint256 r = _rgbArray[0];
        uint256 g = _rgbArray[1];
        uint256 b = _rgbArray[2];

        //// calculate green channel
        uint256 gg;
        if (r == 255 && b == 255 && g == 255) { //// exception: pure white
            gg = 255;
        } else if (r == 0 && b == 0 && g == 0) { //// exception: pure black
            gg = 0;
        } else if (g <= 128) {
            gg = 255 - g;
        } else {
            gg = 255 - g + 32;
        }

        return (r * (256 ** 2)) + (gg * 256) + b;

    }

    /// calculates color tint (lighter color tone) or shade (darker color tone)
    function tintshade(uint256 _c, uint256 _n, uint256 _s, bool _tint) internal pure returns (uint256 _tintshade) {

        //// get color rgb channels
        uint256[3] memory _rgbArray = rgbColor(_c);
        uint256 r;
        uint256 g;
        uint256 b;

        //// calculate saturation for each channel
        if (_tint == true) {
            //// tints
            r = _rgbArray[0] + (((255 - _rgbArray[0]) / _s) * _n);
            g = _rgbArray[1] + (((255 - _rgbArray[1]) / _s) * _n);
            b = _rgbArray[2] + (((255 - _rgbArray[2]) / _s) * _n);
        } else {
            //// shades
            r = _rgbArray[0] - ((_rgbArray[0] / _s) * _n);
            g = _rgbArray[1] - ((_rgbArray[1] / _s) * _n);
            b = _rgbArray[2] - ((_rgbArray[2] / _s) * _n);
        }

        //// return color integer
        _tintshade = (r * (256 ** 2)) + (g * 256) + b;

    }

    /// creates 'rainbow' array (a list of colors in the order required for the main sections)
    function rainbow(uint256 _mc1, uint256 _mc2) internal pure returns (uint256[39] memory _rainbow) {

        //// accessory colors
        uint256 _ac1 = accessoryInt(_mc1);
        uint256 _ac2 = accessoryInt(_mc2);

        //// top, main 1 shades
        uint256[8] memory _ts = [uint256(5), 7, 4, 6, 3, 5, 2, 4];
        for(uint256 i = 0; i < _ts.length; i++) {
            _rainbow[i] = tintshade(_mc1, _ts[i], 8, false);
        }

        //// top, main/accessory 1
        _rainbow[8] = _mc1;
        _rainbow[9] = _ac1;

        //// top, main/accessory 1 tints
        uint256[4] memory _tt = [uint256(1), 2, 3, 4];
        for(uint256 i = 0; i < _tt.length; i++) {
            _rainbow[10 + (i * 2)] = tintshade(_mc1, _tt[i], 6, true);
            _rainbow[11 + (i * 2)] = tintshade(_ac1, _tt[i], 5, true);
        }

        //// middle, white;
        for(uint256 i = 18; i < 21; i++) {
            _rainbow[i] = uint256(16777215);
        }

        //// bottom, accessory/main 2 tints
        uint256[4] memory _bt = [uint256(4), 3, 2, 1];
        for(uint256 i = 0; i < _bt.length; i++) {
            _rainbow[21 + (i * 2)] = tintshade(_ac2, _bt[i], 5, true);
            _rainbow[22 + (i * 2)] = tintshade(_mc2, _bt[i], 6, true);
        }

        //// bottom accessory/main 2
        _rainbow[29] = _ac2;
        _rainbow[30] = _mc2;

        //// bottom, main 2 shades
        uint256[8] memory _bs = [uint256(4), 2, 5, 3, 6, 4, 7, 5];
        for(uint256 i = 0; i < _bs.length; i++) {
            _rainbow[31 + i] = tintshade(_mc2, _bs[i], 8, false);
        }

        return _rainbow;

    }

    /// generates svg rectangle string from template
    function rectStr(rectParams memory _r) internal pure returns (string memory _rect) {

        //// parameters
        string memory _x = Strings.toString(_r._x);
        string memory _y = Strings.toString(_r._y);
        string memory _w = Strings.toString(_r._w);
        string memory _h = Strings.toString(_r._h);
        string memory _f = hexColor(_r._f);

        //// string template
        _rect = string(abi.encodePacked("<rect x='", _x, "' y='", _y, "' width='", _w, "' height='", _h, "' fill='#", _f, "'/>"));

    }

    /// returns the name string for the sarape token name
    function colorTokenNames(uint256 _c1, uint256 _c2) internal view returns (claimedTokenStatus memory) {

        //// get color token names and set function variables
        string memory _c1ColorName = Colorverse(COLORVERSE_ADDRESS).tokenNameById(_c1);
        string memory _c2ColorName = Colorverse(COLORVERSE_ADDRESS).tokenNameById(_c2);

        string memory _claimedTokenName;
        bool _isNamed;

        //// temp variables to check if the color is named(i.e. color name length > 0)
        bytes memory _c1temp = bytes(_c1ColorName);
        bytes memory _c2temp = bytes(_c2ColorName);

        //// if the colors are not named, use the color hex codes for the token name
        if  (_c1temp.length != 0 && _c2temp.length != 0) {
            _claimedTokenName = string(abi.encodePacked(_c1ColorName, ', ', _c2ColorName));
            _isNamed = true;
        } else {
            _claimedTokenName = string(abi.encodePacked(hexColor(_c1), ".", hexColor(_c2)));
            _isNamed = false;
        }

        return claimedTokenStatus(_claimedTokenName, _isNamed);

    }

}
