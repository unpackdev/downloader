// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./AdminControl.sol";
import "./Constants.sol";
import "./StringConvertor.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./ERC20Upgradeable.sol";
import "./IVoucherSVG.sol";
import "./ConvertibleVoucher.sol";
import "./ConvertiblePool.sol";

contract DefaultConvertibleVoucherSVG is IVoucherSVG, AdminControl {

    using StringConvertor for uint256;
    using StringConvertor for bytes;
    
    struct SVGParams {
        address voucher;
        string underlyingTokenSymbol;
        string currencyTokenSymbol;
        uint256 tokenId;
        uint256 parValue;
        uint128 highestPrice;
        uint128 lowestPrice;
        uint64 maturity;
        uint8 valueDecimals;
        uint8 priceDecimals;
        uint8 underlyingTokenDecimals;
        uint8 currencyTokenDecimal;
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
        ConvertibleVoucher convertibleVoucher = ConvertibleVoucher(voucher_);
        ConvertiblePool convertiblePool = convertibleVoucher.convertiblePool();
        ERC20Upgradeable underlyingToken = ERC20Upgradeable(convertiblePool.underlyingToken());

        ConvertibleVoucher.ConvertibleVoucherSnapshot memory snapshot = convertibleVoucher.getSnapshot(tokenId_);
        ERC20Upgradeable currencyToken = ERC20Upgradeable(snapshot.slotDetail.fundCurrency);

        SVGParams memory svgParams;
        svgParams.voucher = voucher_;
        svgParams.underlyingTokenSymbol = underlyingToken.symbol();
        svgParams.currencyTokenSymbol = currencyToken.symbol();
        svgParams.tokenId = tokenId_;
        svgParams.parValue = snapshot.parValue;
        svgParams.lowestPrice = snapshot.slotDetail.lowestPrice;
        svgParams.highestPrice = snapshot.slotDetail.highestPrice;
        svgParams.maturity = snapshot.slotDetail.maturity;
        svgParams.valueDecimals = convertiblePool.valueDecimals();
        svgParams.priceDecimals = convertiblePool.priceDecimals();
        svgParams.underlyingTokenDecimals = underlyingToken.decimals();
        svgParams.currencyTokenDecimal = currencyToken.decimals();
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
                            _generateBackground(),
                            _generateTitle(params),
                            _generateMaturity(params),
                            _generatePriceRange(params),
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
                            '<linearGradient x1="50%" y1="30%" x2="100%" y2="75%" id="lg-1">',
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
                                '<stop stop-color="#FFFFFF" offset="40%"></stop>',
                                '<stop stop-color="#FFFFFF" offset="55%"></stop>',
                                '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                            '</linearGradient>',
                            '<linearGradient x1="82%" y1="18%" x2="25%" y2="65%" id="lg-4">',
                                '<stop stop-color="#FFFFFF" offset="0%"></stop>',
                                '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                            '</linearGradient>',
                            '<linearGradient x1="65%" y1="0" x2="45%" y2="100%" id="lg-5">',
                                '<stop stop-color="#BBBBBB" offset="0%"></stop>',
                                '<stop stop-color="#FFFFFF" offset="100%"></stop>',
                            '</linearGradient>',
                            '<path id="text-path-a" d="M30 12 H570 A18 18 0 0 1 588 30 V370 A18 18 0 0 1 570 388 H30 A18 18 0 0 1 12 370 V30 A18 18 0 0 1 30 12 Z"/>'
                        ),
                    '</defs>'
                )
            );
    }

    function _generateBackground() internal pure virtual returns (string memory) {
        return 
            string(
                abi.encodePacked(
                    // outline
                    '<rect fill="url(#lg-1)" x="0" y="0" width="600" height="400" rx="24"></rect>',
                    // border
                    '<rect stroke="#FFFFFF" x="16.5" y="16.5" width="567" height="367" rx="16"></rect>',
                    // rolling text
                    '<g text-rendering="optimizeSpeed" opacity="0.5" font-size="10" fill="#FFFFFF">',
                        '<text><textPath startOffset="-100%" xlink:href="#text-path-a">In Crypto We Trust<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>',
                        '<text><textPath startOffset="0%" xlink:href="#text-path-a">In Crypto We Trust<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>',
                        '<text><textPath startOffset="50%" xlink:href="#text-path-a">Powered by Solv Protocol<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>',
                        '<text><textPath startOffset="-50%" xlink:href="#text-path-a">Powered by Solv Protocol<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>',
                    '</g>',
                    // bonding curve
                    '<g transform="translate(60, 27)">',
                        '<path d="M0,345 L0,292 C0,226 54,172 120,172 L352,172 C418,172 472,119 472,52 L472,0 L472,0" stroke="url(#lg-2)" stroke-width="20" stroke-linecap="round" stroke-linejoin="round" opacity="0.2"></path>',
                        '<path d="M0,345 L0,292 C0,226 54,172 120,172 L352,172 C418,172 472,119 472,52 L472,0 L472,0" stroke="url(#lg-3)" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"></path>',
                        '<path d="M448.3,131.5 L432,153 C420,138 420,138 420,138 L446,128.5 C447.1,128 449.5,128.5 448.5,131 Z" fill="url(#lg-4)" transform="translate(435, 141) rotate(-12) translate(-435, -141)"></path>',
                        '<circle stroke="#FFFFFF" stroke-width="4" fill="#3CBF45" cx="331" cy="172" r="7"></circle>',
                        '<circle stroke="#FFFFFF" stroke-width="4" fill="#D75959" cx="149" cy="172" r="7"></circle>',
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
                    '<text font-size="32" fill="#FFFFFF">',
                        '<tspan x="40" y="65" font-size="25">', params.underlyingTokenSymbol, ' Convertible Voucher</tspan>',
                        '<tspan x="40" y="105">', 
                            _formatValue(params.parValue, params.valueDecimals), 
                            '<tspan font-size="24"> ', params.currencyTokenSymbol, '</tspan>', 
                        '</tspan>',
                        '<tspan x="', tokenIdLeftMargin.toString(), '" y="69"># ', tokenIdStr, '</tspan>',
                    '</text>'
                )
            );
    }

    function _generateMaturity(SVGParams memory params) internal pure virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text font-size="12" fill="#FFFFFF">',
                        '<tspan x="40" y="365">Maturity Date: ',
                            uint256(params.maturity).dateToString(),
                        '</tspan>',
                    '</text>'
                )
            );
    }

    function _generatePriceRange(SVGParams memory params) internal pure virtual returns (string memory) {
        uint256 minTokenAmount = params.parValue / params.highestPrice;
        uint256 maxTokenAmount = params.parValue / params.lowestPrice;

        bytes memory minAmountStr = minTokenAmount < (10 ** (params.underlyingTokenDecimals + 6)) ? 
                                    _formatValue(minTokenAmount, params.underlyingTokenDecimals) : 
                                    abi.encodePacked(
                                        _formatValue(minTokenAmount, params.underlyingTokenDecimals + 6),
                                        "M"
                                    );
        bytes memory maxAmountStr = maxTokenAmount < (10 ** (params.underlyingTokenDecimals + 6)) ? 
                                    _formatValue(maxTokenAmount, params.underlyingTokenDecimals) : 
                                    abi.encodePacked(
                                        _formatValue(maxTokenAmount, params.underlyingTokenDecimals + 6),
                                        "M"
                                    );

        return 
            string(
                abi.encodePacked(
                    '<path d="M330,242 L550,242 C555,242 560,246 560,252 L560,292 C560,297 555,302 550,302 L330,302 C324,302 320,297 320,292 L320,252 C320,246 324,242 330,242 Z" fill="#000000" opacity="0.2" transform="translate(440, 272) scale(1, -1) translate(-440, -272)"></path>',
                    '<path d="M330,309 L550,309 C555,309 560,313 560,319 L560,359 C560,364 555,369 550,369 L330,369 C324,369 320,364 320,359 L320,319 C320,313 324,309 330,309 Z" fill="#000000" opacity="0.2" transform="translate(440, 339) scale(1, -1) translate(-440, -339)"></path>',
                    '<circle stroke="#FFFFFF" stroke-width="2" fill="#D75959" cx="336" cy="326" r="5"></circle>',
                    '<circle stroke="#FFFFFF" stroke-width="2" fill="#3CBF45" cx="336" cy="260" r="5"></circle>',
                    '<text font-size="14" fill="#FFFFFF" opacity="0.8">',
                        abi.encodePacked(
                            '<tspan x="352" y="265">Price above </tspan>',
                            '<tspan x="432" y="266">$', _formatValue(params.highestPrice, params.priceDecimals), '</tspan>',
                            '<tspan x="352" y="285">Claimable = </tspan>',
                            '<tspan x="432" y="286">', 
                                minAmountStr, ' ', params.underlyingTokenSymbol,
                            '</tspan>'
                        ),
                        abi.encodePacked(
                            '<tspan x="352" y="331">Price below </tspan>',
                            '<tspan x="432" y="332">$', _formatValue(params.lowestPrice, params.priceDecimals), '</tspan>',
                            '<tspan x="352" y="351">Claimable = </tspan>',
                            '<tspan x="432" y="352">',
                                maxAmountStr, ' ', params.underlyingTokenSymbol,
                            '</tspan>'
                        ),
                    '</text>'
                )
            );
    }

    function _formatValue(uint256 value, uint8 decimals) private pure returns (bytes memory) {
        return value.uint2decimal(decimals).trim(decimals - 2).addThousandsSeparator();
    }

}