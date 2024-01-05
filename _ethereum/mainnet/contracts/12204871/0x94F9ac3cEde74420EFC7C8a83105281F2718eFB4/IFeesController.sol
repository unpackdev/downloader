// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.6;

abstract contract IFeesController {
    function feesTo() public virtual returns (address);
    function setFeesTo(address) public virtual;

    function feesPpm() public virtual returns (uint);
    function setFeesPpm(uint) public virtual;
}
