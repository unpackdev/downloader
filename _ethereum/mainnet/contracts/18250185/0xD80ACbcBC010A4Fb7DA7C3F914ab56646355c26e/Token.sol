/*
verified on 2023-09-30
*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Mintable.sol";

contract POWER_OF_LOVE is ERC20, ERC20Burnable, Ownable, Mintable {
      
    constructor()
        ERC20(unicode"POWER OF LOVE", unicode"PLOV") 
        Mintable(90000000000)
    {
        address supplyRecipient = 0xe15B68B0Cb08C76Fd81E6D5856A9824662257df1;
        
        _mint(supplyRecipient, 80000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xe15B68B0Cb08C76Fd81E6D5856A9824662257df1);
    }
    
    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (from == address(0)) {
        }

        super._afterTokenTransfer(from, to, amount);
    }
}
