// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./IPilgrimTreasury.sol";

import "./IERC20.sol";

contract PilgrimTreasury is IPilgrimTreasury {
    address public pil;
    mapping(address => bool) public whiteList;

    constructor (address _pil, address[] memory _addrs) {
        pil = _pil;

        for (uint256 i; i < _addrs.length; i++) {
            whiteList[_addrs[i]] = true;
        }
    }

    function withdraw(address _to, uint256 _amount) external override {
        require(whiteList[msg.sender]);
        require(IERC20(pil).transfer(_to, _amount));
    }
}
