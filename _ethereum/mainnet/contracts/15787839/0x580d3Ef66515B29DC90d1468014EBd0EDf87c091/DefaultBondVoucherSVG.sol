// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./AdminControl.sol";
import "./Constants.sol";
import "./StringConvertor.sol";
import "./ERC20Upgradeable.sol";
import "./IVoucherSVG.sol";
import "./BondVoucher.sol";
import "./BondPool.sol";

contract DefaultBondVoucherSVG is IVoucherSVG, AdminControl {

    using StringConvertor for uint256;
    using StringConvertor for bytes;
    
    struct SVGParams {
        address voucher;
        string voucherName;
        string issuerName;
        string currencyTokenSymbol;
        uint256 tokenId;
        uint256 parValue;
        uint64 effectiveTime;
        uint64 maturity;
        uint8 valueDecimals;
    }

    /// @dev voucher => claimType => background colors
    mapping(address => mapping(uint8 => string[])) public voucherBgColors;

    constructor(
        string[] memory linearBgColors_, 
        string[] memory onetimeBgColors_, 
        string[] memory stagedBgColors_
    ) {
        __AdminControl_init(_msgSender());
        setVoucherBgColors(address(0), linearBgColors_, onetimeBgColors_, stagedBgColors_);
    }

    function setVoucherBgColors(
        address voucher_,
        string[] memory linearBgColors_, 
        string[] memory onetimeBgColors_, 
        string[] memory stagedBgColors_
    )
        public 
        onlyAdmin 
    {
        voucherBgColors[voucher_][uint8(Constants.ClaimType.LINEAR)] = linearBgColors_;
        voucherBgColors[voucher_][uint8(Constants.ClaimType.ONE_TIME)] = onetimeBgColors_;
        voucherBgColors[voucher_][uint8(Constants.ClaimType.STAGED)] = stagedBgColors_;
    }
    
    function generateSVG(address voucher_, uint256 tokenId_) 
        external 
        virtual 
        override
        view 
        returns (string memory) 
    {
        BondVoucher bondVoucher = BondVoucher(voucher_);
        BondPool bondPool = bondVoucher.bondPool();

        BondVoucher.BondVoucherSnapshot memory snapshot = bondVoucher.getSnapshot(tokenId_);
        ERC20Upgradeable currencyToken = ERC20Upgradeable(bondPool.fundCurrency());

        SVGParams memory svgParams;
        svgParams.voucher = voucher_;
        svgParams.voucherName = bondVoucher.name();
        svgParams.issuerName = bondPool.issuerName();
        svgParams.currencyTokenSymbol = currencyToken.symbol();
        svgParams.tokenId = tokenId_;
        svgParams.parValue = snapshot.parValue;
        svgParams.effectiveTime = snapshot.slotDetail.effectiveTime;
        svgParams.maturity = snapshot.slotDetail.maturity;
        svgParams.valueDecimals = bondPool.valueDecimals();
        return _generateSVG(svgParams);
    }

    function _generateSVG(SVGParams memory params) 
        internal 
        virtual 
        view 
        returns (string memory) 
    {
        return 
            string(
                abi.encodePacked(
                    '<svg width="600px" height="400px" viewBox="0 0 600 400" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                        _generateDefs(params),
                        '<g stroke-width="1" fill="none" fill-rule="evenodd" font-family="Arial">',
                            _generateBackground(params),
                            _generateTitle(params),
                            _generateMaturity(params),
                        '</g>',
                    '</svg>'
                )
            );
    }

    function _generateDefs(SVGParams memory params) internal virtual view returns (string memory) {
        string memory color0 = voucherBgColors[params.voucher][1].length > 0 ?
                               voucherBgColors[params.voucher][1][0] :
                               voucherBgColors[address(0)][1][0];
        string memory color1 = voucherBgColors[params.voucher][1].length > 1 ?
                               voucherBgColors[params.voucher][1][1] :
                               voucherBgColors[address(0)][1][1];

        return 
            string(
                abi.encodePacked(
                    '<defs>',
                        abi.encodePacked(
                            '<linearGradient x1="0" y1="50%" x2="100%" y2="50%" id="lg-1">',
                                '<stop stop-color="', color0, '" offset="0%"></stop>',
                                '<stop stop-color="', color1, '" offset="100%"></stop>',
                            '</linearGradient>',
                            '<linearGradient x1="0" y1="50%" x2="100%" y2="50%" id="lg-2">',
                                '<stop stop-color="#000000" stop-opacity="0" offset="0%"></stop>',
                                '<stop stop-color="#000000" offset="40%"></stop>',
                                '<stop stop-color="#000000" offset="55%"></stop>',
                                '<stop stop-color="#000000" stop-opacity="0" offset="100%"></stop>',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient x1="0" y1="50%" x2="100%" y2="50%" id="lg-3">',
                                '<stop stop-color="#FFFFFF" stop-opacity="0" offset="0%"></stop>',
                                '<stop stop-color="#FFFFFF" offset="50%"></stop>',
                                '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                            '</linearGradient>',
                            '<linearGradient x1="82%" y1="18%" x2="25%" y2="65%" id="lg-4">',
                                '<stop stop-color="#FFFFFF" offset="0%"></stop>',
                                '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                            '</linearGradient>',
                            '<path id="text-path-a" d="M30 12 H570 A18 18 0 0 1 588 30 V370 A18 18 0 0 1 570 388 H30 A18 18 0 0 1 12 370 V30 A18 18 0 0 1 30 12 Z"/>'
                        ),
                    '</defs>'
                )
            );
    }

    function _generateBackground(SVGParams memory params) internal pure virtual returns (string memory) {
        return 
            string(
                abi.encodePacked(
                    // outline
                    '<rect fill="url(#lg-1)" x="0" y="0" width="600" height="400" rx="24"></rect>',
                    // border
                    '<rect stroke="#FFFFFF" x="16.5" y="16.5" width="567" height="367" rx="16"></rect>',
                    abi.encodePacked(
                        // rolling text
                        '<g text-rendering="optimizeSpeed" opacity="0.5" font-size="10" fill="#FFFFFF">',
                            '<text><textPath startOffset="-100%" xlink:href="#text-path-a">Issued by ', params.issuerName, '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>',
                            '<text><textPath startOffset="0%" xlink:href="#text-path-a">Issued by ', params.issuerName, '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>',
                            '<text><textPath startOffset="50%" xlink:href="#text-path-a">Powered by Solv Protocol<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>',
                            '<text><textPath startOffset="-50%" xlink:href="#text-path-a">Powered by Solv Protocol<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>',
                        '</g>'
                    ),
                    // bonding curve
                    '<g transform="translate(40, 92)">',
                        '<path d="M0,127 C0,127 0,127 0,127 L260,128 L260,128 L467,7" stroke="url(#lg-2)" stroke-width="20" opacity="0.1" stroke-linecap="round" stroke-linejoin="round"></path>',
                        '<polyline stroke="url(#lg-3)" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" points="47 127 260 127 479 0"></polyline>',
                        '<path d="M413.3,12.5 L397,34 C385,19 385,19 385,19 L411,9.5 C412,9 414.5,9.5 413.5,12 Z" fill="url(#lg-4)" transform="rotate(-356)"></path>',
                        '<circle stroke="#FFFFFF" stroke-width="4" fill="#3CBF45" cx="260" cy="127.5" r="7"></circle>',
                    '</g>'
                )
            );
    }

    function _generateTitle(SVGParams memory params) internal pure virtual returns (string memory) {
        string memory tokenIdStr = params.tokenId.toString();
        uint256 tokenIdLeftMargin = 526 - 18 * bytes(tokenIdStr).length;
        return 
            string(
                abi.encodePacked(
                    '<text fill="#FFFFFF">',
                        '<tspan x="40" y="65" font-size="28">', params.voucherName, '</tspan>',
                        '<tspan x="40" y="120" font-size="36">', 
                            _formatValue(params.parValue, params.valueDecimals), 
                            '<tspan font-size="28"> ', params.currencyTokenSymbol, '</tspan>', 
                        '</tspan>',
                        '<tspan font-size="32" x="', tokenIdLeftMargin.toString(), '" y="69"># ', tokenIdStr, '</tspan>',
                    '</text>'
                )
            );
    }

    function _generateMaturity(SVGParams memory params) internal pure virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text font-size="14" fill="#FFFFFF">',
                        '<tspan x="40" y="350">Start Date: ',
                            uint256(params.effectiveTime).dateToString(),
                        '</tspan>',
                        '<tspan x="400" y="350">Maturity Date: ',
                            uint256(params.maturity).dateToString(),
                        '</tspan>',
                    '</text>'
                )
            );
    }

    function _formatValue(uint256 value, uint8 decimals) private pure returns (bytes memory) {
        return value.uint2decimal(decimals).trim(decimals - 4).addThousandsSeparator();
    }

}