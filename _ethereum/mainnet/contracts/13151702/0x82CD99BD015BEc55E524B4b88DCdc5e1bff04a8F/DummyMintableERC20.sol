
// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC20.sol";


contract DummyMintableERC20 is ERC20
{
    address public immutable predicateProxy;
    constructor(string memory name_, string memory symbol_, address predicateProxy_)
        ERC20(name_, symbol_)
    {
        predicateProxy = predicateProxy_;
    }

    function mint(address account, uint256 amount) external  {
        require(msg.sender == predicateProxy, 'ONLY_PREDICATE_PROXY');
        _mint(account,amount);
    }
    function burn(address account, uint256 amount) external  {
        _burn(account,amount);
    }
}
