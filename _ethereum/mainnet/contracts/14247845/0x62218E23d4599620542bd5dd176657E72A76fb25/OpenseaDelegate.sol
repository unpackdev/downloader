// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/

//solhint-disable-next-line no-empty-blocks
contract OwnableDelegateProxy {

}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}
