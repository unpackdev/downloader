// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Strings.sol";

import "./NFTIME.sol";

///
/// ███╗   ██╗███████╗████████╗██╗███╗   ███╗███████╗               █████╗ ██████╗ ████████╗
/// ████╗  ██║██╔════╝╚══██╔══╝██║████╗ ████║██╔════╝              ██╔══██╗██╔══██╗╚══██╔══╝
/// ██╔██╗ ██║█████╗     ██║   ██║██╔████╔██║█████╗      █████╗    ███████║██████╔╝   ██║
/// ██║╚██╗██║██╔══╝     ██║   ██║██║╚██╔╝██║██╔══╝      ╚════╝    ██╔══██║██╔══██╗   ██║
/// ██║ ╚████║██║        ██║   ██║██║ ╚═╝ ██║███████╗              ██║  ██║██║  ██║   ██║
/// ╚═╝  ╚═══╝╚═╝        ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝              ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
///
/// @title NFTIMEArt
/// @author https://nftxyz.art/ (Olivier Winkler)
/// @notice Art Render Library
/// @custom:security-contact abc@nftxyz.art
library NFTIMEArt {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    string private constant STYLES =
        '<defs><style>@font-face { font-family:"HelveticaNowDisplayMd";src: url("data:application/font-woff2;base64,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")}.container { height: 100%; display: flex; align-items: center; justify-content: center; }p { font-family: "HelveticaNowDisplayMd"; color: white; margin: 0; }@keyframes rotation { from { transform: rotate(0deg); transform-origin: 50% 50%; } to { transform: rotate(360deg); transform-origin: 50% 50%; } }#hand-s-use { animation: rotation 60s infinite steps(60); }</style></defs>';

    string private constant PATH_SMALL_DATE_OUTLINE =
        '<path fill="none" stroke="#fff" d="M350.5 745.9c0 2.2-1.8 4-4 4h-12c-2.2 0-4-1.8-4-4v-12c0-2.2 1.8-4 4-4h12c2.2 0 4 1.8 4 4v12z" />';

    string private constant PATH_LINE_THROUGH =
        '<path fill="none" stroke="#000" d="M520 620h200m40 0h200M520 860h440M520 380h440M520 140h440M40 260h440"/>';

    string private constant PATH_OUTLINE =
        '<path fill="none" stroke="#fff" d="M960 220c0 11-9 20-20 20H540c-11 0-20-9-20-20V60c0-11 9-20 20-20h400c11 0 20 9 20 20v160zm0 240c0 11-9 20-20 20H540c-11 0-20-9-20-20V300c0-11 9-20 20-20h400c11 0 20 9 20 20v160zM720 700c0 11-9 20-20 20H540c-11 0-20-9-20-20V540c0-11 9-20 20-20h160c11 0 20 9 20 20v160zm240 0c0 11-9 20-20 20H780c-11 0-20-9-20-20V540c0-11 9-20 20-20h160c11 0 20 9 20 20v160zm0 240c0 11-9 20-20 20H540c-11 0-20-9-20-20V780c0-11 9-20 20-20h400c11 0 20 9 20 20v160zM480 460c0 11-9 20-20 20H60c-11 0-20-9-20-20V60c0-11 9-20 20-20h400c11 0 20 9 20 20v400zm0 480c0 11-9 20-20 20H60c-11 0-20-9-20-20V540c0-11 9-20 20-20h400c11 0 20 9 20 20v400z" />';

    string private constant GROUP_COLON =
        '<g fill="#fff"><circle class="st0" cx="739.6" cy="595.5" r="8.8" /><circle class="st0" cx="739.6" cy="644.5" r="8.8" /></g>';

    string private constant PATH_CLOCK_MINUTES =
        '<path stroke="white" d="M310.221 542.499l-2.202-21.116M255.679 23.401l2.202 21.116M310.221 23.401l-2.202 21.116M255.679 542.499l2.202-21.116M228.658 27.604l4.504 20.816M337.242 538.296l-4.404-20.816M202.338 34.71l6.505 20.215M363.662 531.19l-6.605-20.215M389.181 521.483l-8.706-19.515M176.819 44.517l8.606 19.415M436.418 494.162l-12.51-17.213M129.582 71.838l12.51 17.213M108.366 89.051l14.211 15.813M457.634 476.949l-14.311-15.812M89.051 108.366l15.813 14.211M476.949 457.634l-15.813-14.311M71.838 129.582l17.213 12.51M494.162 436.418l-17.213-12.51M521.483 389.181l-19.515-8.706M44.517 176.819l19.415 8.606M34.71 202.338l20.215 6.505M531.19 363.662l-20.215-6.605M538.296 337.242l-20.816-4.404M27.604 228.658l20.816 4.504M542.499 310.221l-21.116-2.202M23.401 255.679l21.116 2.202M23.401 310.221l21.116-2.202M542.499 255.679l-21.116 2.202M27.604 337.242l20.816-4.404M538.296 228.658l-20.816 4.504M34.71 363.662l20.215-6.605M531.19 202.338l-20.215 6.505M63.932 380.475l-19.415 8.706M521.483 176.819l-19.515 8.606M494.162 129.582l-17.213 12.51M71.838 436.418l17.213-12.51M476.949 108.366l-15.813 14.211M89.051 457.634l15.813-14.311M457.634 89.051l-14.311 15.813M108.366 476.949l14.211-15.812M129.582 494.162l12.51-17.213M436.418 71.838l-12.51 17.213M176.819 521.483l8.606-19.515M389.181 44.517l-8.706 19.415M363.662 34.71l-6.605 20.215M202.338 531.19l6.505-20.215M228.658 538.296l4.504-20.816M337.242 27.604l-4.404 20.816" />';

    string private constant PATH_CLOCK_HOURS =
        '<path stroke="#fff" d="M434.716 283H544M22 283h109.184M283 434.716V544M283 22v109.184M152.5 56.927l54.542 94.572M358.858 414.401l54.642 94.672M56.927 152.5l94.572 54.542M509.073 413.5l-94.672-54.642M414.401 207.042l94.672-54.542M56.927 413.5l94.572-54.642M358.858 151.499L413.5 56.927M207.042 414.401L152.5 509.073" />';

    string private constant PATH_CLOCK_NOSE =
        '<path fill="#fff" d="M283 295.81c7.075 0 12.81-5.735 12.81-12.81s-5.735-12.81-12.81-12.81-12.81 5.735-12.81 12.81 5.735 12.81 12.81 12.81z" />';

    string private constant PATH_CLOCK_SECOND_HAND =
        '<path fill="#fff" fillRule="evenodd" id="hand-s-use" d="M284.201 283V53.224h-2.402V283l-1.001 36.928v22.618h4.404v-22.618L284.201 283z" clipRule="evenodd" />';

    string private constant PATHS_DAY_NFT =
        '<path d="M520,380H960M520,140H960M40,260H480" fill="none" stroke="#000" stroke-width="1" /><path d="M960,220a20.059,20.059,0,0,1-20,20H540a20.059,20.059,0,0,1-20-20V60a20.059,20.059,0,0,1,20-20H940a20.059,20.059,0,0,1,20,20Zm0,240a20.059,20.059,0,0,1-20,20H540a20.059,20.059,0,0,1-20-20V300a20.059,20.059,0,0,1,20-20H940a20.059,20.059,0,0,1,20,20Zm-480,0a20.059,20.059,0,0,1-20,20H60a20.059,20.059,0,0,1-20-20V60A20.059,20.059,0,0,1,60,40H460a20.059,20.059,0,0,1,20,20Z" fill="none" stroke="#fff" stroke-width="1" />';

    /*//////////////////////////////////////////////////////////////
                                PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Generate the complete SVG code for a given Token.
    /// @param _date Token's NFTIME.Date Struct.
    /// @param _isMinute bool.
    /// @return Returns base64 encoded svg file.
    function generateSVG(NFTIME.Date memory _date, bool _isMinute) public pure returns (bytes memory) {
        /// forgefmt: disable-start
        return abi.encodePacked(
            '<svg ',
                'xmlns="http://www.w3.org/2000/svg" ',
                'width="1000" ',
                'height="1000" ',
                'style="background:black;"',
            '>',
                STYLES,
                _isMinute ? _generateMinuteContent(_date) : _generateDayContent(_date),
            '</svg>'
        );
        /// forgefmt: disable-end
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Generate SVG Content of Minute NFT
    /// @param _date Token's NFTIME.Date Struct.
    /// @return Returns base64 encoded svg file.
    function _generateMinuteContent(NFTIME.Date memory _date) internal pure returns (string memory) {
        return string.concat(
            _fillDateAttributes(_date, true),
            _generateClock(_date),
            PATH_SMALL_DATE_OUTLINE,
            PATH_LINE_THROUGH,
            PATH_OUTLINE,
            GROUP_COLON
        );
    }

    /// @dev Generate SVG Content of Day NFT
    /// @param _date Token's NFTIME.Date Struct.
    /// @return Returns base64 encoded svg file.
    function _generateDayContent(NFTIME.Date memory _date) internal pure returns (string memory) {
        return string.concat(
            '<g transform="translate(0.4 240.4)">', _fillDateAttributes(_date, false), PATHS_DAY_NFT, "</g>"
        );
    }

    /// @dev Generate SVG NFT Attributes
    /// @param _date Token's NFTIME.Date Struct.
    /// @param _isMinute bool.
    /// @return Returns concated attributes.
    function _fillDateAttributes(NFTIME.Date memory _date, bool _isMinute) internal pure returns (string memory) {
        return string.concat(
            _isMinute ? _fillDateAttribute("520", "520", "200", "200", "142", _date.hour) : "",
            _isMinute ? _fillDateAttribute("760", "520", "200", "200", "142", _date.minute) : "",
            _isMinute ? _fillDateAttribute("520", "760", "200", "440", "138", _date.dayOfWeek) : "",
            _fillDateAttribute("520", "40", "200", "440", "142", _date.year),
            _fillDateAttribute("520", "280", "200", "440", "142", _date.month),
            _fillDateAttribute("40", "40", "440", "440", "360", _date.day),
            _isMinute ? _fillDateAttribute("330", "730", "20", "20", "11", _date.day) : ""
        );
    }

    /// @dev Generate SVG NFT Attribute
    /// @param _x X Position
    /// @param _y Y Posion
    /// @param _height Height
    /// @param _width Width
    /// @param _fontSize FontSize
    /// @param _value Value
    /// @return Returns attribute svg object.
    function _fillDateAttribute(
        string memory _x,
        string memory _y,
        string memory _height,
        string memory _width,
        string memory _fontSize,
        string memory _value
    )
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '<foreignObject x="',
            _x,
            '" y="',
            _y,
            '" height="',
            _height,
            '" width="',
            _width,
            '">',
            '<div xmlns="http://www.w3.org/1999/xhtml" class="container">',
            '<p style="font-size: ',
            _fontSize,
            'px;">',
            _value,
            "</p></div></foreignObject>"
        );
    }

    /// @dev Generate SVG NFT Clock
    /// @param _date Token's NFTIME.Date Struct.
    function _generateClock(NFTIME.Date memory _date) internal pure returns (string memory) {
        return string.concat(
            '<g transform="translate(60, 540)">',
            '<svg width="400" height="400" viewBox="0 0 566 566">',
            PATH_CLOCK_MINUTES,
            PATH_CLOCK_HOURS,
            PATH_CLOCK_NOSE,
            '<path fill="#fff" d="M283 139.69l-4.503 11.609V283h9.006V151.299L283 139.69z" transform="rotate(',
            _computeHourRotation(_date),
            ',283,283) translate(0,0)" id="hand-h" />',
            ' <path fill="#fff" d="M287.503 65.633L283 53.324l-4.503 12.31V282.9h9.006V65.633z" transform="rotate(',
            _computeMinuteRotation(_date.minuteUint, 6),
            ',283,283) translate(0,0)" id="hand-m" />',
            PATH_CLOCK_SECOND_HAND,
            "</svg>",
            "</g>"
        );
    }

    /// @dev Calculate rotation for minute hand
    /// @param _rotation rotation.
    /// @param _product product.
    function _computeMinuteRotation(uint256 _rotation, uint256 _product) internal pure returns (string memory) {
        return Strings.toString(_rotation * _product);
    }

    /// @dev Calculate rotation for hour hand
    /// @param _date NFTIME.Date object.
    function _computeHourRotation(NFTIME.Date memory _date) internal pure returns (string memory) {
        uint256 _factor = 10 ** 3;
        uint256 _denominator = 60;
        uint256 _hourRotation = 30;

        uint256 _quotient = _date.minuteUint * _hourRotation / _denominator;
        uint256 _remainder = (_date.minuteUint * _factor / _denominator) % _factor;

        return string.concat(Strings.toString(_date.hourUint * 30 + _quotient), ".", Strings.toString(_remainder));
    }
}
