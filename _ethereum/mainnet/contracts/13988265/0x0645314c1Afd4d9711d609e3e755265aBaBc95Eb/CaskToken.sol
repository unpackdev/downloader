// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract CaskToken is ERC20, Ownable {
    using Address for address;

    constructor() ERC20("Cask Token", "CASK") {
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        if(totalSupply() == 0){
            // one shot, one opportunity. moms spaghetti.
            _mint(_to,_amount);
            renounceOwnership();
            return;
        }
    }

}