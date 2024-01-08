// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

interface IController {

    function dao() external view returns (address);

    function guardian() external view returns (address);

    function isDaoOrGuardian(address sender) external view returns (bool);

    function setDao(address _dao) external returns (bool);

    function setGuardian(address _guardian) external returns (bool);

    function feesOwner() external view returns (address);

    function pausedIssuance() external view returns (bool);

    function setFeesOwner(address _feesOwner) external returns (bool);

    function setPausedIssuance(bool _pausedIssuance) external returns (bool);
}
