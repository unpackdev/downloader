/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>
    Copyright 2023 Lucky8 Lottery

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./Setters.sol";
import "./Constants.sol";
import "./Require.sol";
import "./Decimal.sol";
import "./VRFCoordinatorV2Interface.sol";

contract Lottery is Setters {
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Lottery";

    event TicketsMinted(address indexed account, uint256 round, uint256 amount);
    event PrizeClaimed(address indexed account, uint256 round, uint256 amount);
    event LotteryDrawStarted(uint256 round, uint timestamp, uint256 totalTickets, uint prizePool, uint winnningTickets);
    event LotteryDrawFinished(uint256 round, uint timestamp);

    /// @dev Payout this epochs rewards and trigger the lottery draw with chainlink VRF
    function initiateDrawAndRewards() internal {
        // pay out accrued 888 rewards to stakers
        uint bondedRewards = thisEpochsTokenRewards();

        // rewards to bonders
        incrementTotalBonded(bondedRewards);

        // trigger Lottery draw
        uint prizePool = thisEpochsPrizePool();
        incrementUserUSDCClaims(prizePool);

        // save draw state
        setPrizePerTicket(epoch(), prizePool / getWinningTickets());
        initWinningTicketsArray(epoch(), getWinningTickets());

        // Use the Chainlink VRF to get a random number.
        // This will initiate the request but we will need to wait for the request to be fulfilled.
        // See the method `fulfillRandomWords` for the callback.
        uint256 requestId = VRFCoordinatorV2Interface(VRFCoordinator()).requestRandomWords(
            VRFKeyhash(), // keyHash
            ChainlinkSubId(),
            200, // minimumRequestConfirmations
            1_000_000, // callbackGasLimit
            uint32(getWinningTickets()) // numWords
        );

        // Store chainlink request id
        setChainlinkRequestId(epoch(), requestId);

        emit LotteryDrawStarted(epoch(), blockTimestamp(), tickets().totalSupply(epoch()), prizePool, getWinningTickets());
    }

    /// @dev Internalise the chainlink VRFConsumerBaseV2 method with required checks to keep state layout clean
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        require(msg.sender == VRFCoordinator(), "only VRF Coordinator can fulfill");

        uint epoch = epochForRequestId(requestId);
        require(chainLinkRequestId(epoch) == requestId, "invalid epoch");
        require(drawExecuted(epoch) == false, "draw already executed");

        require(randomWords.length == winningTickets(epoch).length);

        // Iterate over the random words and get the winning numbers.
        uint ticketSupply = tickets().totalSupply(epoch);
        for (uint256 i = 0; i < randomWords.length; i++) {
            setWinningTicket(epoch, i, randomWords[i] % ticketSupply);
        }

        setDrawExecuted(epoch, true);

        emit LotteryDrawFinished(epoch, blockTimestamp());
    }


    /// @dev Method used to mint raffle tickets.
    function mintTickets() external returns (uint256) {
        require(tickets().balanceOf(msg.sender, epoch()) == 0, "Lottery: already minted tickets for this epoch");

        // mint tickets
        uint mintableTickets = balanceOfBonded(msg.sender) / 1 ether;
        require(tickets().balanceOf(msg.sender, epoch()) == 0, "Lottery: Not enough bonded balance");

        uint256 totalSupplyBeforeMinting = tickets().totalSupply(epoch());
        tickets().mint(msg.sender, epoch(), mintableTickets);
        uint256 totalSupplyAfterMinting = tickets().totalSupply(epoch());

        // Update the user tickets ranges.
        setUserTicketRange(msg.sender, epoch(), totalSupplyBeforeMinting, totalSupplyAfterMinting - 1);

        // Emit `TicketsMinted` event.
        emit TicketsMinted(msg.sender, epoch(), mintableTickets);

        return mintableTickets;
    }

    /// @dev Method used to claim the prize.
    function claimPrize(uint epoch) external returns (uint256) {
        require(userPrizeClaimed(epoch, msg.sender) == false, "Lottery: Prize already claimed");
        require(drawExecuted(epoch), "Lottery: Draw not yet resolved by chainlink vrf");

        (uint userTicketStart, uint userTicketEnd) = userTicketRange(msg.sender, epoch);

        // Check if the user has won.
        uint256[] memory winningNumbers = winningTickets(epoch);

        // Initialize the amount of winning tickets.
        uint256 winningTickets;
        for (uint256 i = 0; i < winningNumbers.length; i++) {
            // Check if the winning number is in the user ticket range.
            if (winningNumbers[i] >= userTicketStart && winningNumbers[i] <= userTicketEnd) {
                // Add the amount of winning tickets and the prize.
                winningTickets += 1;
            }
        }

        // Check if the user has won.
        require(winningTickets > 0, "Lottery: no winning tickets");

        // set prize as claimed
        setUserPrizeClaimed(epoch, msg.sender, true);

        uint prize = winningTickets * prizePerTicket(epoch);

        // Transfer the prize to the user.
        decrementUserUSDCClaims(prize);
        usdc().transfer(msg.sender, prize);

        // Emit `PrizeClaimed` event.
        emit PrizeClaimed(msg.sender, epoch, prize);

        return prize;
    }
}