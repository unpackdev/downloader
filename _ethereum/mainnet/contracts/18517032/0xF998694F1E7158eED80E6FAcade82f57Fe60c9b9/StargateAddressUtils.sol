// commit 427ad29973083a8d6910314bbe8eb781e9c80166
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

function getAddresses() view returns (address stakingPool, address router, address factory) {
    uint256 chainId = block.chainid;
    if (chainId == 1) {
        stakingPool = 0xB0D502E938ed5f4df2E681fE6E419ff29631d62b;
        router = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
        factory = 0x06D538690AF257Da524f25D0CD52fD85b1c2173E;
    } else if (chainId == 56) {
        stakingPool = 0x3052A0F6ab15b4AE1df39962d5DdEFacA86DaB47;
        router = 0x4a364f8c717cAAD9A442737Eb7b8A55cc6cf18D8;
        factory = 0xe7Ec689f432f29383f217e36e680B5C855051f25;
    } else if (chainId == 43114) {
        stakingPool = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
        router = 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd;
        factory = 0x808d7c71ad2ba3FA531b068a2417C63106BC0949;
    } else if (chainId == 137) {
        stakingPool = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
        router = 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd;
        factory = 0x808d7c71ad2ba3FA531b068a2417C63106BC0949;
    } else if (chainId == 42161) {
        stakingPool = 0xeA8DfEE1898a7e0a59f7527F076106d7e44c2176;
        router = 0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614;
        factory = 0x55bDb4164D28FBaF0898e0eF14a589ac09Ac9970;
    } else if (chainId == 10) {
        stakingPool = 0x4DeA9e918c6289a52cd469cAC652727B7b412Cd2;
        router = 0xB0D502E938ed5f4df2E681fE6E419ff29631d62b;
        factory = 0xE3B53AF74a4BF62Ae5511055290838050bf764Df;
    } else if (chainId == 250) {
        stakingPool = 0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03;
        router = 0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6;
        factory = 0x9d1B1669c73b033DFe47ae5a0164Ab96df25B944;
    } else {
        revert("no chain id is matched");
    }
}



function getRouterETHAddresses() view returns (address routerETH) {
    uint256 chainId = block.chainid;
    if (chainId == 1) {
        routerETH = 0x150f94B44927F078737562f0fcF3C95c01Cc2376;
    } else if (chainId == 42161) {
        routerETH = 0xbf22f0f184bCcbeA268dF387a49fF5238dD23E40;
    } else if (chainId == 10) {
        routerETH = 0xB49c4e680174E331CB0A7fF3Ab58afC9738d5F8b;
    } else if (chainId == 8453) {
        routerETH = 0x50B6EbC2103BFEc165949CC946d739d5650d7ae4;
    } else if (chainId == 59144) {
        routerETH = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
    } else {
        revert("no chain id is matched");
    }
}
