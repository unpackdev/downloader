pragma solidity ^0.6.0;

import "./IERC20.sol";

interface IHasBlackListERC20Token is IERC20 {
    function isBlackListed(address user) external returns (bool);
    function addBlackList(address user) external;
    function removeBlackList(address user) external;
}