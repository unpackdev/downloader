// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./ERC20.sol";

contract LpToken is ERC20 {
    error Forbidden();
    address public owner;
    string private _name;
    string private _symbol;

    constructor() ERC20("LpToken", "MLP") {}

    function initialize(string memory name_, string memory symbol_, address owner_) external {
        _name = name_;
        _symbol = symbol_;
        owner = owner_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != owner) revert Forbidden();
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        if (msg.sender != owner) revert Forbidden();
        _burn(to, amount);
    }

    function clone(string memory name_, string memory symbol_, address owner_) external returns (LpToken lpToken) {
        lpToken = LpToken(Clones.cloneDeterministic(address(this), bytes32(abi.encode(owner_, bytes12(0)))));
        lpToken.initialize(name_, symbol_, owner_);
    }
}
