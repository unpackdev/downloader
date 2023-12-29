// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract FilxAir is ERC20, Ownable {
    address public airdrop;

    constructor() ERC20("filx-air", "FILA") Ownable(msg.sender) {}

    function mint(uint256 amount) public onlyOwner {
        _mint(airdrop, amount);
    }

    function setAirdrop(address newAirdrop) public onlyOwner {
        airdrop = newAirdrop;
        emit AirdropChanged(newAirdrop);
    }

    event AirdropChanged(address newAirdrop);
}
