// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./SafeERC20Upgradeable.sol";
import "./IChainLinkOracleSportData.sol";
import "./IRegularCompetitionContract.sol";
import "./ICompetitionPool.sol";
import "./CompetitionContract.sol";
import "./String.sol";

/*
RCC01: Address 0x00
RCC02: Time is illegal
RCC03: Competition is in the past
RCC04: No bet options
RCC05: Game is not supported
RCC06: Attribute is not supported
RCC07: _betOptions invalid
RCC08: expired
RCC09: Not enough Fee
RCC10: Invalid length
RCC11: Invalid bracket
RCC12: Not enough Fee
RCC13: Only Oracle
RCC14: It's not time yet
RCC15: Had Got Price
RCC16: Not enough entrant
RCC17: Bet time haven't finished yet
RCC18: Waiting for get result
RCC19: Not result
*/

contract RegularCompetitionContract is
    CompetitionContract,
    IRegularCompetitionContract
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using String for string;
    using String for uint256;
    Competition public competition;
    uint256 public gapValidatitionTime; //maximumRefundTime
    uint256 public scheduledStartTime;

    uint256 constant public decimalOfResult = 10000;

    address public override oracle;

    mapping(bytes32 => address[]) public ticketSell;
    BetOption[] public betOptions;

    bytes32 internal requestID;

    function setOracle(address _oracle) external override onlyConfigurator {
        require(_oracle != address(0), "RCC01");
        oracle = _oracle;
    }

    function setGapvalidationTime(uint256 _gapTime)
        external
        override
        onlyConfigurator
    {
        gapValidatitionTime = _gapTime;
    }

    function getDataToCheckRefund()
        external
        view
        override
        returns (bytes32, uint256)
    {
        return (requestID, endBetTime);
    }

    function getTicketSell(uint256[] memory _brackets)
        external
        view
        override
        returns (address[] memory)
    {
        bytes32 _key = _generateKey(_brackets);
        return ticketSell[_key];
    }

    function getBetOptions() external view returns (BetOption[] memory) {
        return (betOptions);
    }

    function setBasic(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _entryFee,
        uint256 _minEntrant,
        uint256 _scheduledStartTime,
        uint256 _minimumBetime
    ) external override onlyConfigurator onlyLock returns (bool) {
        require(block.timestamp <= _startTimestamp, "RCC02");
        require(_startTimestamp + _minimumBetime < _endTimestamp, "RCC02");
        require(_endTimestamp < _scheduledStartTime, "RCC03");
        startBetTime = _startTimestamp;
        endBetTime = _endTimestamp;
        entryFee = _entryFee;
        minEntrant = _minEntrant;
        scheduledStartTime = _scheduledStartTime;
        return true;
    }

    function setCompetition(
        string memory _competitionId,
        string memory _team1,
        string memory _team2,
        uint256 _sportTypeAlias,
        address _sportManager
    ) external override onlyConfigurator onlyLock {
        sportManager = ISportManager(_sportManager);
        competition = Competition(
            _competitionId,
            _team1,
            _team2,
            _sportTypeAlias,
            0,
            false
        );
    }

    function setBetOptions(BetOption[] memory _betOptions)
        external
        override
        onlyConfigurator
        onlyLock
    {
        require(_betOptions.length > 0, "RCC04");
        require(
            sportManager.checkSupportedGame(competition.sportTypeAlias),
            "RCC05"
        );
        for (uint256 i = 0; i < _betOptions.length; i++) {
            require(
                sportManager.checkSupportedAttribute(
                    competition.sportTypeAlias,
                    _betOptions[i].attribute
                ),
                "RCC06"
            );

            require(_checkBetOption(i, _betOptions), "RCC07");
            if (sportManager.checkTeamOption(_betOptions[i].attribute)) {
                uint256[] memory brackets = new uint256[](2);
                brackets[0] = 0;
                brackets[1] = 1;
                betOptions.push(
                    BetOption({
                        mode: Mode.Team,
                        attribute: _betOptions[i].attribute,
                        id: "0",
                        brackets: brackets
                    })
                );
            } else {
                betOptions.push(_betOptions[i]);
            }
        }
    }

    function start() external virtual override onlyOwner onlyLock {
        require(endBetTime >= block.timestamp, "RCC08");
        require(getTotalToken(tokenAddress) >= fee, "RCC09");
        totalFee = fee;
        status = Status.Open;
        emit Ready(block.timestamp, startBetTime, endBetTime);
    }

    function placeBet(address user, uint256[] memory betIndexs)
        external
        virtual
        override
        onlyOpen
        betable(user)
        onlyOwner
    {
        require(betIndexs.length == betOptions.length, "RCC10");
        for (uint256 i = 0; i < betIndexs.length; i++) {
            require(betIndexs[i] <= betOptions[i].brackets.length, "RCC11");
        }
        uint256 totalToken = getTotalToken(tokenAddress);
        uint256 totalEntryFee = listBuyer.length * entryFee;
        require(
            totalToken >= totalEntryFee + totalFee + fee + entryFee,
            "RCC12"
        );
        totalFee += fee;
        betOrNotYet[user] = true;
        listBuyer.push(user);
        bytes32 key = _generateKey(betIndexs);
        ticketSell[key].push(user);
        emit PlaceBet(user, betIndexs, entryFee + fee);
    }

    function _generateKey(uint256[] memory array)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(array));
    }

    function setIsResult() external override {
        require(msg.sender == oracle, "RCC13");
        competition.resulted = true;
    }

    function requestData() external onlyOpen {
        require(
            block.timestamp > scheduledStartTime + gapValidatitionTime,
            "RCC14"
        );
        require(!competition.resulted, "RCC15");
        bool enoughEntrant = _checkEntrantCodition();
        require(enoughEntrant, "RCC16");
        requestID = IChainLinkOracleSportData(oracle).requestData(
            competition.competitionId,
            competition.sportTypeAlias,
            betOptions
        );
    }

    function distributedReward() external virtual override onlyOpen nonReentrant {
        bool enoughEntrant = _checkEntrantCodition();

        address[] memory winners;
        uint256 ownerReward;
        uint256 creatorReward;
        uint256 winnerReward;
        uint256 totalEntryFee = listBuyer.length * entryFee;
        if (!enoughEntrant) {
            require(block.timestamp > endBetTime, "RCC17");
            status = Status.Non_Eligible;
            winners = listBuyer;
            winnerReward = totalEntryFee;
            ownerReward = totalFee;
        } else {
            (bytes32 key, bool success) = _getResult();
            if (!success) {
                uint256 maxTimeForRefunding = ICompetitionPool(owner)
                    .getMaxTimeWaitForRefunding();
                require(
                    block.timestamp > scheduledStartTime + maxTimeForRefunding,
                    "RCC18"
                );
                status = Status.Refund;
                winners = listBuyer;
                winnerReward = totalEntryFee + totalFee - fee;
                ownerReward = 0;
                creatorReward = fee;
            } else {
                status = Status.End;

                if (key != bytes32(0)) {
                    winners = ticketSell[key];
                } else {
                    winners = listBuyer;
                }

                if (winners.length > 0) {
                    winnerReward = totalEntryFee;
                    ownerReward = totalFee;
                } else {
                    ownerReward = totalFee + totalEntryFee;
                }
            }
        }
        competition.winnerReward = winnerReward;

        if (ownerReward > 0) {
            IERC20Upgradeable(tokenAddress).safeTransfer(owner, ownerReward);
        }
        if (creatorReward > 0) {
            IERC20Upgradeable(tokenAddress).safeTransfer(creator, creatorReward);
        }
        if (winnerReward > 0 && winners.length > 0) {
            _sendRewardToWinner(winners, winnerReward);
        }

        uint256 remaining = getTotalToken(tokenAddress);
        if (remaining > 0) {
            IERC20Upgradeable(tokenAddress).safeTransfer(owner, remaining);
        }

        emit Close(block.timestamp, competition.winnerReward);
    }

    function _getResult() internal view returns (bytes32 _key, bool _success) {
        if (ICompetitionPool(owner).refundable(address(this))) {
            return (bytes32(0), false);
        }
        (uint256[] memory result, ) = IChainLinkOracleSportData(oracle).getData(
            requestID
        );
        require(result.length == betOptions.length, "RCC19");

        uint256[] memory betWin = new uint256[](betOptions.length);

        for (uint256 i = 0; i < betOptions.length; i++) {
            BetOption memory betOption = betOptions[i];
            if (sportManager.checkTeamOption(betOptions[i].attribute)) {
                string memory team = String.toString(
                    result[i] / decimalOfResult
                );
                if (team.compare(competition.team1)) {
                    betWin[i] = 0;
                } else if (team.compare(competition.team2)) {
                    betWin[i] = 1;
                } else return (bytes32(0), false);
            } else {
                uint256 winIndex = _getBracketIndex(
                    betOption.brackets,
                    result[i]
                );
                betWin[i] = winIndex;
            }
        }

        return (_generateKey(betWin), true);
    }

    function _getBracketIndex(uint256[] memory brackets, uint256 value)
        internal
        pure
        returns (uint256 index)
    {
        if (value < brackets[0]) {
            return 0;
        }
        if (value >= brackets[brackets.length - 1]) {
            return brackets.length;
        }
        for (uint256 i = 0; i < brackets.length - 1; i++) {
            if (value < brackets[i + 1]) {
                return i + 1;
            }
        }
    }

    function _checkBetOption(uint256 _index, BetOption[] memory _betOptions)
        internal
        view
        returns (bool)
    {
        uint256[] memory brackets = _betOptions[_index].brackets;
        if (brackets[0] == 0) return false;

        ISportManager.Attribute memory attribute = sportManager
            .getAttributeById(_betOptions[_index].attribute);
        if (_betOptions[_index].mode == Mode.Team) {
            if (
                attribute.attributeSupportFor ==
                ISportManager.AttributeSupportFor.None ||
                attribute.attributeSupportFor ==
                ISportManager.AttributeSupportFor.Player
            ) {
                return false;
            }
        } else {
            if (_betOptions[_index].mode == Mode.Player) {
                uint256 lastBraket = _betOptions[_index].brackets[_betOptions[_index].brackets.length - 1];
                if (
                    attribute.attributeSupportFor ==
                    ISportManager.AttributeSupportFor.None ||
                    attribute.attributeSupportFor ==
                    ISportManager.AttributeSupportFor.Team ||
                    lastBraket != type(uint256).max
                ) {
                    return false;
                }
            }
        }

        for (uint256 i = 0; i < brackets.length - 1; i++) {
            if (brackets[i] >= brackets[i + 1]) {
                return false;
            }
        }
        // Betoptions is different
        for (uint256 j = _index + 1; j < _betOptions.length; j++) {
            if (
                _betOptions[_index].mode == _betOptions[j].mode &&
                _betOptions[_index].attribute == _betOptions[j].attribute &&
                _betOptions[_index].id.compare(_betOptions[j].id)
            ) {
                return false;
            }
        }

        return true;
    }
}
