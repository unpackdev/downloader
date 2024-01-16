// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: ENVY HYENARS
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract EH is ERC721Community {
    constructor() ERC721Community("ENVY HYENARS", "EH", 5555, 100, START_FROM_ONE, "ipfs://bafybeifrcurmgy6tyhgq66gsplg73cy3mla6xczyoauvwhesjrzstmp4gu/",
                                  MintConfig(0 ether, 10, 10, 0, 0x3c7FBb1c384535abd325fC16ba5Fa4983Ff0F96E, false, false, false)) {}
}
