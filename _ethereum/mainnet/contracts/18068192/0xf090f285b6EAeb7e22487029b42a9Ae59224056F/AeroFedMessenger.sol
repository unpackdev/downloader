// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ICrossDomainMessenger.sol";

contract AeroFedMessenger {
    ICrossDomainMessenger constant crossDomainMessenger = ICrossDomainMessenger(0x866E82a600A1414e583f7F13623F1aC5d58b0Afa);
    address public aeroFed;
    address public gov;
    address public pendingGov;
    address public guardian;
    address public chair;

    uint32 public gasLimit = 750_000;

    constructor(address gov_, address chair_, address guardian_, address aeroFed_) {
        gov = gov_;
        chair = chair_;
        guardian = guardian_;
        aeroFed = aeroFed_;
    } 

    modifier onlyGov {
        if (msg.sender != gov) revert OnlyGov();
        _;
    }

    modifier onlyGovOrGuardian {
        if (msg.sender != gov && msg.sender != guardian) revert OnlyGov();
        _;
    }

    modifier onlyPendingGov {
        if (msg.sender != pendingGov) revert OnlyPendingGov();
        _;
    }

    modifier onlyChair {
        if (msg.sender != chair) revert OnlyChair();
        _;
    }

    error OnlyGov();
    error OnlyGovOrGuardian();
    error OnlyPendingGov();
    error OnlyChair();

    //Helper functions

    function sendMessage(bytes memory message) internal {
        crossDomainMessenger.sendMessage(address(aeroFed), message, gasLimit);
    }

    //Gov Messaging functions

    function setMaxSlippageDolaToUsdc(uint newSlippage_) public onlyGovOrGuardian {
        sendMessage(abi.encodeWithSignature("setMaxSlippageDolaToUsdc(uint256)", newSlippage_));
    }

    function setMaxSlippageUsdcToDola(uint newSlippage_) public onlyGovOrGuardian {
        sendMessage(abi.encodeWithSignature("setMaxSlippageUsdcToDola(uint256)", newSlippage_));
    }

    function setMaxSlippageLiquidity(uint newSlippage_) public onlyGovOrGuardian {
        sendMessage(abi.encodeWithSignature("setMaxSlippageLiquidity(uint256)", newSlippage_));
    }

    function setPendingGov(address newPendingGov_) public onlyGov {
        sendMessage(abi.encodeWithSignature("setPendingGov(address)", newPendingGov_));
    }

    function claimGov() public onlyGov {
        sendMessage(abi.encodeWithSignature("claimGov()"));
    }

    function changeTreasury(address newTreasury_) public onlyGov {
        sendMessage(abi.encodeWithSignature("changeTreasury(address)", newTreasury_));
    }

    function changeChair(address newChair_) public onlyGov {
        sendMessage(abi.encodeWithSignature("changeChair(address)", newChair_));
    }

    function changeGuardian(address newGuardian_) public onlyGov {
        sendMessage(abi.encodeWithSignature("changeGuardian(address)", newGuardian_));
    }

    function changeL2Chair(address newChair_) public onlyGov {
        sendMessage(abi.encodeWithSignature("changeL2Chair(address)", newChair_));
    }

    function changeBaseFed(address baseFed_) public onlyGov {
        sendMessage(abi.encodeWithSignature("changeBaseFed(address)", baseFed_));
    }

    //Chair messaging functions

    function claimAeroRewards() public onlyChair {
        sendMessage(abi.encodeWithSignature("claimAeroRewards()"));
    }

    function claimRewards(address[] calldata addrs) public onlyChair {
        sendMessage(abi.encodeWithSignature("claimRewards(address)", addrs));
    }

    function swapAndDeposit(uint dolaAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("swapAndDeposit(uint256)", dolaAmount));
    }

    function deposit(uint dolaAmount, uint usdcAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("deposit(uint256,uint256)", dolaAmount, usdcAmount));
    }

    function withdrawLiquidity(uint dolaAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("withdrawLiquidity(uint256)", dolaAmount));
    }

    function withdrawLiquidityAndSwapToDola(uint dolaAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("withdrawLiquidityAndSwapToDOLA(uint256)", dolaAmount));
    }

    function withdrawToL1BaseFed(uint dolaAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("withdrawToL1BaseFed(uint256)", dolaAmount));
    }

    function withdrawToL1BaseFed(uint dolaAmount, uint usdcAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("withdrawToL1BaseFed(uint256,uint256)", dolaAmount, usdcAmount));
    }

    function swapUSDCtoDOLA(uint usdcAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("swapUSDCtoDOLA(uint256)", usdcAmount));
    }

    function swapDOLAtoUSDC(uint usdcAmount) public onlyChair {
        sendMessage(abi.encodeWithSignature("swapDOLAtoUSDC(uint256)", usdcAmount));
    }

    function resign() public onlyChair {
        sendMessage(abi.encodeWithSignature("resign()"));
    }

    //Gov functions

    function withdrawTokensToL1(address l2Token, address to, uint amount) public onlyGov {
        sendMessage(abi.encodeWithSignature("withdrawTokensToL1(address,address,uint256)", l2Token, to, amount));
    }

    function setGasLimit(uint32 newGasLimit_) public onlyGov {
        gasLimit = newGasLimit_;
    }

    function setPendingMessengerGov(address newPendingGov_) public onlyGov {
        pendingGov = newPendingGov_;
    }

    function claimMessengerGov() public onlyPendingGov {
        gov = pendingGov;
        pendingGov = address(0);
    }

    function changeMessengerChair(address newChair_) public onlyGov {
        chair = newChair_;
    }

    function changeMessengerGuardian(address newGuardian_) public onlyGov {
        guardian = newGuardian_;
    }

    function setAeroFed(address aeroFed_) public onlyGov {
        aeroFed = aeroFed_;
    }
}
