// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


interface IFeeApprover {

    function check(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function setFeeMultiplier(uint _feeMultiplier) external;
    function feePercentX100() external view returns (uint);

    function setTokenUniswapPair(address _tokenUniswapPair) external;

    function setRamTokenAddress(address _ramTokenAddress) external;
    function setYgyTokenAddress(address _ygyTokenAddress) external;
    function sync() external returns (bool lastIsMint, bool lpTokenBurn);
    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    ) external  returns (uint256 transferToAmount, uint256 transferToFeeBearerAmount);

    function setPaused() external;


}
