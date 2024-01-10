// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";

interface ISeedToken is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _to, uint256 _amount) external;
}
