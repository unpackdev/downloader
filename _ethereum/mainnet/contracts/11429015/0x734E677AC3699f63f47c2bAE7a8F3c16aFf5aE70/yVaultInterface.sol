pragma solidity >=0.6.0 <0.7.0;

import "./IERC20Upgradeable.sol";

interface yVaultInterface is IERC20Upgradeable {
    function token() external view returns (IERC20Upgradeable);

    function balance() external view returns (uint256);
    
    function deposit(uint256 _amount) external;
    
    function withdraw(uint256 _shares) external;
    
    function getPricePerFullShare() external view returns (uint256);
}