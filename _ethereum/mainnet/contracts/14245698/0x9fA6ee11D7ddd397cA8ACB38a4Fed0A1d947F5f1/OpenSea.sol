// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// solhint-disable-next-line no-empty-blocks
contract OSOwnableDelegateProxy {

}

contract OSProxyRegistry {
    mapping(address => OSOwnableDelegateProxy) public proxies;
}
