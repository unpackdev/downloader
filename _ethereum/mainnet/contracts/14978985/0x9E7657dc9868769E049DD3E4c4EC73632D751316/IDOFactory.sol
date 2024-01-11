// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IIDOAllowance.sol";
import "./ISharedData.sol";
import "./Whitelist.sol";
import "./IDOProxy.sol";

contract IDOFactory is Whitelist, ISharedData {
    uint256 public idoId;
    uint256 public idoAllowanceId;
    address[] public IDOs;
    address[] public implementations;

    event CreateIDO(address indexed ido, uint256 id);

    modifier paramsVerification(IDOParams memory params) {
        require(
            params._minimumContributionLimit <=
                params._maximumContributionLimit,
            "Minimum Contribution Limit should be lower or equel than Maximum Contribution Limit"
        );
        require(
            params._softCap <= params._hardCap,
            "softCap should be lower or equel than hardCap"
        );
        require(
            params._startDepositTime < params._endDepositTime,
            "Start Deposit Time should be lower or equel than End Deposit Time"
        );

        require(params._vestingInfo.length > 0, "vesting Info needed");

        require(
            params._vestingInfo[0]._time >= params._endDepositTime,
            "Start Claim Time should be more than End Deposit Time"
        );

        if (params._vestingInfo.length > 1) {
            for (
                uint256 index = 0;
                index < params._vestingInfo.length - 1;
                index++
            ) {
                require(
                    params._vestingInfo[index + 1]._time >
                        params._vestingInfo[index]._time,
                    "Start Claim Time should be lower or equel than End Deposit Time"
                );
            }
        }

        require(
            params._maximumContributionLimit <= params._hardCap,
            "Maximum Contribution Limit should be lower or equel than Hard Cap"
        );
        _;
    }

    function initialize(address owner) public initializer {
        __Whitelist_init(owner);
        managerAdd(owner);
        idoId = 0;
        idoAllowanceId = 1;
    }

    function createIDOContract(IDOParams memory params)
        external
        onlyManager
        whenNotPaused
        paramsVerification(params)
        onlyWhitelist(params._tokenAddress)
    {
        address[] memory allowances = params._allowance;
        address newIDO;
        if (allowances.length > 0) {
            newIDO = address(
                new IDOProxy(implementations[idoAllowanceId], owner())
            );
            IIDOAllowance(newIDO).initialize(params);
        } else {
            newIDO = address(new IDOProxy(implementations[idoId], owner()));
            IIDO(newIDO).initialize(params);
        }
        IDOs.push(newIDO);

        emit CreateIDO(newIDO, IDOs.length - 1);
    }

    function setIdoId(uint256 id) public onlyManager {
        idoId = id;
    }

    function setIdoAllowanceId(uint256 id) public onlyManager {
        idoAllowanceId = id;
    }

    function addImplementation(address _address) public onlyManager {
        implementations.push(_address);
    }
}
