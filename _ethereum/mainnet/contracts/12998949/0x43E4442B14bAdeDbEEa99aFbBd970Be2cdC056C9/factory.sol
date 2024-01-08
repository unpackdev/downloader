// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Clones.sol";
import "./Ownable.sol";
import "./IERC20.sol";

interface IDelegateClone {
    function initialize(address owner, address delegatee) external;
}

contract InstaDelegateFactory is Ownable {
    // Events
    event LogDeployed(address owner, address delegatee, address clone);
    event LogSetClonableDelegateAddress(address oldClonableDelegate, address newClonableDelegate);

    // Variables
    address public clonableDelegate; // clonable delegate address
    IERC20 public constant token = IERC20(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb); // INST token

    /*
    Set clonableDelegate contract address
    */
    function setClonableDelegateAddress(address _clonableAddress) external onlyOwner {
        emit LogSetClonableDelegateAddress(clonableDelegate, _clonableAddress);
        clonableDelegate = _clonableAddress;
    }

    function deploy(address cloneOwner, address delegatee) public {
        address clone = Clones.clone(clonableDelegate);
        IDelegateClone newDelegate = IDelegateClone(clone);
        newDelegate.initialize(cloneOwner, delegatee);
        emit LogDeployed(cloneOwner, delegatee, clone);
    }
}
