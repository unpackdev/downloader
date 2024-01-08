// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./draft-ERC20PermitUpgradeable.sol";


contract DummyMintableERC20 is ERC20PermitUpgradeable {
    address public predicateProxy;

    function initialize(
        string memory name_,
        string memory symbol_,
        address predicateProxy_
    ) public initializer {
        require(
            predicateProxy_ != address(0),
            "new predicateProxy is the zero address"
        );
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        predicateProxy = predicateProxy_;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == predicateProxy, "ONLY_PREDICATE_PROXY");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
