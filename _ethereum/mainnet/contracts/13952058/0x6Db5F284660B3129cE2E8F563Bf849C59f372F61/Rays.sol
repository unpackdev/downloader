// Copyright (c) 2021-2022 MCH Co., Ltd.
pragma solidity ^0.8.4;

import "./ERC20Burnable.sol";
import "./Mintable.sol";

contract Rays is ERC20Burnable, Mintable {
    event Minted(address to, uint256 amount);

    constructor() ERC20("RAYS", "RAYS") {
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
        emit Minted(to, amount);
    }
}
