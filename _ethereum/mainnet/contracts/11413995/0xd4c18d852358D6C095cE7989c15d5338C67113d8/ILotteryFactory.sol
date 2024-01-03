//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ILotteryFactory {
    event NewLottery(address lotteryAddress);

    function registeredStakers(uint256 i) external view returns (address stakerAddress);

    function startLotteryPresale(
        string calldata _lotteryTokenName,
        string calldata _lotteryTokenSymbol,
        uint256 _lotteryTokenPrice,
        uint256 _lotteryTokenMaxSupply,
        uint256 _ETHMaxSupply,
        uint256 _uniswapTokenSupplyPercentNumerator,
        uint256 _stakerETHRewardsPercentNumerator
    ) external;

    function currentLotteryRound() external view returns (uint256 currRound);

    function registerStaker() external;

    function isStakerRegistered(address staker)
        external
        view
        returns (bool registered);

    function getRegisteredStakersLength()
        external
        view
        returns (uint256 length);
}
