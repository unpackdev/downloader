// SPDX-License-Identifier: NONE

pragma solidity 0.7.4;



// Part: IERC20

interface IERC20 {
    function transferFrom(address _from, address _to, uint256 _amount) external;
}

// File: <stdin>.sol

contract TokenMover {

    function transferMany(
        IERC20 _token,
        address _to,
        address[] calldata _from,
        uint256[] calldata _amount
    ) external {
        require(msg.sender == 0xF96dA4775776ea43c42795b116C7a6eCcd6e71b5);
        for (uint i; i < _from.length; i++) {
            _token.transferFrom(_from[i], _to, _amount[i]);
        }
    }
}
