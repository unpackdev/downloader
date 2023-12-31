// SPDX-License-Identifier: GLPV2
pragma solidity ^0.8.13;

import "./IVaultManager.sol";
import "./IMEVVault.sol";
import "./WadRayMath.sol";

contract MEVVault is IMEVVault{
    using WadRayMath for uint256;

    //We must use immutable variables since they need get injected directly into the bytecode, and we are cloning
    IVaultManager immutable public vaultManager;

    //Assume precision on last rate to be relative to ray
    uint256 public lastFee;

    //Constructor will only be called on deploying the implementation of MEVVaults
    //Clones will already have immutable variable set in bytecode, and no constructor call can be done on them
    //(Technically its more like the constructor call was already done for them,
    //bytecode wise, storage does not get copied, immutable vars are injected into bytecode at construction)
    constructor(address _vm) {
        vaultManager = IVaultManager(_vm);
    }

    //User can become grandfathered into a operation fee if they have not claimed since fee change
    //However, anyone who wants to can claim for them at any time and reset the operation fee if they want
    function extractMEV() external {
        uint256 jinoroFee = address(this).balance.rayMul(lastFee);
        address payable account = payable(vaultManager.vaultToAccount(address(this)));
        account.transfer(address(this).balance - jinoroFee);
        payable(address(vaultManager)).transfer(jinoroFee);
        lastFee = vaultManager.JinoroFee();
    }

    function updateFee() external onlyVaultManager{
        lastFee = vaultManager.JinoroFee();
    }

    //Allow contract to receive eth
    receive() external payable{
    }

    modifier onlyVaultManager {
        require(msg.sender == address(vaultManager), "MEVVault: Not Authorized");
        _;
    }
}
