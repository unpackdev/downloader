// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./StringConvertor.sol";
import "./Dates.sol";
import "./Strings.sol";
import "./ERC20.sol";
import "./EarnDelegate.sol";
import "./EarnConcrete.sol";

contract DefaultEarnSVG {

    using Strings for uint256;
    using Strings for address;
    using StringConvertor for uint256;
    using StringConvertor for bytes;
    using Dates for uint256;
    
    struct SVGParams {
        address payableAddress;
        string payableName;
        string currencyTokenSymbol;
        string tokenId;
        string parValue;
        string maturity;
        string term;
        string interestRate;
        address issuer;
    }

    /// @dev payable => background colors [upper-left-0 upper-left-1 lower-right-0 lower-right-1]
    mapping(address => string[]) public backgroundColors;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor(
        address owner_,
        string[] memory backgroundColors_
    ) {
		owner = owner_;
        backgroundColors[address(0)] = backgroundColors_;
    }

    function setBackgroundColors(address payable_, string[] memory backgroundColors_) public onlyOwner {
        backgroundColors[payable_] = backgroundColors_;
    }

    function generateSVG(address payable_, uint256 tokenId_) 
        external 
        virtual 
        view 
        returns (string memory) 
    {
        EarnDelegate payableDelegate = EarnDelegate(payable_);
        EarnConcrete payableConcrete = EarnConcrete(payableDelegate.concrete());

        uint256 slot = payableDelegate.slotOf(tokenId_);
        EarnConcrete.SlotBaseInfo memory baseInfo = payableConcrete.slotBaseInfo(slot);
        EarnConcrete.SlotExtInfo memory extInfo = payableConcrete.slotExtInfo(slot);
        ERC20 currencyToken = ERC20(baseInfo.currency);

        SVGParams memory svgParams;
        svgParams.payableAddress = payable_;
        svgParams.payableName = payableDelegate.name();
        svgParams.currencyTokenSymbol = currencyToken.symbol();
        svgParams.tokenId = tokenId_.toString();
        svgParams.parValue = string(_formatValue(payableDelegate.balanceOf(tokenId_), payableDelegate.valueDecimals()));
        svgParams.maturity = uint256(baseInfo.maturity).dateToString();
        svgParams.term = uint256((baseInfo.maturity - baseInfo.valueDate) / 86400).toString();
        svgParams.interestRate = extInfo.isInterestRateSet ? 
            string(
                extInfo.interestRate < 0 ? 
                    abi.encodePacked("-", uint256(int256(0 - extInfo.interestRate)).toDecimalsString(2), "%") : 
                    abi.encodePacked(uint256(int256(extInfo.interestRate)).toDecimalsString(2), "%")
            ) :
            "Floating";
        svgParams.issuer = baseInfo.issuer;
        return generateSVG(svgParams);
    }

    function generateSVG(SVGParams memory params) 
        public 
        virtual 
        view 
        returns (string memory) 
    {
        return 
            string(
                abi.encodePacked(
                    '<svg width="600" height="400" viewBox="0 0 600 400" fill="none" xmlns="http://www.w3.org/2000/svg">',
                        _generateDefs(params),
                        _generateBackground(),
                        _generateContent(params),
                    '</svg>'
                )
            );
    }

    function _generateDefs(SVGParams memory params) internal virtual view returns (string memory) {
        string memory color_upper_left_0 = backgroundColors[address(0)][0];
        string memory color_upper_left_1 = backgroundColors[address(0)][1];
        string memory color_lower_right_0 = backgroundColors[address(0)][2];
        string memory color_lower_right_1 = backgroundColors[address(0)][3];

        if (backgroundColors[params.payableAddress].length > 3) {
            color_upper_left_0 = backgroundColors[params.payableAddress][0];
            color_upper_left_1 = backgroundColors[params.payableAddress][1];
            color_lower_right_0 = backgroundColors[params.payableAddress][2];
            color_lower_right_1 = backgroundColors[params.payableAddress][3];
        }

        return 
            string(
                abi.encodePacked(
                    '<defs>',
                        abi.encodePacked(
                            '<filter id="f_3525_3" x="275" y="-220" width="600" height="800" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
                                '<feFlood flood-opacity="0" result="e_3525_1"/>',
                                '<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>',
                                '<feOffset dy="6"/>',
                                '<feGaussianBlur stdDeviation="25"/>',
                                '<feComposite in2="hardAlpha" operator="out"/>',
                                '<feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0.3 0 0 0 0 0.5 0 0 0 0.6 0"/>',
                                '<feBlend mode="normal" in2="e_3525_1" result="e_3525_2"/>',
                                '<feBlend mode="normal" in="SourceGraphic" in2="e_3525_2"/>',
                            '</filter>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="lg_3525_1" x1="500" y1="360" x2="420" y2="-60" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', color_upper_left_0, '"/>',
                                '<stop offset="1" stop-color="', color_upper_left_1, '"/>',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="lg_3525_2" x1="120" y1="200" x2="620" y2="-128" gradientUnits="userSpaceOnUse">',
                                '<stop offset="0.15" stop-color="', color_lower_right_0, '"/>',
                                '<stop offset="0.6" stop-color="', color_lower_right_1, '"/>',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="lg_3525_3" x1="120" y1="200" x2="620" y2="-128" gradientUnits="userSpaceOnUse">',
                                '<stop offset="0.45" stop-color="', color_lower_right_0, '"/>',
                                '<stop offset="1" stop-color="', color_lower_right_1, '"/>',
                            '</linearGradient>'
                        ),
                    '</defs>'
                )
            );
    }

    function _generateBackground() internal pure virtual returns (string memory) {
        return 
            string(
                abi.encodePacked(
                    '<rect width="600" height="400" rx="20" fill="white"/>',
                    '<rect x="0.5" y="0.5" width="599" height="399" rx="20" stroke="#F3F3F3"/>',
                    '<mask id="m_3525_3" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="300" y="0" width="300" height="400">',
                        '<path d="M300 0H580C590 0 600 8 600 20V380C600 392 590 400 580 400H300V0Z" fill="white"/>',
                    '</mask>',
                    '<g mask="url(#m_3525_3)">',
                        '<path d="M300 400L600 400L600 0L300 0Z" fill="url(#lg_3525_1)"/>',
                        '<path d="M222 400L600 400L600 -64Z" fill="url(#lg_3525_2)"/>',
                        '<g filter="url(#f_3525_3)">',
                            '<path d="M336 400L600 400L600 -85Z" fill="url(#lg_3525_3)"/>',
                        '</g>',
                    '</g>',
                    '<path d="M30 199H263 M30 242H263 M30 285H263 M30 328H263" opacity="0.5" stroke="#DDDDDD" stroke-width="1"/>'
                )
            );
    }

    function _generateContent(SVGParams memory params) internal pure virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text fill="#202020" font-family="Arial" font-size="14">',
                    abi.encodePacked(
                        '<tspan x="30" y="55" font-size="18" font-weight="bold">', params.payableName, '</tspan>',
                        '<tspan x="30" y="95" font-size="28">', params.parValue, 
                            '<tspan font-size="14"> ', params.currencyTokenSymbol, '</tspan>',
                        '</tspan>',
                        '<tspan x="30" y="180" font-weight="bold">ID #', params.tokenId, '</tspan>'
                    ),
                    abi.encodePacked(
                        '<tspan x="30" y="223">APR</tspan>',
                        '<tspan x="262" y="223" text-anchor="end">', params.interestRate, '</tspan>'
                        '<tspan x="30" y="266">Term</tspan>',
                        '<tspan x="262" y="266" text-anchor="end">', params.term, 'd</tspan>',
                        '<tspan x="30" y="309">Maturity date</tspan>',
                        '<tspan x="262" y="309" text-anchor="end">', params.maturity, '</tspan>'
                    ),
                    abi.encodePacked(
                        '<tspan x="30" y="354" font-size="9">Issuer: ', params.issuer.toHexString(), '</tspan>',
                        '<tspan x="30" y="372" font-size="9" fill="#929292">Powered by Solv Protocol</tspan>'
                    ),
                    '</text>'
                )
            );
    }

    function _formatValue(uint256 value, uint8 decimals) private pure returns (bytes memory) {
        return value.toDecimalsString(decimals).trimRight(decimals - 2).addThousandsSeparator();
    }
}