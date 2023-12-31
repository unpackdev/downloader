// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Strings.sol";
import "./Base64.sol";

import "./NFTIMEArt.sol";
import "./NFTIME.sol";

///
/// ███╗   ██╗███████╗████████╗██╗███╗   ███╗███████╗              ███╗   ███╗███████╗████████╗ █████╗ ██████╗  █████╗ ████████╗ █████╗
/// ████╗  ██║██╔════╝╚══██╔══╝██║████╗ ████║██╔════╝              ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗
/// ██╔██╗ ██║█████╗     ██║   ██║██╔████╔██║█████╗      █████╗    ██╔████╔██║█████╗     ██║   ███████║██║  ██║███████║   ██║   ███████║
/// ██║╚██╗██║██╔══╝     ██║   ██║██║╚██╔╝██║██╔══╝      ╚════╝    ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║  ██║██╔══██║   ██║   ██╔══██║
/// ██║ ╚████║██║        ██║   ██║██║ ╚═╝ ██║███████╗              ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██████╔╝██║  ██║   ██║   ██║  ██║
/// ╚═╝  ╚═══╝╚═╝        ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝              ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
///
/// @title NFTIMEMetadata
/// @author https://nftxyz.art/ (Olivier Winkler)
/// @notice Metadata Library
/// @custom:security-contact abc@nftxyz.art
library NFTIMEMetadata {
    /*//////////////////////////////////////////////////////////////
                                PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Render the JSON Metadata for a given token.
    /// @param _date Token's NFTIME.Date Struct.
    /// @return Returns base64 encoded metadata file.
    function generateTokenURI(NFTIME.Date memory _date, bool _isMinute) public pure returns (string memory) {
        bytes memory _svg = NFTIMEArt.generateSVG(_date, _isMinute);
        string memory _name = _isMinute
            ? string.concat(_date.day, " ", _date.month, " ", _date.year, " ", _date.hour, ":", _date.minute)
            : string.concat(_date.day, " ", _date.month, " ", _date.year);

        /// forgefmt: disable-start
        bytes memory _metadata = abi.encodePacked(
            "{",
                '"name": "',
                _name,
                '",',
                '"description": "Collect your NFTIME. Mint your day. Mint your minute.",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(_svg),
                    '",',
                '"attributes": [', 
                    _getAttributes(_date, _isMinute),
                "]",
            "}"
        );
        /// forgefmt: disable-end

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(_metadata)));
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Generate all Attributes
    /// @param _date Token's NFTIME.Date Struct.
    /// @param _isMinute bool.
    /// @return Returns base64 encoded attributes.
    function _getAttributes(NFTIME.Date memory _date, bool _isMinute) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _getTrait("Year", _date.year, ","),
            _getTrait("Month", _date.month, ","),
            _getTrait("Day", _date.day, ","),
            _getTrait("Type", _isMinute ? "MINUTE" : "DAY", ","),
            _isMinute ? _getTrait("Week Day", _date.dayOfWeek, ",") : "",
            _isMinute ? _getTrait("Hour", _date.hour, ",") : "",
            _isMinute ? _getTrait("Minute", _date.minute, ",") : "",
            _getTrait("Rarity", "false", "")
        );
    }

    /// @dev Generate the SVG snipped for a single attribute.
    /// @param traitType The `trait_type` for this trait.
    /// @param traitValue The `value` for this trait.
    /// @param append Helper to append a comma.
    function _getTrait(
        string memory traitType,
        string memory traitValue,
        string memory append
    )
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked("{", '"trait_type": "', traitType, '",' '"value": "', traitValue, '"' "}", append));
    }
}
