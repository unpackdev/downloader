//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract AOPM is ERC20Burnable, Ownable {
    constructor(address _ownerAddress)
        ERC20("Open Platform Metaversity", "OPM")
        Ownable()
    {
        _mint(_ownerAddress, 30000000 ether);
        _transferOwnership(_ownerAddress);
    }
}
