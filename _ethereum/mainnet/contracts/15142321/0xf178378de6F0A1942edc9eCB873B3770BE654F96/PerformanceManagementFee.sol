// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./VaultStorage.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract PerformanceManagementFee is VaultStorage {
    using SafeERC20 for IERC20;
    event LOG(string message);
    using SafeMath for uint256;

    function executeSafeCleanUp(
        uint256 blockDifference,
        uint256 vaultCurrentNAV
    ) public payable {
        calculateFee(blockDifference, vaultCurrentNAV);
    }

    function calculateFee(uint256 blockDifference, uint256 vaultCurrentNAV)
        internal
    {
        uint256 bCurrentNAV = getVaultNAV();
        uint256 bLastNAV = tokenBalances.getLastTransactionNav();
        uint256 performanceFee = strategyPercentage;

        if (bCurrentNAV > bLastNAV) {
            uint256 navDiff = bCurrentNAV - bLastNAV;
            uint256 fees = platformFeeInterest + managementFeeInterest;
            performanceFeeInterest =
                performanceFeeInterest +
                (navDiff - fees).mul(performanceFee).div(1e20);
        } else {
            performanceFeeInterest = 0;
        }
        if (performanceFeeInterest < 0) performanceFeeInterest = 0;
    }
}
