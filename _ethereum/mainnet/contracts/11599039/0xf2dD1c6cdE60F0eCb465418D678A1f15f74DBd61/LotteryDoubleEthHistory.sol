// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

import "./GovernanceInterface.sol";

contract LotteryDoubleEthHistory {
    GovernanceInterface public immutable TrustedGovernance;

    event RoundStarted(
        uint32 indexed round,
        uint endsAfter
    );

    event RoundEnded(
        uint32 indexed round,
        uint256 randomness,
        uint256 totalBooty,
        uint256 totalWinners
    );

    event NewBet(
        uint32 indexed round,
        uint8 side,
        address indexed player,
        uint256 amount,
        address indexed referrer
    );

    modifier onlyLotteries() {
        require(TrustedGovernance.lotteryContracts(msg.sender), "Only lottery");
        _;
    }

    /** 
     * @dev L7L DAO should be in charge of lottery smart-contract.
     *
     * @param _governance Orchestration contract.
     */
    constructor(address _governance) public {
        TrustedGovernance = GovernanceInterface(_governance);
    }

    /**
     * @dev Save history of bets.
     *
     * @param round Round of game.
     * @param side Side of bet: Blue - 0, Green - 1.
     * @param player Address of player.
     * @param amount Amount of ETH in bet.
     * @param referrer Address of referrer.
     */
    function newBet(uint32 round, uint8 side, address player, uint256 amount, address referrer) external onlyLotteries {
        emit NewBet(round, side, player, amount, referrer);
    }

    /**
     * @dev Save new round event.
     *
     * @param round Round of game.
     * @param endsAfter Unixtimestamp when round should end.
     */
    function roundStarted(uint32 round, uint endsAfter) external onlyLotteries {
        emit RoundStarted(round, endsAfter);
    }

    /**
     * @dev Save new round event.
     *
     * @param round Round of game.
     * @param randomness Randomness result.
     * @param totalBooty Total ETH betted in a round.
     * @param totalWinners Total ETH betted by the winning side.
     */
    function roundEnded(uint32 round, uint256 randomness, uint256 totalBooty, uint256 totalWinners) external onlyLotteries {
        emit RoundEnded(round, randomness, totalBooty, totalWinners);
    }
}