pragma solidity ^0.8.13;
import "./ArbiGovMessengerL1.sol";
import "./AuraFarmer.sol";
import "./Governable.sol";


contract ArbiAuraFarmerMessenger is Governable{
    
    ArbiGovMessengerL1 public arbiGovMessenger;
    address public auraFarmerL2;
    
    error InsufficientCallValue(uint expected);

    constructor(
        address _gov,
        address _arbiGovMessenger,
        address _auraFarmerL2
    ) Governable(_gov) {
        arbiGovMessenger = ArbiGovMessengerL1(payable(_arbiGovMessenger));
        auraFarmerL2 = _auraFarmerL2;
    }

    function setAuraFarmerL2(address _auraFarmerL2) external onlyGov {
        auraFarmerL2 = _auraFarmerL2;
    }

    function changeL2Chair(address _newL2Chair) payable external onlyGov {
        bytes4 selector = AuraFarmer.changeL2Chair.selector;
        if(!arbiGovMessenger.isCallValueSufficient(auraFarmerL2, selector, msg.value))
            revert InsufficientCallValue(arbiGovMessenger.getFunctionMinimumCallValue(auraFarmerL2, selector));
        bytes memory data = abi.encodeWithSelector(selector, _newL2Chair);
        arbiGovMessenger.sendMessage{value:msg.value}(auraFarmerL2, selector, data);
    }

    function changeL2Guardian(address _newL2Guardian) payable external onlyGov {
        bytes4 selector = AuraFarmer.changeL2Guardian.selector;
        if(!arbiGovMessenger.isCallValueSufficient(auraFarmerL2, selector, msg.value))
            revert InsufficientCallValue(arbiGovMessenger.getFunctionMinimumCallValue(auraFarmerL2, selector));
        bytes memory data = abi.encodeWithSelector(selector, _newL2Guardian);
        arbiGovMessenger.sendMessage{value:msg.value}(auraFarmerL2, selector, data);
    }

    function changeL2TWG(address _newL2TWG) payable external onlyGov {
        bytes4 selector = AuraFarmer.changeL2TWG.selector;
        if(!arbiGovMessenger.isCallValueSufficient(auraFarmerL2, selector, msg.value))
            revert InsufficientCallValue(arbiGovMessenger.getFunctionMinimumCallValue(auraFarmerL2, selector));
        bytes memory data = abi.encodeWithSelector(selector, _newL2TWG);
        arbiGovMessenger.sendMessage{value:msg.value}(auraFarmerL2, selector, data);
    }

    function changeArbiFedL1(address _newArbiFedL1) payable external onlyGov {
        bytes4 selector = AuraFarmer.changeArbiFedL1.selector;
        if(!arbiGovMessenger.isCallValueSufficient(auraFarmerL2, selector, msg.value))
            revert InsufficientCallValue(arbiGovMessenger.getFunctionMinimumCallValue(auraFarmerL2, selector));
        bytes memory data = abi.encodeWithSelector(selector, _newArbiFedL1);
        arbiGovMessenger.sendMessage{value:msg.value}(auraFarmerL2, selector, data);
    }

    function changeArbiGovMessengerL1(address _newArbiGovMessengerL1) payable external onlyGov {
        bytes4 selector = AuraFarmer.changeArbiGovMessengerL1.selector;
        if(!arbiGovMessenger.isCallValueSufficient(auraFarmerL2, selector, msg.value))
            revert InsufficientCallValue(arbiGovMessenger.getFunctionMinimumCallValue(auraFarmerL2, selector));
        bytes memory data = abi.encodeWithSelector(selector, _newArbiGovMessengerL1);
        arbiGovMessenger.sendMessage{value:msg.value}(auraFarmerL2, selector, data);
    }

    function changeTreasuryL1(address _newTreasuryL1) payable external onlyGov {
        bytes4 selector = AuraFarmer.changeTreasuryL1.selector;
        if(!arbiGovMessenger.isCallValueSufficient(auraFarmerL2, selector, msg.value))
            revert InsufficientCallValue(arbiGovMessenger.getFunctionMinimumCallValue(auraFarmerL2, selector));
        bytes memory data = abi.encodeWithSelector(selector, _newTreasuryL1);
        arbiGovMessenger.sendMessage{value:msg.value}(auraFarmerL2, selector, data);
    }

    function changeMaxLossExpansionBps(uint _newMaxLossExpansionBps) payable external onlyGov {
        bytes4 selector = AuraFarmer.setMaxLossExpansionBps.selector;
        if(!arbiGovMessenger.isCallValueSufficient(auraFarmerL2, selector, msg.value))
            revert InsufficientCallValue(arbiGovMessenger.getFunctionMinimumCallValue(auraFarmerL2, selector));
        bytes memory data = abi.encodeWithSelector(selector, _newMaxLossExpansionBps);
        arbiGovMessenger.sendMessage{value:msg.value}(auraFarmerL2, selector, data);
    }

    function changeMaxLossWithdrawBps(uint _newMaxLossWithdrawBps) payable external onlyGov {
        bytes4 selector = AuraFarmer.setMaxLossWithdrawBps.selector;
        if(!arbiGovMessenger.isCallValueSufficient(auraFarmerL2, selector, msg.value))
            revert InsufficientCallValue(arbiGovMessenger.getFunctionMinimumCallValue(auraFarmerL2, selector));
        bytes memory data = abi.encodeWithSelector(selector, _newMaxLossWithdrawBps);
        arbiGovMessenger.sendMessage{value:msg.value}(auraFarmerL2, selector, data);
    }

    function changeMaxLossSetableByGuardianBps(uint _newMaxLossSetableByGuardianBps) payable external onlyGov {
        bytes4 selector = AuraFarmer.setMaxLossSetableByGuardianBps.selector;
        if(!arbiGovMessenger.isCallValueSufficient(auraFarmerL2, selector, msg.value))
            revert InsufficientCallValue(arbiGovMessenger.getFunctionMinimumCallValue(auraFarmerL2, selector));
        bytes memory data = abi.encodeWithSelector(selector, _newMaxLossSetableByGuardianBps);
        arbiGovMessenger.sendMessage{value:msg.value}(auraFarmerL2, selector, data);
    }
}
