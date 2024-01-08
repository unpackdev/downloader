pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";

interface IGToken is IERC20 {
    function _wrap(uint256 amount, address user) external;

    function _unwrap(uint256 amount, address user) external;

    function asset() external view returns (IERC20Metadata);
}
