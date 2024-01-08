//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TalentumToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Talentum", "TAL") {}

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function mint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }
}
