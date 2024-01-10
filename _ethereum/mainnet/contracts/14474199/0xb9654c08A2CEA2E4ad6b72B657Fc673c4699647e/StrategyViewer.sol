// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC20.sol";
import "./ERC20.sol";
import "./IERC721Enumerable.sol";
import "./ERC721.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";

import "./LowGasSafeMath.sol";
import "./PreciseUnitMath.sol";
import "./SafeDecimalMath.sol";
import "./Math.sol";

import "./IRewardsDistributor.sol";
import "./IBabController.sol";
import "./IGardenValuer.sol";
import "./IGarden.sol";
import "./IStrategy.sol";
import "./IMardukGate.sol";
import "./IGardenNFT.sol";
import "./IStrategyNFT.sol";
import "./IPriceOracle.sol";
import "./IViewer.sol";

/**
 * @title GardenViewer
 * @author Babylon Finance
 *
 * Class that holds common view functions to retrieve garden information effectively
 */
contract StrategyViewer is IStrategyViewer {
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;
    using Math for int256;
    using SafeDecimalMath for uint256;

    IBabController private immutable controller;

    constructor(IBabController _controller) {
        controller = _controller;
    }

    /* ============ External Getter Functions ============ */

    /**
     * Gets complete strategy details
     *
     * @param _strategy            Address of the strategy to fetch
     * @return                     All strategy details
     */
    function getCompleteStrategy(address _strategy)
        external
        view
        override
        returns (
            address,
            string memory,
            uint256[16] memory,
            bool[] memory,
            uint256[] memory
        )
    {
        IStrategy strategy = IStrategy(_strategy);
        bool[] memory status = new bool[](3);
        uint256[] memory ts = new uint256[](4);
        // ts[0]: executedAt, ts[1]: exitedAt, ts[2]: updatedAt
        (, status[0], status[1], status[2], ts[0], ts[1], ts[2]) = strategy.getStrategyState();
        uint256 rewards =
            ts[1] != 0 ? IRewardsDistributor(controller.rewardsDistributor()).getStrategyRewards(_strategy) : 0;
        ts[3] = strategy.enteredCooldownAt();
        return (
            strategy.strategist(),
            IStrategyNFT(controller.strategyNFT()).getStrategyName(_strategy),
            [
                strategy.getOperationsCount(),
                strategy.stake(),
                strategy.totalPositiveVotes(),
                strategy.totalNegativeVotes(),
                strategy.capitalAllocated(),
                strategy.capitalReturned(),
                strategy.duration(),
                strategy.expectedReturn(),
                strategy.maxCapitalRequested(),
                strategy.enteredAt(),
                strategy.getNAV(),
                rewards,
                strategy.maxAllocationPercentage(),
                strategy.maxGasFeePercentage(),
                strategy.maxTradeSlippagePercentage(),
                strategy.isStrategyActive()
                    ? IRewardsDistributor(controller.rewardsDistributor()).estimateStrategyRewards(_strategy)
                    : 0
            ],
            status,
            ts
        );
    }

    function getOperationsStrategy(address _strategy)
        external
        view
        override
        returns (
            uint8[] memory,
            address[] memory,
            bytes[] memory
        )
    {
        IStrategy strategy = IStrategy(_strategy);
        uint256 count = strategy.getOperationsCount();
        uint8[] memory types = new uint8[](count);
        address[] memory integrations = new address[](count);
        bytes[] memory datas = new bytes[](count);

        for (uint8 i = 0; i < count; i++) {
            (types[i], integrations[i], datas[i]) = strategy.getOperationByIndex(i);
        }
        return (types, integrations, datas);
    }

    function getUserStrategyActions(address[] memory _strategies, address _user)
        external
        view
        override
        returns (uint256, uint256)
    {
        uint256 strategiesCreated;
        uint256 totalVotes;
        for (uint8 i = 0; i < _strategies.length; i++) {
            IStrategy strategy = IStrategy(_strategies[i]);
            if (strategy.strategist() == _user) {
                strategiesCreated = strategiesCreated.add(1);
            }
            int256 votes = strategy.getUserVotes(_user);
            if (votes != 0) {
                totalVotes = totalVotes.add(uint256(Math.abs(votes)));
            }
        }
        return (strategiesCreated, totalVotes);
    }

    /* ============ Private Functions ============ */
}
