// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./ISupportingExternalReflection.sol";
import "./IAutomatedExternalReflector.sol";
import "./Ownable.sol";

contract EthReflectingToken is Ownable, ISupportingExternalReflection {
    using Address for address;
    using Address for address payable;

    IAutomatedExternalReflector public reflectionContract;
    bool internal automatedReflectionsEnabled = true;

    uint256 public minGas = 70000;

    function takeEthReflection(uint256 amount) internal {
        if(amount > 1000 && address(this).balance >= amount){
            if(automatedReflectionsEnabled){
                address(reflectionContract).call{value: amount, gas: gasleft()}(abi.encodeWithSignature("depositEth()"));
            } else {
                address(reflectionContract).call{value: amount}("");
            }
        }
    }

    function reflectRewards() internal {
        if(gasleft() >= minGas)
            try reflectionContract.reflectRewards{gas: gasleft()}() {} catch {}

    }

    function setReflectorAddress(address payable _reflectorAddress) external override onlyOwner {
        require(_reflectorAddress != address(reflectionContract), "Reflector is already set to this address");
        reflectionContract = IAutomatedExternalReflector(_reflectorAddress);
    }

    function updateAutomatedReflections(bool enabled) external onlyOwner {
        require(enabled != automatedReflectionsEnabled, "Auto-Reflections are already set to that value");
        automatedReflectionsEnabled = enabled;
    }

    function updateMinGas(uint256 minGasQuantity) external onlyOwner {
        require(minGas >= 50000, "Minimum Gas must be over 50,000 bare minimum!");
        minGas = minGasQuantity;
    }
}
