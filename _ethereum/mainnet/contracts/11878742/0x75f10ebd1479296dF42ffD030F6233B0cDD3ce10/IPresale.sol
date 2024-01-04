// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IPresale {
    event PresaleStarted();

    event FcfsActivated();

    event PresaleEnded();

    event ContributionAccepted(
        address indexed _contributor,
        uint256 _partialContribution,
        uint256 _totalContribution,
        uint256 _receivedTokens,
        uint256 _contributions
    );

    event ContributionRefunded(address indexed _contributor, uint256 _contribution);

    function tokenAddress() external view returns (address);

    function uniswapPairAddress() external view returns (address);

    function buybackAddress() external view returns (address);

    function liquidityLockAddress() external view returns (address);

    function uniswapRouterAddress() external view returns (address);

    function rcFarmAddress() external view returns (address);

    function rcEthFarmAddress() external view returns (address);

    function collectedAmount() external view returns (uint256);

    function hardcapAmount() external view returns (uint256);

    function maxContributionAmount() external view returns (uint256);

    function isPresaleActive() external view returns (bool);

    function isFcfsActive() external view returns (bool);

    function wasPresaleEnded() external view returns (bool);

    function isWhitelisted(address _contributor) external view returns (bool);

    function contribution(address _contributor) external view returns (uint256);

    function addContributors(address[] calldata _contributors) external;

    function start(
        uint256 _hardcap,
        uint256 _maxContribution,
        address _token,
        address _uniswapPair,
        address _buyback,
        address _liquidityLock,
        address _uniswapRouter,
        address _rcFarm,
        address _rcEthFarm,
        address[] calldata _contributors
    ) external;

    function activateFcfs() external;

    function end(address payable _team) external;
}
