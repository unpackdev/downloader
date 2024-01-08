//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";

contract BackedToken is ERC20, ERC20Detailed, Ownable {
    
    bool _unlocked;
    address private _ownerToken;

    constructor() public ERC20() ERC20Detailed("BACKED", "BAKT", 18) {
        _mint(msg.sender, 100000000 * 10**18);
        _ownerToken = msg.sender;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(_unlocked || from == _ownerToken, "token transfer while locked");
        super._transfer(from, to, amount);
    }

    function unlock() external onlyOwner {
        _unlocked = true;
    }
}
