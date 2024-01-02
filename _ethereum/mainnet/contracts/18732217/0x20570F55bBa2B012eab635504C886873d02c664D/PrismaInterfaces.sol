// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

interface ITradeFactory {
    function enable(address, address) external;

    function disable(address, address) external;
}

interface IOracle {
    function latestRoundData(
        address,
        address
    )
        external
        view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IDetails {
    // get details from curve
    function symbol() external view returns (string memory);
}

interface ILocker {
    // Get POL address.
    function governance() external view returns (address);
}

interface ICurveOracle {
    function price_oracle() external view returns (uint256);
}

interface ISimpleOracle {
    function latestAnswer() external view returns (uint256);
}

interface IPrismaVault {
    function getClaimableWithBoost(
        address
    ) external view returns (uint256 maxBoosted, uint256 boosted);

    function batchClaimRewards(
        address receiver,
        address boostDelegate,
        address[] calldata rewardContracts,
        uint256 maxFeePct
    ) external returns (bool);
}

interface IPrismaReceiver {
    function lpToken() external view returns (address);

    function CRV() external view returns (address);

    function CVX() external view returns (address);

    function balanceOf(address a) external view returns (uint256);

    function deposit(address receiver, uint256 amount) external returns (bool);

    function withdraw(address receiver, uint256 amount) external returns (bool);

    function claimableReward(
        address account
    )
        external
        view
        returns (uint256 prismaAmount, uint256 crvAmount, uint256 cvxAmount);
}
