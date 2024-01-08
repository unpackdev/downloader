// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./SharedDataTypes.sol";

interface IUZV1Factory {
    /* view functions */
    function getActivePools() external view returns (address[] memory);

    function isValidPool(address pool) external view returns (bool);

    /* control functions */
    function createNewPool(
        uint256 totalRewards,
        uint256 startBlock,
        uint256 endBlock,
        address token,
        uint8 poolType,
        string memory name,
        string memory blockchain,
        string memory cAddress
    ) external returns (address);

    function removePool(address _pool) external;

    function setNative(address _pool, bool _isNative) external;

    function setStakingWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external;

    function setPaymentAddress(address _pool, address _receiver) external;

    function setPaymentWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external;

    function setDistributionWindow(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock
    ) external;

    function withdrawTokens(
        address _pool,
        address _tokenAddress,
        uint256 _amount
    ) external;

    function setPaymentToken(
        address _pool,
        address _token,
        uint256 _pricePerReward
    ) external;
}
