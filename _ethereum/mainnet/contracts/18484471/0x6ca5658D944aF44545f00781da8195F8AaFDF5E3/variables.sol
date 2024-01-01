// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interface.sol";

contract Variables {
    /***********************************|
    |             OLD ADDRESSES         |
    |__________________________________*/
    address internal constant OLD_USER_MODULE =
        0xFF1029d2fB178167f1eb9435289a90b324F3BdbC;
    address internal constant OLD_ADMIN_MODULE =
        0x27248FEe1c1DD1697F305328B031725e10B8c241;
    address internal constant OLD_LEVERAGE_MODULE =
        0xeb228438D3e5829aCe4D90a6f4D5453B8146b79a;
    address internal constant OLD_REBALANCER_MODULE =
        0x63AD4D2346B7b1009F888a4708ba66178a8431F0;
    address internal constant OLD_REFINANCE_MODULE =
        0x0f885fe8f1351A8F1755e7E79bD831d108FF10B4;
    address internal constant OLD_DSA_MODULE =
        0x8b751C738767b90005b9C06c1398F65cd0bd3094;

    /***********************************|
    |             NEW ADDRESSES         |
    |__________________________________*/
    address internal constant NEW_USER_MODULE =
        0xFF93C10FB34f7069071D0679c45ed77A98f37f21;
    address internal constant NEW_ADMIN_MODULE =
        0x06feaa505193e987B12f161F1dB73b1D4d604001;
    address internal constant NEW_LEVERAGE_MODULE =
        0xA18519a6bb1282954e933DA0A775924E4CcE6019;
    address internal constant NEW_REBALANCER_MODULE =
        0xc6639CE123d779fE6eA545B70CbDc1dCA421740d;
    address internal constant NEW_REFINANCE_MODULE =
        0x390936658cB9B73ca75c6c02D5EF88b958D38241;
    address internal constant NEW_DSA_MODULE =
        0xE38d5938d6D75ceF2c3Fc63Dc4AB32cD103E10df;
    address internal constant NEW_WITHDRAWALS_MODULE =
        0xbd45DfF3320b0d832C61fb41489fdd3a1b960067;

    address internal constant NEW_DUMMY_IMPLEMENTATION =
        0x5C122207f668D3fE345465Ac447b3FEF627f4963;

    address internal constant GOVERNANCE =
        0xC7Cb1dE2721BFC0E0DA1b9D526bCdC54eF1C0eFC; // InstaTimelock

    address internal constant VAULT =
        0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78;
    IVault internal constant vault =
        IVault(0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78);
}

contract NewSignatures is Variables {

    // Keeping them pulic so we can verify that all the signatures are matching after deploying.
    function userSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](54);
        sigs_[0] = bytes4(keccak256("allowance(address,address)"));
        sigs_[1] = bytes4(keccak256("approve(address,uint256)"));
        sigs_[2] = bytes4(keccak256("balanceOf(address)"));
        sigs_[3] = bytes4(keccak256("decreaseAllowance(address,uint256)"));
        sigs_[4] = bytes4(keccak256("increaseAllowance(address,uint256)"));
        sigs_[5] = bytes4(keccak256("name()"));
        sigs_[6] = bytes4(keccak256("symbol()"));
        sigs_[7] = bytes4(keccak256("totalSupply()"));
        sigs_[8] = bytes4(keccak256("transfer(address,uint256)"));
        sigs_[9] = bytes4(keccak256("transferFrom(address,address,uint256)"));
        sigs_[10] = bytes4(keccak256("asset()"));
        sigs_[11] = bytes4(keccak256("convertToAssets(uint256)"));
        sigs_[12] = bytes4(keccak256("convertToShares(uint256)"));
        sigs_[13] = bytes4(keccak256("decimals()"));
        sigs_[14] = bytes4(keccak256("maxDeposit(address)"));
        sigs_[15] = bytes4(keccak256("maxMint(address)"));
        sigs_[16] = bytes4(keccak256("maxRedeem(address)"));
        sigs_[17] = bytes4(keccak256("maxWithdraw(address)"));
        sigs_[18] = bytes4(keccak256("previewDeposit(uint256)"));
        sigs_[19] = bytes4(keccak256("previewMint(uint256)"));
        sigs_[20] = bytes4(keccak256("previewRedeem(uint256)"));
        sigs_[21] = bytes4(keccak256("previewWithdraw(uint256)"));
        sigs_[22] = bytes4(keccak256("getNetAssets()"));
        sigs_[23] = bytes4(keccak256("getProtocolRatio(uint8)"));
        sigs_[24] = bytes4(keccak256("getRatioAaveV2()"));
        sigs_[25] = bytes4(keccak256("getRatioAaveV3(uint256)"));
        sigs_[26] = bytes4(keccak256("getRatioCompoundV3(uint256)"));
        sigs_[27] = bytes4(keccak256("getRatioEuler(uint256)"));
        sigs_[28] = bytes4(keccak256("getRatioMorphoAaveV2()"));
        sigs_[29] = bytes4(keccak256("getWithdrawFee(uint256)"));
        sigs_[30] = bytes4(keccak256("aggrMaxVaultRatio()"));
        sigs_[31] = bytes4(keccak256("exchangePrice()"));
        sigs_[32] = bytes4(keccak256("isRebalancer(address)"));
        sigs_[33] = bytes4(keccak256("leverageMaxUnitAmountLimit()"));
        sigs_[34] = bytes4(keccak256("maxRiskRatio(uint8)"));
        sigs_[35] = bytes4(keccak256("revenue()"));
        sigs_[36] = bytes4(keccak256("revenueExchangePrice()"));
        sigs_[37] = bytes4(keccak256("revenueFeePercentage()"));
        sigs_[38] = bytes4(keccak256("secondaryAuth()"));
        sigs_[39] = bytes4(keccak256("treasury()"));
        sigs_[40] = bytes4(keccak256("vaultDSA()"));
        sigs_[41] = bytes4(keccak256("withdrawFeeAbsoluteMin()"));
        sigs_[42] = bytes4(keccak256("withdrawalFeePercentage()"));
        sigs_[43] = bytes4(keccak256("deposit(uint256,address)"));
        sigs_[44] = bytes4(
            keccak256("importPosition(uint256,uint256,uint256,address)")
        );
        sigs_[45] = bytes4(keccak256("mint(uint256,address)"));
        sigs_[46] = bytes4(keccak256("redeem(uint256,address,address)"));
        sigs_[47] = bytes4(keccak256("totalAssets()"));
        sigs_[48] = bytes4(keccak256("withdraw(uint256,address,address)"));
        // new functions
        sigs_[49] = bytes4(keccak256("borrowBalanceMorphoAaveV3(address)"));
        sigs_[50] = bytes4(keccak256("collateralBalanceMorphoAaveV3(address)"));
        sigs_[51] = bytes4(keccak256("getRatioMorphoAaveV3(uint256)"));
        sigs_[52] = bytes4(keccak256("getRatioSpark(uint256)"));
        sigs_[53] = bytes4(keccak256("queuedWithdrawStEth()"));
    }

    function adminSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](11);
        sigs_[0] = bytes4(keccak256("changeVaultStatus(uint8)"));
        sigs_[1] = bytes4(keccak256("reduceAggrMaxVaultRatio(uint256)"));
        sigs_[2] = bytes4(keccak256("reduceMaxRiskRatio(uint8[],uint256[])"));
        sigs_[3] = bytes4(keccak256("updateAggrMaxVaultRatio(uint256)"));
        sigs_[4] = bytes4(keccak256("updateFees(uint256,uint256,uint256)"));
        sigs_[5] = bytes4(
            keccak256("updateLeverageMaxUnitAmountLimit(uint256)")
        );
        sigs_[6] = bytes4(keccak256("updateMaxRiskRatio(uint8[],uint256[])"));
        sigs_[7] = bytes4(keccak256("updateRebalancer(address,bool)"));
        sigs_[8] = bytes4(keccak256("updateSecondaryAuth(address)"));
        sigs_[9] = bytes4(keccak256("updateTreasury(address)"));
        // new functions
        sigs_[10] = bytes4(keccak256("initializeV2()"));
    }

    function leverageSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](1);
        sigs_[0] = bytes4(
            keccak256(
                "leverage(uint8,uint256,uint256,uint256,address[],uint256[],uint256,uint256,bytes)"
            )
        );
    }

    function rebalancerSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](6);
        sigs_[0] = bytes4(keccak256("collectRevenue(uint256)"));
        sigs_[1] = bytes4(keccak256("fillVaultAvailability(uint8,uint256)"));
        sigs_[2] = bytes4(keccak256("sweepEthToSteth()"));
        sigs_[3] = bytes4(keccak256("sweepWethToSteth()"));
        sigs_[4] = bytes4(keccak256("updateExchangePrice()"));
        sigs_[5] = bytes4(keccak256("vaultToProtocolDeposit(uint8,uint256)"));
    }

    function refinanceSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](1);
        sigs_[0] = bytes4(
            keccak256("refinance(uint8,uint8,uint256,uint256,uint256,uint256)")
        );
    }

    function dsaSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](2);
        sigs_[0] = bytes4(keccak256("addDSAAuth(address)"));
        sigs_[1] = bytes4(keccak256("spell(address,bytes,uint256,uint256)"));
    }

    function withdrawalsSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](4);
        // new functions
        sigs_[0] = bytes4(
            keccak256("onERC721Received(address,address,uint256,bytes)")
        );
        sigs_[1] = bytes4(keccak256("queueEthWithdrawal(uint256,uint8)"));
        sigs_[2] = bytes4(keccak256("paybackDebt(uint8)"));
        sigs_[3] = bytes4(keccak256("claimEthWithdrawal(uint256,uint8)"));
    }
}
