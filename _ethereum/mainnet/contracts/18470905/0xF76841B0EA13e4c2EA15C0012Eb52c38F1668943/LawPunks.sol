//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721ConsecutiveAdjusted.sol";

/*================================================================================*
 *          ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗███╗   ██╗ ██████╗
 *          ██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝████╗  ██║██╔════╝
 *          ██████╔╝██║     ██║   ██║██║     █████╔╝ ██╔██╗ ██║██║  ███╗
 *          ██╔══██╗██║     ██║   ██║██║     ██╔═██╗ ██║╚██╗██║██║   ██║
 *          ██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗██║ ╚████║╚██████╔╝
 *          ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝
 *      ╔═╗┌─┐┌─┐┬┌─┐┬┌─┐┬   ┌─────────────────────────┐ ╦ ╦┌─┐┌┐ ╔═╗┬┌┬┐┌─┐
 *      ║ ║├┤ ├┤ ││  │├─┤│   │  https://blockng.money  │ ║║║├┤ ├┴┐╚═╗│ │ ├┤
 *      ╚═╝└  └  ┴└─┘┴┴ ┴┴─┘ └─────────────────────────┘ ╚╩╝└─┘└─┘╚═╝┴ ┴ └─┘
 *================================================================================*/
contract LawPunks is ERC721ConsecutiveAdjusted, Ownable {
    string public baseURI;
    uint public constant totalSupply = 10000;

    constructor(address bridge) ERC721("LawPunks:Trek", "LAWPUNK"){
        for (uint i = 0; i < 20; i++) {
            _mintConsecutive(bridge, uint96(500));
        }
    }

    function setBaseURI(string memory baseURI_) onlyOwner public {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}