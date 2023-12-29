pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./LibOrder.sol";
import "./ISetAllowance.sol";

interface IPMM is ISetAllowance {
    function fill(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    ) external payable returns (uint256);
}