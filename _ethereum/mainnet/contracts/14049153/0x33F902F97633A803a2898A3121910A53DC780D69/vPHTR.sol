// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

import "./IERC20.sol";

import "./IvPHTR.sol";
import "./IePHTR.sol";

contract vPHTR is IvPHTR {
    address public override ePHTR;
    address public override PHTR;

    constructor(address _PHTR, address _ePHTR) {
        require(_PHTR != address(0) && _ePHTR != address(0), "vPHTR: ZERO");

        PHTR = _PHTR;
        ePHTR = _ePHTR;
    }

    function balanceOf(address account) external view override returns (uint) {
        return
            IERC20(PHTR).balanceOf(account) +
            IePHTR(ePHTR).withdrawableAmount(IERC20(ePHTR).balanceOf(account));
    }
}
