// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./DydxFlashloanBase.sol";
import "./IDydx.sol";

import "./IDssCdpManager.sol";
import "./IDssProxyActions.sol";
import "./DssActionsBase.sol";

import "./OpenShortDAI.sol";
import "./CloseShortDAI.sol";

import "./ICurveFiCurve.sol";

import "./Constants.sol";

contract ShortDAIActions {
    using SafeMath for uint256;

    function _openUSDCACdp() internal returns (uint256) {
        return
            IDssCdpManager(Constants.CDP_MANAGER).open(
                bytes32("USDC-A"),
                address(this)
            );
    }

    // Entry point for proxy contracts
    function flashloanAndOpen(
        address _osd,
        address _solo,
        address _curvePool,
        uint256 _cdpId, // Set 0 for new vault
        uint256 _initialMargin, // Initial amount of USDC
        uint256 _flashloanAmount // Amount of DAI to flashloan
    ) external {
        // Tries and get USDC from msg.sender to proxy
        require(
            IERC20(Constants.USDC).transferFrom(
                msg.sender,
                address(this),
                _initialMargin
            ),
            "initial-margin-transferFrom-failed"
        );

        uint256 cdpId = _cdpId;

        // Opens a new USDC vault for the user if unspecified
        if (cdpId == 0) {
            cdpId = _openUSDCACdp();
        }

        // Allows LSD contract to manage vault on behalf of user
        IDssCdpManager(Constants.CDP_MANAGER).cdpAllow(cdpId, _osd, 1);

        // Transfers the initial margin (in USDC) to lsd contract
        require(
            IERC20(Constants.USDC).transfer(_osd, _initialMargin),
            "initial-margin-transfer-failed"
        );
        // Flashloan and shorts DAI
        OpenShortDAI(_osd).flashloanAndOpen(
            msg.sender,
            _solo,
            _curvePool,
            cdpId,
            _initialMargin,
            _flashloanAmount
        );

        // Forbids LSD contract to manage vault on behalf of user
        IDssCdpManager(Constants.CDP_MANAGER).cdpAllow(cdpId, _osd, 0);
    }

    function flashloanAndClose(
        address _csd,
        address _solo,
        address _curvePool,
        uint256 _cdpId
    ) external {
        IDssCdpManager(Constants.CDP_MANAGER).cdpAllow(_cdpId, _csd, 1);

        CloseShortDAI(_csd).flashloanAndClose(
            msg.sender,
            _solo,
            _curvePool,
            _cdpId
        );

        IDssCdpManager(Constants.CDP_MANAGER).cdpAllow(_cdpId, _csd, 0);
    }
}
