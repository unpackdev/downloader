// SPDX-License-Identifier: MIT
/*



    ███████╗██╗   ██╗███╗   ██╗████████╗██╗  ██╗██████╗ ████████╗ ██╗ ██████╗
    ██╔════╝╚██╗ ██╔╝████╗  ██║╚══██╔══╝██║  ██║╚════██╗╚══██╔══╝███║██╔════╝
    ███████╗ ╚████╔╝ ██╔██╗ ██║   ██║   ███████║ █████╔╝   ██║   ╚██║██║     
    ╚════██║  ╚██╔╝  ██║╚██╗██║   ██║   ██╔══██║ ╚═══██╗   ██║    ██║██║     
    ███████║   ██║   ██║ ╚████║   ██║   ██║  ██║██████╔╝   ██║    ██║╚██████╗
    ╚══════╝   ╚═╝   ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═════╝    ╚═╝    ╚═╝ ╚═════╝
                                                                         
    synth3t1c



*/


pragma solidity ^0.8.7;

import "./ERC721Custom.sol";
import "./Pausable.sol";

contract SYNTH3T1C is Pausable, ERC721 {

    uint16 public constant FANATICS = (3-1) ** ((1*(2**3) + 2) + 3);

    constructor() ERC721(
        "synth3t1c.xyz",
        "synth3t1c",
        FANATICS)
    {

    }

    function Mint(uint256 amount, address to) external onlyControllers whenNotPaused {
        for (uint256 i = 0; i < amount; i++ ){
            _mint(to);
        }
    }

}