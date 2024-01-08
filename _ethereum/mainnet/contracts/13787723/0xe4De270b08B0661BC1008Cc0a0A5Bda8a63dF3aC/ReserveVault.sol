//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DragonsVault.sol";

contract ReserveVault is DragonsVault {
    constructor(address _tokenAddress)
        DragonsVault("Reserve", _tokenAddress)
    {}
}
