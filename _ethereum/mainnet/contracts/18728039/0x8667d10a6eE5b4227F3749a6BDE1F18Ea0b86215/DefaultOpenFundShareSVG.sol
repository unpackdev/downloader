// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OpenFundShareDelegate.sol";
import "./OpenFundShareConcrete.sol";
import "./OpenFundSVGBase.sol";

contract DefaultOpenFundShareSVG is OpenFundSVGBase {

    using Strings for uint256;
    using Strings for address;
    using Dates for uint256;
    
    struct SVGParams {
        address payableAddress;
        string tokenId;
        uint256 slot;
        string payableName;
        string currencyTokenSymbol;
        string tokenBalance;
        string estValue;
        string navDate;
        address issuer;
        string svgGenerationTime;
    }

    function generateSVG(address payable_, uint256 tokenId_) 
        external 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        OpenFundShareDelegate payableDelegate = OpenFundShareDelegate(payable_);
        OpenFundShareConcrete payableConcrete = OpenFundShareConcrete(payableDelegate.concrete());

        uint256 tokenBalance = payableDelegate.balanceOf(tokenId_);
        uint256 slot = payableDelegate.slotOf(tokenId_);
        OpenFundShareConcrete.SlotBaseInfo memory baseInfo = payableConcrete.slotBaseInfo(slot);

        bytes32 marketPoolId = keccak256(abi.encode(payable_, slot));
        (,,,,,, address navOracle, ,,) = OpenFundMarketStorage(_market()).poolInfos(marketPoolId);
        (uint256 nav, uint256 navDate) = INavOracle(navOracle).getSubscribeNav(marketPoolId, block.timestamp);
        uint256 estValue = tokenBalance * nav / (10 ** payableDelegate.valueDecimals());
        
        SVGParams memory svgParams;
        svgParams.payableAddress = payable_;
        svgParams.tokenId = tokenId_.toString();
        svgParams.slot = slot;
        svgParams.payableName = payableDelegate.name();
        svgParams.currencyTokenSymbol = ERC20(baseInfo.currency).symbol();
        svgParams.tokenBalance = string(_formatValue(tokenBalance, payableDelegate.valueDecimals()));
        svgParams.estValue = string(_formatValue(estValue, ERC20(baseInfo.currency).decimals()));
        svgParams.navDate = navDate.dateToString();
        svgParams.issuer = baseInfo.issuer;
        svgParams.svgGenerationTime = block.timestamp.datetimeToString();

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
                        _generateBackground(params.payableAddress, params.slot),
                        _generateContent(params),
                    '</svg>'
                )
            );
    }

    function _generateContent(SVGParams memory params) internal view virtual returns (string memory) {
        SVGBackgroundGenerator.SVGColorInfo memory svgColorInfo = SVGBackgroundGenerator(svgBackgroundGenerator).getSVGColorInfo(params.payableAddress, params.slot);
        return
            string(
                abi.encodePacked(
                    '<text fill="#202020" font-family="Arial" font-size="12">',
                    abi.encodePacked(
                        '<tspan x="26" y="61" font-size="16" font-weight="bold">AMOUNT</tspan>',
                        '<tspan x="26" y="108" font-size="38" font-weight="bold">', params.tokenBalance, '</tspan>',
                        '<tspan x="26" y="143" font-size="14" font-weight="bold" fill="', svgColorInfo.backgroundColor, '">', params.payableName, '</tspan>',
                        '<tspan x="26" y="162">#', params.tokenId, '</tspan>'
                    ),
                    abi.encodePacked(
                        '<tspan x="26" y="300">EST. VALUE</tspan>',
                        '<tspan x="26" y="320">NAV DATE</tspan>',
                        '<tspan x="250" y="300" text-anchor="end">', params.estValue, ' ', params.currencyTokenSymbol, '</tspan>',
                        '<tspan x="250" y="320" text-anchor="end">', params.navDate, '</tspan>'
                    ),
                    abi.encodePacked(
                        '<tspan x="26" y="364" font-size="7">Issuer: ', params.issuer.toHexString(), '</tspan>',
                        '<tspan x="26" y="376" font-size="7">Updated: ', params.svgGenerationTime, '</tspan>',
                        '<tspan x="498" y="376" font-size="7" fill="white" fill-opacity="0.6">Powered by Solv Protocol</tspan>'
                    ),
                    '</text>'
                )
            );
    }
}