// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";

contract Erc20C17SettingsBase is
Ownable
{
    // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    // 115792089237316195423570985008687907853269984665640564039457584007913129639935
    uint256 internal constant maxUint256 = type(uint256).max;
    address internal constant addressPinkSaleLock = address(0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE);
    address internal constant addressUnicryptLock = address(0x663A5C229c09b049E36dCc11a9B0d4a8Eb9db214);
    address internal constant addressNull = address(0x0);
    address internal constant addressDead = address(0xdead);

    address public addressMarketing;

    address internal addressBaseOwner;
    address internal addressWETH;

    function setAddressMarketing(address addressMarketing_)
    external
    onlyOwner
    {
        addressMarketing = addressMarketing_;
    }
}
