// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./CometInterface.sol";
import "./IWrappedERC20.sol";
import "./IRewardable.sol";

interface ICusdcV3Wrapper is IWrappedERC20, IRewardable {
    struct UserBasic {
        uint104 principal;
        uint64 baseTrackingAccrued;
        uint64 baseTrackingIndex;
        uint256 rewardsClaimed;
    }

    function deposit(uint256 amount) external;

    function depositTo(address account, uint256 amount) external;

    function depositFrom(
        address from,
        address dst,
        uint256 amount
    ) external;

    function withdraw(uint256 amount) external;

    function withdrawTo(address to, uint256 amount) external;

    function withdrawFrom(
        address src,
        address to,
        uint256 amount
    ) external;

    function claimTo(address src, address to) external;

    function accrue() external;

    function accrueAccount(address account) external;

    function underlyingBalanceOf(address account) external view returns (uint256);

    function getRewardOwed(address account) external view returns (uint256);

    function exchangeRate() external view returns (uint256);

    function convertStaticToDynamic(uint104 amount) external view returns (uint256);

    function convertDynamicToStatic(uint256 amount) external view returns (uint104);

    function baseTrackingAccrued(address account) external view returns (uint256);

    function baseTrackingIndex(address account) external view returns (uint64);

    function underlyingComet() external view returns (CometInterface);

    function rewardERC20() external view returns (IERC20);
}
