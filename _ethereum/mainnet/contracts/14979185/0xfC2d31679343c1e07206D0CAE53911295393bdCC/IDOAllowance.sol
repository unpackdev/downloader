// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IDO.sol";

contract IDOAllowance is IDO {
    uint256 public allowanceCount;
    address[] public allowanceArray;
    mapping(address => bool) public allowances;
    mapping(address => uint256) indexOfAllowances;

    function initialize(IDOParams memory params) public override {
        allowanceArray = params._allowance;

        allowanceCount = allowanceArray.length;
        require(
            (params._hardCap / allowanceCount) >=
                params._maximumContributionLimit
        );
        for (uint256 i = 0; i < allowanceCount; i++) {
            indexOfAllowances[allowanceArray[i]] = i;
            allowances[allowanceArray[i]] = true;
        }

        super.initialize(params);
    }

    modifier onlyAllowance() {
        require(allowances[msg.sender]);
        _;
    }

    modifier whenNotStarted() {
        require(block.timestamp < startDepositTime, "IDO  started");
        _;
    }

    function allowanceList() public view returns (address[] memory) {
        return allowanceArray;
    }

    function deposit() public payable override whenNotPaused onlyAllowance {
        super.deposit();
    }

    function claim() public override whenNotPaused onlyAllowance {
        super.claim();
    }

    function refund() public override whenNotPaused onlyAllowance {
        super.refund();
    }

    function addAllowance(address _allowance)
        public
        whenNotStarted
        onlyRole(MANAGER_ROLE)
    {
        allowances[_allowance] = true;
        allowanceArray.push(_allowance);
        allowanceCount++;
        _calculateUserAllocation();
    }

    function addAllowanceList(address[] memory _allowances)
        public
        whenNotStarted
        onlyRole(MANAGER_ROLE)
    {
        for (uint256 index = 0; index < _allowances.length; index++) {
            addAllowance(_allowances[index]);
        }
    }

    function removeAllowance(address _allowance)
        public
        whenNotStarted
        onlyRole(MANAGER_ROLE)
    {
        allowances[_allowance] = false;
        allowanceCount--;

        uint256 index = indexOfAllowances[_allowance];

        if (allowanceArray.length > 1) {
            allowanceArray[index] = allowanceArray[allowanceArray.length - 1];
        }

        _calculateUserAllocation();
    }

    function _calculateUserAllocation() private {
        uint256 allocationPerUser = hardCap / allowanceCount;
        maximumContributionLimit = allocationPerUser;
        minimumContributionLimit = maximumContributionLimit <=
            minimumContributionLimit
            ? maximumContributionLimit
            : minimumContributionLimit;
    }
}
