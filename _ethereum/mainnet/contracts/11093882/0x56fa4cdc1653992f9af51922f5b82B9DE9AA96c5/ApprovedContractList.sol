pragma solidity ^0.6.0;

import "./Ownable.sol";

/*
    Approve Contracts to interact with pools.
    (All contracts are barred from interacting with pools by default.)
*/
contract ApprovedContractList is Ownable {
    mapping (address => bool) approved;
    function isApproved(address toCheck) external returns (bool) {
        return approved[toCheck];
    }
    function approveContract(address toApprove) external onlyOwner {
        approved[toApprove] = true;
    }

    function revokeContract(address toRevoke) external onlyOwner {
        approved[toRevoke] = false;
    }
}