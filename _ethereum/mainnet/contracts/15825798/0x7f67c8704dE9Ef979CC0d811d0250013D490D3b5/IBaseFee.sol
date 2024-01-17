// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IBaseFee {
    function isCurrentBaseFeeAcceptable() external view returns (bool);
}
