//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

uint256 constant targetSupply = 250 * 1e6 * 1e18; // 250 million tokens

contract META is ERC20, ERC20Burnable, Ownable {
    bool private initialized = false;

    constructor() ERC20("METAVERSE", "META") {
        mint(msg.sender, targetSupply);
    }

    function mint(address _beneficiary, uint256 _amount) public onlyOwner notInitialized {
        _mint(_beneficiary, _amount);
    }

    function removeContract() public onlyOwner notInitialized {
        selfdestruct(payable(owner()));
    }

    function initialize() public onlyOwner notInitialized {
        initialized = true;
    }

    modifier notInitialized {
        require(!initialized);
        _;
    }
}
