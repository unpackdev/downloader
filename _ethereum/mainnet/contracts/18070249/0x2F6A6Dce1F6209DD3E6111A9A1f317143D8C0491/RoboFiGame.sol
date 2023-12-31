// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Errors.sol";
import "./RoboFiAddress.sol";
import "./IDABot.sol";
import "./IRoboFiGame.sol";
import "./IBotBenefitciary.sol";
import "./IVicsExchange.sol";


contract RoboFiGame is Ownable, Initializable, IRoboFiGameEvent, IBotBenefitciary {

    using RoboFiAddress for address;

    IDABotManager public botManager;
    IBotVaultManager public vaultManager;
    IConfigurator public configurator;

    mapping(address => uint) private prizePools;
    mapping(address => mapping(address => Ticket[])) private tickets;
    mapping(address => GameRound[]) private gameRounds;
    mapping(address => GameSetting) private gameSettings;

    modifier onlyBot {
        require(botManager.isRegisteredBot(_msgSender()), Errors.RFG_CALLER_IS_NOT_REGISTERED_BOT);
        _;
    }

    modifier onlyBotOwner(address bot) {
        require(IDABot(bot).owner() == _msgSender(), Errors.RFG_CALLER_IS_NOT_BOT_OWNER);
        _;
    }

    modifier onlyVault {
        require(address(vaultManager) == _msgSender(), Errors.RFG_CALLER_IS_NOT_VAULT);
        _;
    }

    modifier roundNotFinished(address bot) {
        GameRound[] storage rounds = gameRounds[bot];
        require(rounds.length > 0 && rounds[rounds.length - 1].data.state != uint8(RoundState.Finished),
                Errors.RFG_ROUND_NOT_FINISHED);
        _;
    }

    modifier checkCommitPhase(address bot) {
        GameRound[] storage rounds = gameRounds[bot];
        GameRound storage currentRound = rounds[rounds.length - 1];
        require(block.timestamp <= currentRound.data.startTime + (currentRound.data.commitPhaseDuration * 1 seconds),
                Errors.RFG_ROUND_NOT_IN_COMMIT_PHASE);
        _;
    }

    modifier checkRevealPhase(address bot) {
        GameRound[] storage rounds = gameRounds[bot];
        GameRound storage currentRound = rounds[rounds.length - 1];
        uint commitPhase = currentRound.data.startTime + (currentRound.data.commitPhaseDuration * 1 seconds);
        uint revealPhase = commitPhase + (currentRound.data.revealPhaseDuration * 1 seconds);

        require(commitPhase < block.timestamp && block.timestamp <= revealPhase,
            Errors.RFG_ROUND_NOT_IN_REVEAL_PHASE);
        _;
    }

    modifier checkClosePhase(address bot) {
        GameRound[] storage rounds = gameRounds[bot];
        GameRound storage currentRound = rounds[rounds.length - 1];
        uint commitPhase = currentRound.data.startTime + (currentRound.data.commitPhaseDuration * 1 seconds);
        uint revealPhase = commitPhase + (currentRound.data.revealPhaseDuration * 1 seconds);

        require(block.timestamp > revealPhase, Errors.RFG_ROUND_NOT_READY_CLOSE);
        _;
    }

    function initialize(IDABotManager manager, IBotVaultManager botVault, IConfigurator config) external payable initializer {
        botManager = manager;
        vaultManager = botVault;
        configurator = config;
        _transferOwnership(_msgSender());
    }

    function setBotManager(IDABotManager manager) external onlyOwner {
        botManager = manager;
    }

    function setVaultManager(IBotVaultManager botVault) external onlyOwner {
        vaultManager = botVault;
    }

    function setConfigurator(IConfigurator config) external onlyOwner {
        configurator = config;
    }

    function name() external pure override returns(string memory) {
        return "RoboFi Game";
    }

    function shortName() external pure override returns(string memory) {
        return "RoboFi Game";
    }

    function onAward(uint amount) external override onlyBot {
        prizePools[_msgSender()] += amount;
    }

    function generateTicket(address bot, address account, address botToken, uint112 amount) external onlyVault {
        if (!botToken.isGovernToken()) {
            return;
        }

        uint112 ticketQuantity = uint112(amount / 10 ** IRoboFiERC20(botToken).decimals());
        if (ticketQuantity < 1) {
            return;
        }

        GameSetting storage settings = gameSettings[bot];
        uint112 lower = settings.lastTicketNumber > 0 ? settings.lastTicketNumber + 1 : 0;
        Ticket memory newTicket = Ticket({
            ticketId: settings.lastTicketId++,
            lower: lower,
            upper: lower + ticketQuantity - 1
        });

        tickets[bot][account].push(newTicket);
        settings.lastTicketNumber = newTicket.upper;

        emit GenerateTicket(bot, account, newTicket.ticketId, newTicket.lower, newTicket.upper);
    }

    function deleteTicket(address bot, address account, address botToken, uint112 amount) external onlyVault {
        if (!botToken.isGovernToken()) {
            return;
        }

        Ticket[] storage userTickets = tickets[bot][account];
        if (userTickets.length == 0) {
            return;
        }

        uint112 ticketQuantity = uint112(amount / 10 ** IRoboFiERC20(botToken).decimals());
        if (ticketQuantity < 1) {
            ticketQuantity = 1;
        }
        
        while (ticketQuantity > 0) {
            Ticket storage userTicket = userTickets[0];
            uint112 totalRange = userTicket.upper - userTicket.lower + 1;
            if (ticketQuantity < totalRange) {
                userTicket.lower += ticketQuantity;
                emit UpdateTicket(bot, account, userTicket.ticketId, userTicket.lower);
                break;
            }

            emit DeleteTicket(bot, account, userTicket.ticketId);
            delete userTickets[0];
            userTickets[0] = userTickets[userTickets.length - 1];
            userTickets.pop();

            ticketQuantity -= totalRange;
        }
    }

    function startRound(address bot, uint secretHash) external onlyBotOwner(bot) {
        GameRound[] storage rounds = gameRounds[bot];
        if (rounds.length > 0) {
            require(rounds[rounds.length - 1].data.state == uint8(RoundState.Finished),
                    Errors.RFG_ROUND_NOT_FINISHED);
        }

        GameSetting memory settings = gameSettings[bot];
        RoundData memory data = RoundData({
            startTime: uint64(block.timestamp),
            commitPhaseDuration: _getCommitDurationOrDefault(bot),
            revealPhaseDuration: _getRevealDurationOrDefault(bot),
            state: uint8(RoundState.NotFinished),
            noWinnerAllowed: settings.noWinnerAllowed,
            numberWinners: _getNumberWinnersOrDefault(bot),
            prize: prizePools[bot],
            secretHash: secretHash,
            randSeed: 0
        });

        GameRound storage newRound = rounds.push();
        newRound.data = data;

        emit StartRound(bot, rounds.length - 1, newRound.data.startTime, newRound.data.commitPhaseDuration,
                        newRound.data.revealPhaseDuration, newRound.data.prize);
    }

    function submit(address bot, uint secretHash) external roundNotFinished(bot) checkCommitPhase(bot) {
        GameRound[] storage rounds = gameRounds[bot];
        rounds[rounds.length - 1].committedHashes[_msgSender()] = secretHash;

        emit Submit(bot, _msgSender(), rounds.length - 1, secretHash);
    }

    function reveal(address bot, uint secretNumber) external roundNotFinished(bot) checkRevealPhase(bot) {
        GameRound[] storage rounds = gameRounds[bot];
        GameRound storage currentRound = rounds[rounds.length - 1];
        require(_checkSecretNumber(secretNumber, currentRound.committedHashes[_msgSender()]),
                Errors.RFG_INVALID_SECRET_NUMBER);

        _updateRandSeed(currentRound, secretNumber);

        emit Reveal(bot, _msgSender(), rounds.length - 1);
    }

    function submitAndReveal(address bot, uint secretNumber) external roundNotFinished(bot) checkCommitPhase(bot) {
        GameRound[] storage rounds = gameRounds[bot];
        uint currentRoundId = rounds.length - 1;
        GameRound storage currentRound = rounds[currentRoundId];

        uint secretHash = uint(_hashNumber(secretNumber));
        currentRound.committedHashes[_msgSender()] = secretHash;
        _updateRandSeed(currentRound, secretNumber);

        emit Submit(bot, _msgSender(), currentRoundId, secretHash);
        emit Reveal(bot, _msgSender(), currentRoundId);
    }

    function closeRound(address bot, uint secretNumber) external onlyBotOwner(bot) roundNotFinished(bot) checkClosePhase(bot) {
        GameRound[] storage rounds = gameRounds[bot];
        GameRound storage currentRound = rounds[rounds.length - 1];
        require(_checkSecretNumber(secretNumber, currentRound.data.secretHash),
                Errors.RFG_INVALID_SECRET_NUMBER);

        _updateRandSeed(currentRound, uint(keccak256(abi.encodePacked(block.timestamp, secretNumber))));
        currentRound.data.state = uint8(RoundState.RoundClosed);

        emit CloseRound(bot, rounds.length - 1, currentRound.data.randSeed);
    }

    function submitWinners(address bot, address[] memory winners, uint32[] memory wonNumberOffsets,
                           uint32[] memory wonTicketLocalIndexes) external onlyBotOwner(bot) {

        require(winners.length == wonNumberOffsets.length &&
            winners.length == wonTicketLocalIndexes.length,
            Errors.RFG_INVALID_SUBMIT_WINNERS);

        GameRound[] storage rounds = gameRounds[bot];
        uint currentRoundId = rounds.length - 1;
        require(rounds[currentRoundId].data.state == uint8(RoundState.RoundClosed), Errors.RFG_ROUND_NOT_CLOSED_YET);
        require(rounds[currentRoundId].data.numberWinners == winners.length,
                Errors.RFG_INVALID_NUMBER_OF_WINNERS);

        if (!rounds[currentRoundId].data.noWinnerAllowed) {
            for (uint i = 0; i < winners.length; i++) {
                require(winners[i] != address(0), Errors.RFG_WINNER_IS_REQUIRE);
            }
        }

        uint currentSeed = gameRounds[bot][currentRoundId].data.randSeed;
        uint112 lastTicketNumber = gameSettings[bot].lastTicketNumber;
        uint112[] memory wonNumbers = new uint112[](wonNumberOffsets.length);
        uint32[] memory ticketIds = new uint32[](wonNumberOffsets.length);

        for (uint i = 0; i < wonNumberOffsets.length; i++) {
            uint112 wonNumber = uint112(uint(_hashNumber((currentSeed + wonNumberOffsets[i]))) % lastTicketNumber);
            if (winners[i] != address(0) && wonTicketLocalIndexes[i] > 0) {
                Ticket memory wonTicket = tickets[bot][winners[i]][wonTicketLocalIndexes[i] - 1];
                require(wonNumber >= wonTicket.lower && wonNumber <= wonTicket.upper,
                        Errors.RFG_INVALID_WON_NUMBER);
                ticketIds[i] = wonTicket.ticketId;
            } else {
                ticketIds[i] = 0;
            }
            wonNumbers[i] = wonNumber;
        }

        _distributePrize(bot, winners, gameRounds[bot][currentRoundId].data.prize);
        gameRounds[bot][currentRoundId].data.state = uint8(RoundState.Finished);

        emit RoundWinner(
            bot,
            currentRoundId,
            winners,
            wonNumbers,
            wonNumberOffsets,
            wonTicketLocalIndexes,
            ticketIds,
            lastTicketNumber
        );
    }

    function updateGameSettings(address bot, bool noWinnerAllowed, uint8 numberWinners,
                                uint64 commitPhaseDuration, uint64 revealPhaseDuration) external onlyBotOwner(bot) {
        require(numberWinners > 0, Errors.RFG_INVALID_NUMBER_OF_WINNERS);
        require(commitPhaseDuration > 0, Errors.RFG_INVALID_COMMIT_DURATION);
        require(revealPhaseDuration > 0, Errors.RFG_INVALID_REVEAL_DURATION);

        GameSetting storage settings = gameSettings[bot];
        if (settings.noWinnerAllowed != noWinnerAllowed) {
            settings.noWinnerAllowed = noWinnerAllowed;
        }
        
        if (settings.numberWinners != numberWinners) {
            settings.numberWinners = numberWinners;
        }

        if (settings.commitPhaseDuration != commitPhaseDuration) {
            settings.commitPhaseDuration = commitPhaseDuration;
        }
        
        if (settings.revealPhaseDuration != revealPhaseDuration) {
            settings.revealPhaseDuration = revealPhaseDuration;
        }
    }

    receive() external payable { }

    function getGamePrize(address bot, uint roundId) external view returns(uint) {
        return gameRounds[bot][roundId].data.prize;
    }

    function randSeed(address bot, uint roundId) external view returns (uint) {
        return gameRounds[bot][roundId].data.randSeed;
    }

    function getUserTickets(address bot, address account) external view returns(Ticket[] memory) {
        return tickets[bot][account];
    }

    function getRoundDetails(address bot, uint roundId) external view returns (RoundData memory) {
        GameRound storage gRound = gameRounds[bot][roundId];
        return gRound.data;
    }

    function getBotGameSettings(address bot) external view returns (GameSetting memory settings) {
        settings.noWinnerAllowed = gameSettings[bot].noWinnerAllowed;
        settings.numberWinners = _getNumberWinnersOrDefault(bot);
        settings.commitPhaseDuration = _getCommitDurationOrDefault(bot);
        settings.revealPhaseDuration = _getRevealDurationOrDefault(bot);
    }

    function getLastTicketNumber(address bot) external view returns(uint) {
        return gameSettings[bot].lastTicketNumber;
    }

    function getCurrentRoundId(address bot) external view returns(int) {
        GameRound[] storage rounds = gameRounds[bot];
        if (rounds.length == 0) {
            return -1;
        }

        return int(rounds.length - 1);
    }

    function getBotPrize(address bot) external view returns(uint) {
        return prizePools[bot];
    }

    function _updateRandSeed(GameRound storage round, uint secretNumber) private {
        round.data.randSeed ^= uint(keccak256(abi.encodePacked(secretNumber + 1)));
    }

    function _hashNumber(uint secretNumber) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(Strings.toString(secretNumber)));
    }

    function _checkSecretNumber(uint secretNumber, uint secretHash) private pure returns(bool) {
        return uint(_hashNumber(secretNumber)) == secretHash;
    }

    function _distributePrize(address bot, address[] memory winners, uint prize) private {
        if (winners.length > 0) {
            uint prizePerWinner = prize / winners.length;
            IERC20 vics = IERC20(configurator.addressOf(AddressBook.ADDR_VICS));
            require (address(vics) != address(0), Errors.RFG_INVALID_VICS_ADDRESS);

            for (uint i = 0; i < winners.length; i++) {
                if (winners[i] != address(0)) {
                    prizePools[bot] -= prizePerWinner;
                    vics.transfer(winners[i], prizePerWinner);
                }
            }
        }
    }

    function _getNumberWinnersOrDefault(address bot) private view returns (uint8 numWinner) {
        numWinner = gameSettings[bot].numberWinners;
        if (numWinner == 0) {
            numWinner = uint8(configurator.configOf(Config.GAME_NUMBER_WINNER));
        }
    }

    function _getCommitDurationOrDefault(address bot) private view returns (uint64 commitDuration) {
        commitDuration = gameSettings[bot].commitPhaseDuration;
        if (commitDuration == 0) {
            commitDuration = uint64(configurator.configOf(Config.GAME_COMMIT_DURATION));
        }
    }

    function _getRevealDurationOrDefault(address bot) private view returns (uint64 revealDuration) {
        revealDuration = gameSettings[bot].revealPhaseDuration;
        if (revealDuration == 0) {
            revealDuration = uint64(configurator.configOf(Config.GAME_REVEAL_DURATION));
        }
    }
}
