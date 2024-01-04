// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";

interface IMintable {

    function mintTo(address to, uint256 amount) external returns (bool);


}