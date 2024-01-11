//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Addrs {
  address internal constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // ON ETHER OR EVERYWHERE ?
  address internal constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac; // ON ETHER
//  address internal constant SUSHI_FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4; // ON MOVR
//  address internal constant ANYSWAP_ETH_TO_MOVR_BRIDGE = 0x10c6b61DbF44a083Aec3780aCF769C77BE747E23;
//  address internal constant ANYCALLPROXY_ON_ETHER = 0x37414a8662bC1D25be3ee51Fb27C2686e2490A89;
}

library Selectors {
  bytes4 internal constant UNISWAP_V2_GETPAIR_SELECTOR = bytes4(keccak256("getPair(address,address)"));
  bytes4 internal constant UNISWAP_V2_GETRESERVES_SELECTOR = bytes4(keccak256("getReserves()"));

  bytes4 internal constant UNISWAP_V2_PAIR_SWAP_SELECTOR = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));

  uint internal constant SLIPPAGE_LIMIT = 200;
//  bytes4 internal constant ANYCALLPROXY_ANYCALL_SELECTOR = bytes4(keccak256("anyCall(address,bytes,address,uint256)"));

  bytes4 internal constant TRANSFER_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
  bytes4 internal constant TRANSFERFROM_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));
  bytes4 internal constant BALANCEOF_SELECTOR = bytes4(keccak256("balanceOf(address)"));
}
