//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DragonsVault.sol";

contract EcosystemVault is DragonsVault {
    constructor(address _tokenAddress)
        DragonsVault("Ecosystem", _tokenAddress)
    {}
}
