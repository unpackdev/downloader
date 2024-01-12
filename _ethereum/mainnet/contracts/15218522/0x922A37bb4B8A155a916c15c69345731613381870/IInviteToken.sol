pragma solidity ^0.8.7;

import "./IERC20.sol";

interface IInviteToken is IERC20 {
    function batchMint(address[] calldata accounts, uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}
