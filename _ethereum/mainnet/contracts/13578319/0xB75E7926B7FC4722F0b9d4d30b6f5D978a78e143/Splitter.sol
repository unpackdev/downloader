//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "./Ownable.sol";


contract Splitter is Ownable {

    address[] public beneficiaries;
    mapping(address => bool) public beneficiarySet;
    mapping(address => uint8) public allocations; // the absolute value of these don't matter, just their relative values

    uint8 public numBeneficiaries;
    uint8 public sumAllocations;


    constructor(address owner_) {
        transferOwnership(owner_);
    }

    function setAllocation(address beneficiary, uint8 allocation) external onlyOwner {
        if (beneficiarySet[beneficiary]) {
            if (allocations[beneficiary] <= allocation) {
                sumAllocations += allocation - allocations[beneficiary];
            } else {
                sumAllocations -= allocations[beneficiary] - allocation;
            }
        } else {
            beneficiaries.push(beneficiary);
            beneficiarySet[beneficiary] = true;
            numBeneficiaries++;
            sumAllocations += allocation;
        }
        allocations[beneficiary] = allocation;

    }

    receive() external payable {
        _split();
    }

    fallback() external payable {
        _split();
    }

    function _split() internal {
        uint256 bal = address(this).balance;
        for (uint i = 0; i < numBeneficiaries; i++) {
            payable(beneficiaries[i]).transfer(bal * allocations[beneficiaries[i]] / sumAllocations);
        }
    }
}
