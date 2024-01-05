// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

abstract contract IFeeRecipient {
    function getFeeAddr() public view virtual returns (address);
    function changeWalletAddr(address _newWallet) public virtual;
}
