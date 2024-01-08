// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IMochiEngine.sol";

contract MochiNFTEngine is IMochiEngine {
    IMochiEngine public engine;
    IMochiVaultFactory public override vaultFactory;
    IMochiNFT public override nft;
    ILiquidator public override liquidator;
   
    function mochi() external override view returns(IMochi) {
       return engine.mochi(); 
    }
    
    function vMochi() external override view returns(IVMochi) {
        return engine.vMochi();
    }

    function governance() external override view returns(address) {
        return engine.governance();
    }

    function treasury() external override view returns(address) {
        return engine.treasury();
    }

    function operationWallet() external override view returns(address) {
        return engine.operationWallet();
    }
    
    function usdm() external override view returns(IUSDM) {
        return engine.usdm();
    }

    function minter() external override view returns(IMinter) {
        return engine.minter();
    }

    function cssr() external override view returns(ICSSRRouter) {
        return engine.cssr();
    }

    function mochiProfile() external override view returns(IMochiProfile) {
        return engine.mochiProfile();
    }

    function discountProfile() external override view returns(IDiscountProfile) {
        return engine.discountProfile();
    }

    function feePool() external override view returns(IFeePool) {
        return engine.feePool();
    }

    function referralFeePool() external override view returns(IReferralFeePool) {
        return engine.referralFeePool();
    }

    constructor(address _engine) {
        engine = IMochiEngine(_engine);
    }

    modifier onlyGov() {
        require(msg.sender == engine.governance(), "!gov");
        _;
    }

    function changeVaultFactory(address _factory) external onlyGov {
        vaultFactory = IMochiVaultFactory(_factory);
    }

    function changeLiquidator(address _liquidator) external onlyGov {
        liquidator = ILiquidator(_liquidator);
    }

    function changeNFT(address _nft) external onlyGov {
        nft = IMochiNFT(_nft);
    }
}
