//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DragonsVault.sol";

contract MarketingVault is DragonsVault {
    constructor(address _tokenAddress)
        DragonsVault("Marketing", _tokenAddress)
    {}
}
