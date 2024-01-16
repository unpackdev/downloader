// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./base64.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTSVG {
    using Strings for uint256;

    struct SVGParams {
        uint256 tokenId;
        string stableCoin;
        string token;
        string stableCoinSymbol;
        string tokenSymbol;
        string color0;
        string color1;
        string frequency;
        string tickAmount;
        string ongoing;
        string invested;
        string withdrawn;
        uint256 ticks;
        uint256 currentTicks;
    }

    function generateSVG(SVGParams memory params)
        internal
        pure
        returns (string memory svg)
    {
        /*
        address: "0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        msg: "Forged in SVG for Uniswap in 2021 by 0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        sig: "0x2df0e99d9cbfec33a705d83f75666d98b22dea7c1af412c584f7d626d83f02875993df740dc87563b9c73378f8462426da572d7989de88079a382ad96c57b68d1b",
        version: "2"
        */
        return
            string(
                abi.encodePacked(
                    generateSVGDefs(),
                    generateSVGFooter(
                        params.stableCoin,
                        params.stableCoinSymbol,
                        params.token,
                        params.tokenSymbol
                    ),
                    generateSVGBody(params),
                    generateSVGTitle(
                        params.stableCoinSymbol,
                        params.tokenSymbol,
                        params.tickAmount,
                        params.frequency
                    ),
                    generateSVGProgress(params.ticks, params.currentTicks),
                    "</svg>"
                )
            );
    }

    function generateSVGDefs() private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="400" height="500" viewBox="0 0 400 500" xmlns="http://www.w3.org/2000/svg"',
                ' xmlns:xlink="http://www.w3.org/1999/xlink">'
            )
        );
    }

    function generateSVGTitle(
        string memory stableCoinSymbol,
        string memory tokenSymbol,
        string memory tickAmount,
        string memory frequency
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<rect fill="#030303" width="400" height="167"/>',
                '<text transform="matrix(1 0 0 1 20 46)" font-size="36px" fill="white" font-family="\'Courier New\', monospace">',
                tokenSymbol,
                unicode"•",
                frequency,
                "D</text>",
                '<text transform="matrix(1 0 0 1 20 82)" fill="#B1B5C4" font-size="18px" font-family="\'Courier New\', monospace">',
                tickAmount,
                " ",
                stableCoinSymbol,
                " per period</text>"
            )
        );
    }

    function generateSVGProgress(uint256 ticks, uint256 currentTicks)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<rect x="20" y="108" fill="white" width="360" height="6"/>',
                '<rect x="20" y="108" fill="#B1E846" width="',
                ((360 * currentTicks) / ticks).toString(),
                '" height="6"/>',
                '<text transform="matrix(1 0 0 1 20 142)" font-size="18px" fill="#B1E846" font-family="\'Courier New\', monospace">',
                currentTicks.toString(),
                "/",
                ticks.toString(),
                " Periods</text>"
            )
        );
    }

    function generateSVGBody(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                generateBodyBackground(params.color0, params.color1),
                generateBodyInfo(
                    "Invested",
                    params.invested,
                    params.tokenSymbol,
                    "276"
                ),
                generateBodyInfo(
                    "Withdrawn",
                    params.withdrawn,
                    params.tokenSymbol,
                    "329"
                ),
                generateBodyInfo(
                    "Ongoing",
                    params.ongoing,
                    params.stableCoinSymbol,
                    "381"
                ),
                generateSVGTokenId(params.tokenId)
            )
        );
    }

    function generateBodyInfo(
        string memory title,
        string memory amount,
        string memory symbol,
        string memory pos
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text transform="matrix(1 0 0 1 32 ',
                pos,
                ')" fill="#B1B5C4" font-size="18px" font-family="\'Courier New\', monospace">',
                title,
                ":</text>",
                '<text transform="matrix(1 0 0 1 150 ',
                pos,
                ')" font-size="18px"  fill="white" font-family="\'Courier New\', monospace">',
                amount,
                " ",
                symbol,
                "</text>"
            )
        );
    }

    function generateBodyBackground(string memory color0, string memory color1)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<radialGradient id="SVGID_1_" cx="199.9981" cy="294.991" r="260.2305" fx="-16.3071" fy="157.6408" gradientTransform="matrix(0.9985 -5.497951e-02 6.211905e-02 1.1281 -18.0226 -26.7835)" gradientUnits="userSpaceOnUse">',
                '<stop  offset="0.2423" style="stop-color:#',
                color0,
                '"/>',
                '<stop  offset="1" style="stop-color:#',
                color1,
                '"/>',
                "</radialGradient>",
                '<rect y="167" fill="url(#SVGID_1_)" width="400" height="256"/>',
                '<path fill="#23262F" opacity="0.5" d="M380,349.9H20v39c0,6.6,5.4,12,12,12h336c6.6,0,12-5.4,12-12V349.9z"/>',
                '<path fill="#23262F" opacity="0.5" d="M368,245H32c-6.6,0-12,5.4-12,12v39h360v-39C380,250.4,374.6,245,368,245z"/>'
                '<rect x="20" y="297.3" fill="#23262F" opacity="0.5" width="360" height="51"/>',
                '<path fill="#23262F" opacity="0.5" d="M364.8,187.5H35.2c-8.4,0-15.2,6.8-15.2,15.2v20.7c0,8.4,6.8,15.2,15.2,15.2',
                'h329.7c8.4,0,15.2-6.8,15.2-15.2v-20.7C380,194.3,373.2,187.5,364.8,187.5z"/>'
            )
        );
    }

    function generateSVGTokenId(uint256 tokenId)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<path fill="white" d="M50.9,205c-4.3,0-7.7,3.7-7.7,8C47.5,213,50.9,209.3,50.9,205z"/>',
                '<path fill="white" d="M51,205c0,4.3,3.3,8,7.7,8C58.6,208.7,55.3,205,51,205z"/>',
                '<path fill="white" d="M58.6,213c-4.2,0.2-7.5,3.6-7.5,8C55.2,220.9,58.6,217.3,58.6,213z"/>',
                '<path fill="white" d="M50.9,221c0.1,0,0.1,0,0.2,0c-0.2-4.3-3.5-7.8-7.8-8C43.3,217.5,46.6,221,50.9,221z"/>',
                '<path fill="white" d="M51.2,214.3L51.2,214.3L51.2,214.3L51.2,214.3z"/>',
                '<rect x="39" y="201" transform="matrix(0.7071 -0.7071 0.7071 0.7071 -135.6834 98.4286)" fill="none" ',
                'stroke="#E6E8EC" stroke-width="0.25" width="24" height="24"/>',
                '<text transform="matrix(1 0 0 1 80 217)" fill="#B1B5C4" font-size="18px" font-family="\'Courier New\', monospace">ID:</text>',
                '<text transform="matrix(1 0 0 1 128 217)" font-size="18px"  fill="white" font-family="\'Courier New\', monospace">',
                tokenId.toString(),
                "</text>"
            )
        );
    }

    function generateSVGFooter(
        string memory stableCoin,
        string memory stableCoinSymbol,
        string memory token,
        string memory tokenSymbol
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<rect y="423" fill="#030303" width="400" height="78"/>',
                '<text transform="matrix(1 0 0 1 20 480)" font-size="11px" fill="white" font-family="\'Courier New\', monospace">',
                tokenSymbol,
                unicode" • ",
                token,
                "</text>",
                '<text transform="matrix(1 0 0 1 20 450)" font-size="11px" fill="white" font-family="\'Courier New\', monospace">',
                stableCoinSymbol,
                unicode" • ",
                stableCoin,
                "</text>"
            )
        );
    }
}
