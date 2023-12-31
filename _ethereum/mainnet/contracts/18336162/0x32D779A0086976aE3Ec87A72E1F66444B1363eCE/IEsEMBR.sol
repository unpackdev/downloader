// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IVester.sol";
import "./IERC20.sol";

interface IEsEMBR {
    function updateRewardsEthForAll() external;
    function updateRewardsEmbrForAll() external;
    function addVester(uint timeframe, IVester vester) external;
    function reward(address recipient, uint amount) external;

    function claimable(address _address) external view returns (uint256);
    function claim() external returns (uint256);

    function claimableRevShare(address _address) external view returns (uint256);
    function claimRevShare() external returns (uint256);
    function claimableEMBR(address addy, uint256[] calldata timeframes) external view returns (uint256);

    function batchCollectVested(uint[] calldata timeframes) external returns (uint);
    function collectVested(uint timeframe) external returns (uint);

    function rewardsLeft() external returns (uint);
}
