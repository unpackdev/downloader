pragma solidity 0.7.6;

import "./ERC20.sol";

interface yToken is ERC20 {
    function getPricePerFullShare() external view returns (uint256);
}
