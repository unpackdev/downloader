// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ERC20.sol";

contract GREEN is ERC20 {

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _mint(msg.sender, 1_000_000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function name() public view virtual override returns (string memory) {
        return "GREEN";
    }
    
    function symbol() public view virtual override returns (string memory) {
        return "GREEN";
    }
}