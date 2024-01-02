//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AdminControl.sol";
import "./ISFTDelegateControl.sol";

abstract contract SFTDelegateControl is ISFTDelegateControl, AdminControl {
    address private _concrete;

    function __SFTDelegateControl_init(address concrete_) internal onlyInitializing {
        __AdminControl_init_unchained(_msgSender());
        __SFTDelegateControl_init_unchained(concrete_);
    }

    function __SFTDelegateControl_init_unchained(address concrete_) internal onlyInitializing {
        _concrete = concrete_;
    }

    function concrete() public view override returns (address) {
        return _concrete;
    }

    function setConcreteOnlyAdmin(address newConcrete_) external override onlyAdmin {
        emit NewConcrete(_concrete, newConcrete_);
        _concrete = newConcrete_;
    }

	uint256[49] private __gap;
}