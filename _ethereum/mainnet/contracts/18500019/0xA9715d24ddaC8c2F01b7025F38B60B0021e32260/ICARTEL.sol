pragma solidity ^0.8.17;

import "./IERC20.sol";

interface ICARTEL is IERC20 {
    function mintFromCasino(address to, uint256 amount) external;
    function mintFromPresale(address to, uint256 amount) external;
}