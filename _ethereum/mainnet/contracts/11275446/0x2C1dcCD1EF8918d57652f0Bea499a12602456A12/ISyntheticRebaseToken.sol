pragma solidity ^0.6.0;

import "./IERC20Nameable.sol";

interface ISyntheticRebaseToken is IERC20Nameable  {
    function transferOwnershipWithBalance(address newOwner) external;
}