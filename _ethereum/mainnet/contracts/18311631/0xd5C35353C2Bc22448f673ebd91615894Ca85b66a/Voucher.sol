// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC20.sol";

abstract contract Voucher is ERC20 {
    address private _factory;
    mapping(address => bool) private _pools;

    modifier onlyPool() {
        require(isPool(_msgSender()), "Must be Pool");
        _;
    }

    modifier onlyFactory() {
        require(_msgSender() == _factory, "Must be Factory");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address factory_
    ) ERC20(name_, symbol_) {
        _factory = factory_;
    }

    function factory() public view returns (address) {
        return _factory;
    }

    function isPool(address p) public view returns (bool) {
        return _pools[p];
    }

    function mint(address account, uint256 value) external onlyPool {
        _mint(account, value);

        emit Mint(account, value);
    }

    function burn(address account, uint256 value) external onlyPool {
        _burn(account, value);

        emit Burn(account, value);
    }

    function addPool(address account) external onlyFactory {
        _pools[account] = true;
    }
}
