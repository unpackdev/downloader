// SPDX-License-Identifier: CC0 1.0 Universal

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.19;

struct Wawa {
    Trait trait;
    string tokenURI;
    Faction faction;
    uint8 petId;
    bytes32 gene;
}

struct Trait {
    uint8 headwear;
    uint8 eyes;
    uint8 chest;
    uint8 legs;
}

enum Faction {
    Prima,
    Zook,
    Mecha,
    Flavo
}
