// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferRules {
    function setSRC(address src20) external returns (bool);
    
    function doTransfer(address from, address to, uint256 value) external returns (bool);
}

