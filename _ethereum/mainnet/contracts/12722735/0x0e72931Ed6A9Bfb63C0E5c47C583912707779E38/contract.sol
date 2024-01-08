// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";

contract RBI is ERC20 {
    constructor() ERC20('Rainbow Inu','RBI') {
        _mint(0xdbF9f9A56a46dFdb97706487Fa7BFD120D942D29, 10000000000000 *10**18);
    }
}