  
// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.6;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface IMintableERC20 is IERC20 {

    function mintAmount(address[] calldata accounts, uint256 amount) external;

    function mintAmounts(address[] calldata accounts, uint256[] calldata amounts) external;
    
    function addMaintainer(address maintainer) external;
    
    function removeMaintainer(address maintainer) external;
    
    function maintainers() external view returns (address[] memory);

    function maxMintedAmount() external view returns (uint256);
}