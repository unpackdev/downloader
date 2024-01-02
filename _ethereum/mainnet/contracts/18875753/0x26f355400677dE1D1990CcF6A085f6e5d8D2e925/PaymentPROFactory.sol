//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Clones.sol";

interface IPaymentPROClonableReference {
  function initializeContract(
    address _roleAdmin,
    address _approvedPaymentToken,
    address _approvedSweepingToken,
    address _approvedTokenSweepRecipient,
    uint256 _defaultTokenAmount
  ) external;
}

contract PaymentPROFactory is Ownable {

    event NewPaymentPROClone(
      address indexed referenceContract,
      address indexed cloneAddress,
      address indexed roleAdmin,
      address approvedPaymentToken,
      address approvedSweepingToken,
      address approvedTokenSweepRecipient,
      uint256 defaultTokenAmount
    );

    event SetClonableReferenceValidity(
      address indexed referenceContract,
      bool validity
    );

    event SetClonerValidity(
      address indexed cloner,
      address indexed referenceContract,
      bool indexed approvalStatus
    );

    mapping(address => bool) public validClonableReferences;
    mapping(address => bool) public approvedCloner;
    mapping(address => address) public approvedClonerClonableReference;

    modifier onlyApprovedClonerOrOwner() {
      require((approvedCloner[msg.sender]) || (owner() == msg.sender), "INVALID_CLONER");
      _;
    }

    constructor(
      address _clonableReference
    ) {
      validClonableReferences[_clonableReference] = true;
      emit SetClonableReferenceValidity(_clonableReference, true);
    }

    function newPaymentPROClone(
      address _referenceContract,
      address _roleAdmin,
      address _approvedPaymentToken,
      address _approvedSweepingToken,
      address _approvedTokenSweepRecipient,
      uint256 _defaultTokenAmount
    ) external onlyApprovedClonerOrOwner {
      require(validClonableReferences[_referenceContract], "INVALID_REFERENCE_CONTRACT");
      // Deploy new clone of PaymentPROClonable
      address newCloneAddress = Clones.clone(_referenceContract);
      IPaymentPROClonableReference newClone = IPaymentPROClonableReference(newCloneAddress);
      newClone.initializeContract(
        _roleAdmin,
        _approvedPaymentToken,
        _approvedSweepingToken,
        _approvedTokenSweepRecipient,
        _defaultTokenAmount
      );
      emit NewPaymentPROClone(
        _referenceContract,
        newCloneAddress,
        _roleAdmin,
        _approvedPaymentToken,
        _approvedSweepingToken,
        _approvedTokenSweepRecipient,
        _defaultTokenAmount
      );
    }

    // admin functions

    function setClonableReferenceValidity(
      address _referenceContract,
      bool _validity
    ) external onlyOwner {
      require(_referenceContract != address(0), "INVALID_REFERENCE_CONTRACT");
      validClonableReferences[_referenceContract] = _validity;
      emit SetClonableReferenceValidity(_referenceContract, _validity);
    }

    function setApprovedCloner(
      address _clonerAddress,
      address _clonableReference,
      bool _validity
    ) external onlyOwner {
      approvedCloner[_clonerAddress] = _validity;
      require(validClonableReferences[_clonableReference], "INVALID_REFERENCE_CONTRACT");
      approvedClonerClonableReference[_clonerAddress] = _clonableReference;
      emit SetClonerValidity(_clonerAddress, _clonableReference, _validity);
    }

}
