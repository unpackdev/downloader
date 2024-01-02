// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OpenFundRedemptionDelegate.sol";
import "./OpenFundRedemptionConcrete.sol";
import "./OpenFundSVGBase.sol";

contract DefaultOpenFundRedemptionSVG is OpenFundSVGBase {

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
        string value;
        string nav;
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
        OpenFundRedemptionDelegate payableDelegate = OpenFundRedemptionDelegate(payable_);
        OpenFundRedemptionConcrete payableConcrete = OpenFundRedemptionConcrete(payableDelegate.concrete());

        uint256 tokenBalance = payableDelegate.balanceOf(tokenId_);
        uint256 slot = payableDelegate.slotOf(tokenId_);
        OpenFundRedemptionConcrete.RedeemInfo memory redeemInfo = payableConcrete.getRedeemInfo(slot);

        (,, OpenFundMarketStorage.ManagerInfo memory managerInfo, ,,,,,,) = OpenFundMarketStorage(_market()).poolInfos(redeemInfo.poolId);
        uint256 value = tokenBalance * redeemInfo.nav / (10 ** payableDelegate.valueDecimals());
        
        SVGParams memory svgParams;
        svgParams.payableAddress = payable_;
        svgParams.tokenId = tokenId_.toString();
        svgParams.slot = slot;
        svgParams.payableName = payableDelegate.name();
        svgParams.currencyTokenSymbol = ERC20(redeemInfo.currency).symbol();
        svgParams.tokenBalance = string(_formatValue(tokenBalance, payableDelegate.valueDecimals()));
        svgParams.value = redeemInfo.nav == 0 ? 'Pending' : string(abi.encodePacked(_formatValue(value, ERC20(redeemInfo.currency).decimals()), ' ', svgParams.currencyTokenSymbol));
        svgParams.nav = redeemInfo.nav == 0 ? 'Pending' : string(_formatValue(redeemInfo.nav, ERC20(redeemInfo.currency).decimals()));
        svgParams.issuer = managerInfo.poolManager;
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
                    '<rect x="154" y="278" width="96" height="16" rx="8" fill="', svgColorInfo.backgroundColor, '" />',
                    '<text fill="#202020" font-family="Arial" font-size="12">',
                    abi.encodePacked(
                        '<tspan x="26" y="61" font-size="16" font-weight="bold">AMOUNT</tspan>',
                        '<tspan x="26" y="108" font-size="38" font-weight="bold">', params.tokenBalance, '</tspan>',
                        '<tspan x="26" y="143" font-size="14" font-weight="bold" fill="', svgColorInfo.backgroundColor, '">', params.payableName, '</tspan>',
                        '<tspan x="26" y="162">#', params.tokenId, '</tspan>'
                    ),
                    abi.encodePacked(
                        '<tspan x="26" y="290">STATUS</tspan>'
                        '<tspan x="26" y="310">VALUE</tspan>',
                        '<tspan x="26" y="330">NAV</tspan>',
                        '<tspan x="238" y="290" text-anchor="end" font-size="10" fill="white">REDEMPTION</tspan>',
                        '<tspan x="250" y="310" text-anchor="end">', params.value, '</tspan>',
                        '<tspan x="250" y="330" text-anchor="end">', params.nav, '</tspan>'
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