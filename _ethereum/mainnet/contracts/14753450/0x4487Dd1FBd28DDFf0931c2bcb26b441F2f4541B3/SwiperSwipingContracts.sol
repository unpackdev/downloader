//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

import "./SwiperSwipingState.sol";

abstract contract SwiperSwipingContracts is Initializable, SwiperSwipingState {

    function __SwiperSwipingContracts_init() internal initializer {
        SwiperSwipingState.__SwiperSwipingState_init();
    }

    function setContracts(address _wndAddress, address _tower1Address, address _tower2Address) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        wnd = IWnDRoot(_wndAddress);
        tower1Address = _tower1Address;
        tower2Address = _tower2Address;
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(wnd) != address(0) && tower1Address != address(0) && tower2Address != address(0);
    }
}