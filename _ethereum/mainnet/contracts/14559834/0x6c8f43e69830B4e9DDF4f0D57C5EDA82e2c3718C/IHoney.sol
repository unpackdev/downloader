//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IValidator.sol";

interface IHoney is IERC20, IValidator {
    function mint(address for_, uint256 amount) external;
    function burn(address for_, uint256 amount) external;
}
