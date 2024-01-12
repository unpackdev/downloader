// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./VaultStorage.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./PlatformManagementFeeStorage.sol";

contract PlatformManagementFee is VaultStorage {
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
        PlatformManagementFeeStorage mStorage = PlatformManagementFeeStorage(
            IAPContract(APContract).getPlatformFeeStorage()
        );
        uint256 platformFee = mStorage.getPlatformFee();
        platformFeeInterest = platformFeeInterest + vaultCurrentNAV
            .mul(blockDifference.mul(1e18))
            .mul(platformFee)
            .div(uint256(210240000).mul(1e36));
    }
}
