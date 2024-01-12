// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./VaultStorage.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract ManagementFee is VaultStorage {
    using SafeERC20 for IERC20;
    event LOG(string message);
    using SafeMath for uint256;

    function executeSafeCleanUp(
        uint256 blockDifference,
        uint256 vaultCurrentNAV
    ) public payable {
        calculateFee(blockDifference,vaultCurrentNAV);
    }

    function calculateFee(uint256 blockDifference,uint256 vaultCurrentNAV)
        internal
    {
        uint256 managementFee = managementPercentage;
        managementFeeInterest = managementFeeInterest + vaultCurrentNAV
            .mul(blockDifference.mul(1e18))
            .mul(managementFee)
            .div(uint256(210240000).mul(1e36));
    }
}
