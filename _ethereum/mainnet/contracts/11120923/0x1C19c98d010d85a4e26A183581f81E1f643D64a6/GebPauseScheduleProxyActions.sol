/// GebPauseScheduleProxyActions.sol

// Copyright (C) 2018 Gonzalo Balabasquer <gbalabasquer@gmail.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.7;

abstract contract PauseLike {
    function scheduleTransaction(address, bytes32, bytes memory, uint) virtual public;
}

contract GebPauseScheduleProxyActions {
    function modifyParameters(address pause, address actions, address who, bytes32 parameter, uint data, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,uint256)", who, parameter, data),
            earliestExecutionTime
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 parameter, int data, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,int256)", who, parameter, data),
            earliestExecutionTime
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 parameter, address data, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,address)", who, parameter, data),
            earliestExecutionTime
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 collateralType, bytes32 parameter, uint data, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,bytes32,uint256)", who, collateralType, parameter, data),
            earliestExecutionTime
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 collateralType, bytes32 parameter, address data, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,bytes32,address)", who, collateralType, parameter, data),
            earliestExecutionTime
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 collateralType, uint data1, uint data2, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,uint256,uint256)", who, collateralType, data1, data2),
            earliestExecutionTime
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 collateralType, uint data1, uint data2, address data3, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,uint256,uint256,address)", who, collateralType, data1, data2, data3),
            earliestExecutionTime
        );
    }

    function setDummyPIDValidator(address pause, address actions, address rateSetter, address oracleRelayer, address dummyValidator, uint earliestExecutionTime) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setDummyPIDValidator(address,address,address)", rateSetter, oracleRelayer, dummyValidator),
            earliestExecutionTime
        );
    }

    function addReader(address pause, address actions, address validator, address reader, uint earliestExecutionTime) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("addReader(address,address)", validator, reader),
            earliestExecutionTime
        );
    }

    function removeReader(address pause, address actions, address validator, address reader, uint earliestExecutionTime) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("removeReader(address,address)", validator, reader),
            earliestExecutionTime
        );
    }

    function addAuthority(address pause, address actions, address validator, address account, uint earliestExecutionTime) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("addAuthority(address,address)", validator, account),
            earliestExecutionTime
        );
    }

    function removeAuthority(address pause, address actions, address validator, address account, uint earliestExecutionTime) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("removeAuthority(address,address)", validator, account),
            earliestExecutionTime
        );
    }

    function changePriceSource(address pause, address actions, address fsm, address priceSource, uint earliestExecutionTime) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("changePriceSource(address,address)", fsm, priceSource),
            earliestExecutionTime
        );
    }

    function stopFsm(address pause, address actions, address fsmGovInterface, bytes32 collateralType, uint earliestExecutionTime) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("stopFsm(address,bytes32)", fsmGovInterface, collateralType),
            earliestExecutionTime
        );
    }

    function start(address pause, address actions, address fsm, uint earliestExecutionTime) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("start(address)", fsm),
            earliestExecutionTime
        );
    }

    function changeNextPriceDeviation(address pause, address actions, address fsm, uint deviation, uint earliestExecutionTime) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("changeNextPriceDeviation(address,uint256)", fsm, deviation),
            earliestExecutionTime
        );
    }

    function modifyTwoParameters(
      address pause,
      address actions,
      address who1,
      address who2,
      bytes32 collateralType1,
      bytes32 collateralType2,
      bytes32 parameter1,
      bytes32 parameter2,
      uint data1,
      uint data2,
      uint earliestExecutionTime
    ) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyTwoParameters(address,address,bytes32,bytes32,bytes32,bytes32,uint256,uint256)", who1, who2, collateralType1, collateralType2, parameter1, parameter2, data1, data2),
            earliestExecutionTime
        );
    }

    function modifyTwoParameters(
      address pause,
      address actions,
      address who1,
      address who2,
      bytes32 parameter1,
      bytes32 parameter2,
      uint data1,
      uint data2,
      uint earliestExecutionTime
    ) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyTwoParameters(address,address,bytes32,bytes32,uint256,uint256)", who1, who2, parameter1, parameter2, data1, data2),
            earliestExecutionTime
        );
    }

    function removeAuthorizationAndModify(
      address pause,
      address actions,
      address who,
      address to,
      bytes32 parameter,
      uint data,
      uint earliestExecutionTime
    ) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("removeAuthorizationAndModify(address,address,bytes32,uint256)", who, to, parameter, data),
            earliestExecutionTime
        );
    }

    function removeAuthorization(address pause, address actions, address who, address to, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("removeAuthorization(address,address)", who, to),
            earliestExecutionTime
        );
    }

    function addAuthorization(address pause, address actions, address who, address to, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("addAuthorization(address,address)", who, to),
            earliestExecutionTime
        );
    }

    function updateRedemptionRate(address pause, address actions, address who, bytes32 parameter, uint data, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("updateRedemptionRate(address,bytes32,uint256)", who, parameter, data),
            earliestExecutionTime
        );
    }

    function updateRateAndModifyParameters(address pause, address actions, address who, bytes32 parameter, uint data, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("updateRateAndModifyParameters(address,bytes32,uint256)", who, parameter, data),
            earliestExecutionTime
        );
    }

    function taxSingleAndModifyParameters(address pause, address actions, address who, bytes32 collateralType, bytes32 parameter, uint data, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("taxSingleAndModifyParameters(address,bytes32,bytes32,uint256)", who, collateralType, parameter, data),
            earliestExecutionTime
        );
    }

    function setTotalAllowance(address pause, address actions, address who, address account, uint rad, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setTotalAllowance(address,address,uint256)", who, account, rad),
            earliestExecutionTime
        );
    }

    function setPerBlockAllowance(address pause, address actions, address who, address account, uint rad, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setPerBlockAllowance(address,address,uint256)", who, account, rad),
            earliestExecutionTime
        );
    }

    function setAuthorityAndDelay(address pause, address actions, address newAuthority, uint newDelay, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setAuthorityAndDelay(address,address,uint256)", pause, newAuthority, newDelay),
            earliestExecutionTime
        );
    }

    function shutdownSystem(address pause, address actions, address globalSettlement, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("shutdownSystem(address)", globalSettlement),
            earliestExecutionTime
        );
    }

    function setProtester(address pause, address actions, address protester, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setProtester(address,address)", pause, protester),
            earliestExecutionTime
        );
    }

    function setDelay(address pause, address actions, uint newDelay, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setDelay(address,uint256)", pause, newDelay),
            earliestExecutionTime
        );
    }

    function setDelayMultiplier(address pause, address actions, uint delayMultiplier, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setDelayMultiplier(address,uint256)", pause, delayMultiplier),
            earliestExecutionTime
        );
    }

    function setAllowance(address pause, address actions, address join, address account, uint allowance, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setAllowance(address,address,uint256)", join, account, allowance),
            earliestExecutionTime
        );
    }

    function multiSetAllowance(address pause, address actions, address join, address[] calldata accounts, uint[] calldata allowances, uint earliestExecutionTime) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("multiSetAllowance(address,address[],uint256[])", join, accounts, allowances),
            earliestExecutionTime
        );
    }
}