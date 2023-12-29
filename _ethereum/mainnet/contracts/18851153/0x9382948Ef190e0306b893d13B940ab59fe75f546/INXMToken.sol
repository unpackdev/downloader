// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./IERC20.sol";

interface INXMToken is IERC20 {
    function burn(uint256 amount) external returns (bool);

    function burnFrom(address from, uint256 value) external returns (bool);

    function operatorTransfer(address from, uint256 value) external returns (bool);

    function mint(address account, uint256 amount) external;

    function addToWhiteList(address _member) external returns (bool);

    function removeFromWhiteList(address _member) external returns (bool);

    function changeOperator(address _newOperator) external returns (bool);

    function lockForMemberVote(address _of, uint256 _days) external;
}
