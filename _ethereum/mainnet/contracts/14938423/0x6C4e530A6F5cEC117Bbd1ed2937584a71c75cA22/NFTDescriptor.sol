// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "base64.sol";
import "utils.sol";

/// @title NFTDescriptor
/// @author chalex.eth - CharlieDAO
/// @notice Library for rendering the NFT by returning a SVG code associated to a locked position in TrueFreezeGovernor

library NFTDescriptor {
    struct paramsTokenURI {
        string n1;
        string n2;
        string n3;
        string y1;
        string m1;
        string d1;
        string y2;
        string m2;
        string d2;
    }

    /// @dev main function for constructing the tokenURI
    function _constructTokenURI(
        uint256 _amountLocked,
        uint256 _lockingDate,
        uint256 _maturityDate
    ) internal pure returns (string memory) {
        paramsTokenURI memory params = _constructParamsTokenURI(
            _amountLocked,
            _lockingDate,
            _maturityDate
        );

        string memory imageURI = Base64.encode(bytes(generateSVG(params)));
        string memory attributes = generateAttributes(
            _amountLocked,
            _lockingDate,
            _maturityDate
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "TrueFreeze NFT",
                                '", "description":"This NFT represent a locked position in TrueFreeze protocol", "image":"',
                                "data:image/svg+xml;base64,",
                                imageURI,
                                '","attributes": ',
                                attributes,
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function _constructParamsTokenURI(
        uint256 _amountLocked,
        uint256 _lockingDate,
        uint256 _maturityDate
    ) internal pure returns (paramsTokenURI memory) {
        (uint256 n1, uint256 n2, uint256 n3) = Utils.getIntAndDigit(
            _amountLocked
        );
        (uint256 y1, uint256 m1, uint256 d1) = Utils.timestampToDate(
            _lockingDate
        );
        (uint256 y2, uint256 m2, uint256 d2) = Utils.timestampToDate(
            _maturityDate
        );

        string memory sm1;
        string memory sm2;
        string memory sd1;
        string memory sd2;
        if (m1 < 10) {
            sm1 = string(abi.encodePacked("0", Utils.uint2str(m1)));
        } else {
            sm1 = Utils.uint2str(m1);
        }

        if (m2 < 10) {
            sm2 = string(abi.encodePacked("0", Utils.uint2str(m2)));
        } else {
            sm2 = Utils.uint2str(m2);
        }

        if (d1 < 10) {
            sd1 = string(abi.encodePacked("0", Utils.uint2str(d1)));
        } else {
            sd1 = Utils.uint2str(d1);
        }

        if (d2 < 10) {
            sd2 = string(abi.encodePacked("0", Utils.uint2str(d2)));
        } else {
            sd2 = Utils.uint2str(d2);
        }

        return
            paramsTokenURI({
                n1: Utils.uint2str(n1),
                n2: Utils.uint2str(n2),
                n3: Utils.uint2str(n3),
                y1: Utils.uint2str(y1),
                m1: sm1,
                d1: sd1,
                y2: Utils.uint2str(y2),
                m2: sm2,
                d2: sd2
            });
    }

    function generateAttributes(
        uint256 _amountLocked,
        uint256 _lockingDate,
        uint256 _maturityDate
    ) internal pure returns (string memory attributes) {
        (uint256 n1, uint256 n2, uint256 n3) = Utils.getIntAndDigit(
            _amountLocked
        );
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "Amount locked", "value":',
                    Utils.uint2str(n1),
                    ".",
                    Utils.uint2str(n2),
                    Utils.uint2str(n3),
                    '},{"display_type": "date", "trait_type": "Locking date", "value":',
                    Utils.uint2str(_lockingDate),
                    '},{"display_type": "date", "trait_type": "Maturity date", "value":',
                    Utils.uint2str(_maturityDate),
                    "}]"
                )
            );
    }

    function generateSVG(paramsTokenURI memory _params)
        internal
        pure
        returns (string memory svg)
    {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 400 500">',
                    generateStyle(),
                    generateLinearGradient(),
                    generateAmountLocked(_params),
                    generateMiddle(),
                    generateMaturity(_params),
                    generateLocking(_params),
                    generateBottom()
                )
            );
    }

    function generateStyle() internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    "<style>    @import url(&apos;https://fonts.googleapis.com/css2?family=Montserrat&apos;);",
                    ".background {      fill: url(&quot;#linear-gradient&quot;);    }",
                    ".snowflake-logo {      fill: #fff;    }    .logo-text {      fill: #fff;",
                    "font-family: Montserrat, sans-serif;      font-size: 25px;    }",
                    ".amount-text {    fill: #d8b98d;    font-family: Montserrat, sans-serif;    font-size: 55px;    }",
                    ".date-text {    fill: #d8b98d;    font-family: Montserrat, sans-serif;    font-size: 30px;    }",
                    ".date-label {    fill: #8dbdd8;    font-family: Montserrat, sans-serif;    font-size: 20px;    }",
                    ".gradient-box {      fill: none;      stroke-miterlimit: 10;      stroke-width: 3px;",
                    "stroke: url(&quot;#linear-gradient&quot;);    }",
                    ".gradient-border {    fill: none;    stroke-miterlimit: 10;    stroke-width: 1px;    stroke: #bdbec5;    }  </style>"
                )
            );
    }

    function generateLinearGradient()
        internal
        pure
        returns (string memory svg)
    {
        return
            string(
                abi.encodePacked(
                    '<linearGradient id="linear-gradient" x1="0" y1="500" x2="250" y2="100" gradientUnits="userSpaceOnUse">',
                    '<stop offset="0" stop-color="#bdbec5"/>    <stop offset="0.5" stop-color="#547181"/>',
                    '<stop offset="1" stop-color="#4b4c4e"/>  </linearGradient>',
                    '<rect class="background" width="400" height="500" rx="20"/><g transform="translate(0,50)">',
                    '<g>      <linearGradient y1="50" x2="350" y2="50" gradientUnits="userSpaceOnUse">',
                    '<stop offset="0" stop-color="#bdbec5"/>        <stop offset="1" stop-color="#4b4c4e"/>      </linearGradient>'
                )
            );
    }

    function generateAmountLocked(paramsTokenURI memory _params)
        internal
        pure
        returns (string memory svg)
    {
        return
            string(
                abi.encodePacked(
                    '<rect class="gradient-border" x="50" y="10" width="300" height="100" rx="20" transform="translate(0,0)"/>',
                    '<text text-anchor="end" class="amount-text" x="345" y="70">',
                    _params.n1,
                    ".",
                    _params.n2,
                    _params.n3,
                    "</text>",
                    '<text text-anchor="middle" class="date-label" x="200" y="100">',
                    "WETH</text>    </g>"
                )
            );
    }

    function generateMiddle() internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '<g><linearGradient y1="50" x2="350" y2="50" gradientUnits="userSpaceOnUse">',
                    '<stop offset="0" stop-color="#bdbec5"/><stop offset="1" stop-color="#4b4c4e"/></linearGradient>',
                    '<rect class="gradient-border" x="75" y="120" width="250" height="90" rx="20" transform="translate(0,0)"/>'
                )
            );
    }

    function generateMaturity(paramsTokenURI memory _params)
        internal
        pure
        returns (string memory svg)
    {
        return
            string(
                abi.encodePacked(
                    '<text text-anchor="middle" class="date-text" x="200" y="165">',
                    _params.y2,
                    "-",
                    _params.m2,
                    "-",
                    _params.d2,
                    '</text>      <text text-anchor="middle" class="date-label" x="200" y="200">',
                    "Maturity Date</text>"
                )
            );
    }

    function generateLocking(paramsTokenURI memory _params)
        internal
        pure
        returns (string memory svg)
    {
        return
            string(
                abi.encodePacked(
                    '<rect class="gradient-border" x="75" y="220" width="250" height="90" rx="20" transform="translate(0,0)"/>',
                    '<text text-anchor="middle" class="date-text" x="200" y="265">',
                    _params.y1,
                    "-",
                    _params.m1,
                    "-",
                    _params.d1,
                    '</text>      <text text-anchor="middle" class="date-label" x="200" y="300">',
                    "Lock Date </text>    </g>  </g>"
                )
            );
    }

    function generateBottom() internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '<g transform="translate(10,420)">',
                    '<path class="snowflake-logo" d="M19.41,5.77l-3.47,4.89L12.46,5.77,15.94,0ZM7.54,7.53l1.2,4.88,',
                    "4.41.74-.74-4.41ZM0,15.93l5.77,3.48,4.89-3.48L5.77,12.45Zm7.53,8.4,      4.88-1.2.74-4.42-4.41.75Zm8.4,7.54,3.48-5.77-3.48-4.89L12.45,",
                    '26.1Zm8.4-7.53-1.2-4.88-4.42-.74.75,4.41Zm7.54-8.4L26.1,      12.46l-4.89,3.48,4.89,3.47Zm-7.53-8.4-4.88,1.2-.74,4.41,4.41-.74Z"/>',
                    '<text class="logo-text" x="40" y="25"> TRUE FREEZE        </text>  </g></svg>'
                )
            );
    }
}
