// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./ERC20.sol";

import "./IxTrippyToken.sol";

contract xTrippyToken is IxTrippyToken, ERC20 {
    address public stakingContract;

    modifier onlyTrippyStaking() {
        require(
            stakingContract == _msgSender(),
            "xTrippyToken: permission denied"
        );
        _;
    }

    constructor(address _stakingContract, uint256 _initialSupply)
        ERC20("Trippy Chips", "$Chips")
    {
        stakingContract = _stakingContract;
        _mint(_msgSender(), _initialSupply);
    }

    function mint(address account, uint256 amount)
        public
        override
        onlyTrippyStaking
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        public
        override
        onlyTrippyStaking
    {
        _burn(account, amount);
    }
}
