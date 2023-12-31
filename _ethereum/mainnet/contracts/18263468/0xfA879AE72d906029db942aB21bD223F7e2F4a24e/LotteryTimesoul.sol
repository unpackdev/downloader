// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";

contract LotteryTimesoul is Ownable {
    uint randNonce;
    uint public lotteryID;

    address[] wallets;
    mapping(address => uint) tickets;
    mapping(address => bool) winnersMap;

    address[] winners;
    string[] public prizes;

    error LotteryCompleted();
    error LotteryNotCompleted();
    error NoTickets(address);
    error NoWallets();
    error DuplicateWallet(address);
    error PrizesRequired();
    error NotEnoughWalletsForDraw(uint required, uint provided);

    event NewWinner(address wallet, string prize);

    struct Participant {
        address wallet;
        uint tickets;
    }

    struct Winner {
        address wallet;
        string prize;
    }

    constructor(uint _lotteryID, uint _randNonce, string[] memory _prizes) {
        if (_prizes.length == 0) {
            revert PrizesRequired();
        }

        randNonce = _randNonce;
        lotteryID = _lotteryID;
        prizes = _prizes;
    }

    function addParticipants(Participant[] calldata parts) external onlyOwner {
        if (winners.length > 0) {
            revert LotteryCompleted();
        }

        for (uint i = 0; i < parts.length; i++) {
            Participant memory p = parts[i];
            if (p.tickets == 0) {
                revert NoTickets(p.wallet);
            }

            if (tickets[p.wallet] == 0) {
                wallets.push(p.wallet);
            }

            tickets[p.wallet] = p.tickets;
        }
    }

    function walletBet(address wallet) external view returns (uint) {
        require(
            tickets[wallet] > 0,
            "wallet does not participate in the lottery"
        );

        return tickets[wallet];
    }

    function getWinners() external view returns (Winner[] memory) {
        require(winners.length > 0, "lottery is not over yet");

        Winner[] memory winnersWallets = new Winner[](prizes.length);
        for (uint i = 0; i < prizes.length; i++) {
            winnersWallets[i] = Winner(winners[i], prizes[i]);
        }

        return (winnersWallets);
    }

    function draw() external onlyOwner {
        if (winners.length > 0) {
            revert LotteryCompleted();
        }

        if (wallets.length == 0) {
            revert NoWallets();
        }

        if (prizes.length > wallets.length) {
            revert NotEnoughWalletsForDraw(prizes.length, wallets.length);
        }

        winners = new address[](prizes.length);
        uint[] memory weightSum = new uint[](wallets.length);

        weightSum[0] = tickets[wallets[0]];
        for (uint j = 1; j < weightSum.length; j++) {
            weightSum[j] = weightSum[j - 1] + tickets[wallets[j]];
        }

        uint maxWeight = weightSum[weightSum.length - 1];
        uint prizeIdx = 0;
        while (prizeIdx < prizes.length) {
            uint winnerIdx = getRandomIdx(
                weightSum,
                weightSum.length,
                maxWeight
            );

            address winner = wallets[winnerIdx];
            if (winnersMap[winner]) {
                continue;
            }

            winners[prizeIdx] = winner;
            emit NewWinner(winner, prizes[prizeIdx]);

            winnersMap[winner] = true;
            prizeIdx++;
        }
    }

    function getRandomIdx(
        uint[] memory weightSum,
        uint len,
        uint maxWeight
    ) internal returns (uint) {
        uint weight = randMod(maxWeight + 1);
        uint left = 0;
        uint right = len - 1;

        while (left < right) {
            uint mid = (left + right) / 2;

            if (weightSum[mid] == weight) {
                return mid;
            } else if (weightSum[mid] < weight) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        return left;
    }

    function randMod(uint _modulus) internal returns (uint) {
        randNonce++;

        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % _modulus;
    }
}
