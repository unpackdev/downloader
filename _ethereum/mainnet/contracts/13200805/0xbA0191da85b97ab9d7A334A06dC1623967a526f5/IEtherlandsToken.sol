//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

interface IEtherlandsToken is IERC20Upgradeable {


    function initialize(string memory _name, string memory _symbol) external;
    function setPaused(bool pause) external;
    function adminMint(address to, uint256 amount) external;
    function adminBurn(address from, uint256 amount) external;




}
