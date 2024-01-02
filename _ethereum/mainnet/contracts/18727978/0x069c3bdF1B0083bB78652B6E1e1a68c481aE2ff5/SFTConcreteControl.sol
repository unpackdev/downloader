// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AdminControl.sol";
import "./ISFTConcreteControl.sol";

abstract contract SFTConcreteControl is ISFTConcreteControl, AdminControl {
    address private _delegate;

    modifier onlyDelegate() {
        require(_msgSender() == _delegate, "only delegate");
        _;
    }

    function __SFTConcreteControl_init() internal onlyInitializing {
        __AdminControl_init_unchained(_msgSender());
        __SFTConcreteControl_init_unchained();
    }

    function __SFTConcreteControl_init_unchained() internal onlyInitializing {}

    function delegate() public view override returns (address) {
        return _delegate;
    }

    function setDelegate(address newDelegate_) external override {
        if (_delegate != address(0)) {
            require(_msgSender() == admin, "only admin");
        }

        emit NewDelegate(_delegate, newDelegate_);
        _delegate = newDelegate_;
    }

	uint256[49] private __gap;
}
