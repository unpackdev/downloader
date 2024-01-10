// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./Auth.sol";
import "./SafeTransferLib.sol";
import "./SafeCastLib.sol";
import "./FixedPointMathLib.sol";
import "./IVaderMinter.sol";

contract VaderGateway is Auth, IVaderMinter {

    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using SafeCastLib for uint256;

    IVaderMinter public immutable VADERMINTER;

    ERC20 public immutable VADER;
    ERC20 public immutable USDV;

    constructor(
        address VADERMINTER_,
        address GOVERNANCE_,
        Authority AUTHORITY_,
        address VADER_,
        address USDV_
    ) Auth(GOVERNANCE_, Authority(AUTHORITY_))
    {
        VADERMINTER = IVaderMinter(VADERMINTER_);
        VADER = ERC20(VADER_);
        USDV = ERC20(USDV_);

        //set approvals
        VADER.safeApprove(VADERMINTER_, type(uint256).max);
        VADER.safeApprove(address(USDV), type(uint256).max);
        USDV.safeApprove(VADERMINTER_, type(uint256).max);
    }


    function lbt() external view returns (address) {
        return VADERMINTER.lbt();
    }

    // The 24 hour limits on USDV mints that are available for public minting and burning as well as the fee.
    function dailyLimits() external view returns (Limits memory) {
        return VADERMINTER.dailyLimits();
    }

    // The current cycle end timestamp
    function cycleTimestamp() external view returns (uint) {
        return VADERMINTER.cycleTimestamp();
    }

    // The current cycle cumulative mints
    function cycleMints() external view returns (uint) {
        return VADERMINTER.cycleMints();
    }

    // The current cycle cumulative burns
    function cycleBurns() external view returns (uint){
        return VADERMINTER.cycleBurns();
    }

    function partnerLimits(address partner) external view returns (Limits memory){
        return VADERMINTER.partnerLimits(partner);
    }

    // USDV Contract for Mint / Burn Operations
    function usdv() external view returns (address) {
        return VADERMINTER.usdv();
    }

    /*
     * @dev Partner mint function that receives Vader and mints USDV.
     * @param vAmount Vader amount to burn.
     * @returns uAmount in USDV, represents the USDV amount received from the mint.
     *
     * Requirements:
     * - Can only be called by whitelisted partners.
     **/
    function partnerMint(uint256 vAmount, uint256 uMinOut) external requiresAuth returns (uint256 uAmount) {
        VADER.transferFrom(msg.sender, address(this), vAmount);

        uAmount = VADERMINTER.partnerMint(vAmount, uMinOut);

        USDV.safeTransfer(msg.sender, uAmount);
    }
    /*
     * @dev Partner burn function that receives USDV and mints Vader.
     * @param uAmount USDV amount to burn.
     * @returns vAmount in Vader, represents the Vader amount received from the mint.
     *
     * Requirements:
     * - Can only be called by whitelisted partners.
     **/
    function partnerBurn(uint256 uAmount, uint256 vMinOut) external requiresAuth returns (uint256 vAmount) {
        USDV.transferFrom(msg.sender, address(this), uAmount);
        vAmount = VADERMINTER.partnerBurn(uAmount, vMinOut);
        VADER.safeTransfer(msg.sender, vAmount);
    }

}
