// SPDX-License-Identifier: MIT
//  UBD ERC20 


pragma solidity 0.8.21;

import "ERC20.sol";

contract UBDToken is ERC20 {

    address immutable public minter; // sale contract

    constructor(address _minter)
        ERC20("United Blockchain Dollar", "UBD")
    { 
        minter = _minter;

    }

    function mint(address _to, uint256 _amount) external {
        require(msg.sender == minter, 'Only exchange contract');
         _mint(_to, _amount);
    }

    
    function burn(address _burnFor, uint256 _amount) external {
        require(msg.sender == minter, 'Only exchange contract');
        _burn(_burnFor, _amount);
    }
    
}

