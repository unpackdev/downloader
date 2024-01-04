// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IFeeApprover {
    function check(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function setPaused(bool _pause) external;

    function setFeeMultiplier(uint256 _feeMultiplier) external;

    function feePercentX100() external view returns (uint256);

    function setTokenUniswapPair(address _tokenUniswapPair) external;

    function setHal9kVaultAddress(address _hal9kVaultAddress) external;

    function sync() external;

    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (uint256 transferToAmount, uint256 transferToFeeBearerAmount);
}
