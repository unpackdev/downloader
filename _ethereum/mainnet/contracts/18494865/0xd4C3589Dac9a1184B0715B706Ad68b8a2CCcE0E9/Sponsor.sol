// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./TimeExchange.sol";

/// @title Sponsor: a TIME Token Finance smart contract to relay and monitor transactions that generate value on the platform; it rewards users accordingly, which means users' transactions are being sponsored
/// @author https://timetoken.finance
/// @notice Reward is given in the network's native token, as recurrent prizes, which are granted according to users' activity frequency and their transacted amount.
/// Please refer that interacting with this contract is solely at your own risk!
/// Also, the administrator reserves the right to claim all funds from this contract at any time at their own discretion, once they deposit their own funds here...
/// There are other ways of interacting and trading with the TIME Token Finance platform, either through the TimeExchange contract or directly through the TimeToken and TimeIsUp contracts.
/// We encourage everyone who wishes to do so if they feel uncomfortable with the functions of this contract.
contract Sponsor {
    using Math for uint256;

    enum OperationType {
        MINT,
        SWAP_TIME,
        SWAP_TUP
    }

    struct Participant {
        bool isParticipating;
        bool wasSelected;
        address previousParticipant;
        address nextParticipant;
        mapping(uint256 => uint256) interactionPoints;
        mapping(uint256 => uint256) valuePoints;
    }

    struct Winners {
        address first;
        address second;
        address third;
        address fourth;
    }

    event ParticipantAdded(address participant);
    event ParticipantRemoved(address participant);
    event ParticipantsListCleaned();
    event RoundWinner(uint256 round, address participant, uint256 earnedPrize);

    bool private _canReceiveAdditionalFunds = true;
    bool private _isOperationLocked;

    bool public isOperationTypeFlipped;

    TimeExchange public immutable timeExchange;
    ITimeToken public immutable timeToken;
    ITimeIsUp public immutable tupToken;

    address public administrator;
    address public currentLeader;
    address public firstParticipant;
    address public lastParticipant;

    uint256 private constant D = 10 ** 18;
    uint256 public constant TIME_BURNING_RATE = 5_000;
    uint256 public constant MININUM_NUMBER_OF_PARTICIPANTS = 5;
    uint256 public constant NUMBER_OF_SELECTED_WINNERS = 4;

    uint256 private CURRENT_FEES_PERCENTAGE;
    uint256 private PERCENTAGE_PROFIT_TARGET = 11_000;
    uint256 private REBATE_PERCENTAGE = 100;

    uint256 public accumulatedPrize;
    uint256 public currentAdditionalPrize;
    uint256 public currentPrize;
    uint256 public currentRebate;
    uint256 public currentTarget;
    uint256 public currentValueMoved;
    uint256 public maxInteractionPoints;
    uint256 public minAmountToEarnPoints;
    uint256 public numberOfParticipants;
    uint256 public round;

    mapping(address => uint256) private _currentBlock;

    mapping(address => uint256) public lastBlock;
    mapping(address => uint256) public prizeToClaim;
    mapping(address => uint256) public remainingTime;

    mapping(uint256 => Winners winners) public roundWinners;

    mapping(address => Participant participant) public participants;

    constructor(address timeTokenAddress, address tupTokenAddress, address timeExchangeAddress) {
        administrator = msg.sender;
        timeToken = ITimeToken(payable(timeTokenAddress));
        tupToken = ITimeIsUp(payable(tupTokenAddress));
        timeExchange = TimeExchange(payable(timeExchangeAddress));
        setCurrentFeesPercentage(timeExchange.FEE());
        setMinAmountToEarnPoints(0.1 ether);
        round = 1;
    }

    receive() external payable {
        _depositPrize(0, msg.value);
    }

    fallback() external payable {
        require(msg.data.length == 0);
        _depositPrize(0, msg.value);
    }

    /// @notice Modifier to allow only administrator access
    modifier admin() {
        require(msg.sender == administrator, "Sponsor: only admin allowed");
        _;
    }

    /// @notice Modifier to allow registering additional funds to prize when receiveing native token of the network
    modifier canReceiveAdditional() {
        _canReceiveAdditionalFunds = true;
        _;
        _canReceiveAdditionalFunds = false;
    }

    /// @notice Modifier to disallow registering additional funds to prize when receiveing native token of the network
    modifier cannotReceiveAdditional() {
        _canReceiveAdditionalFunds = false;
        _;
        _canReceiveAdditionalFunds = true;
    }

    /// @notice Verifies if the current round can be finished
    modifier checkEndOfRound() {
        _;
        if (queryAmountRemainingForPrize() == 0 && currentPrize > 0 && numberOfParticipants >= MININUM_NUMBER_OF_PARTICIPANTS) {
            _rewardWinnersAndCloseRound();
        }
    }

    /// @notice Modifier to make a function runs only once per block
    modifier onlyOncePerBlock() {
        require(block.number != _currentBlock[tx.origin], "Sponsor: you cannot perform this operation again in this block");
        _currentBlock[tx.origin] = block.number;
        _;
    }

    /// @notice Implement security to avoid reentrancy attacks
    modifier nonReentrant() {
        require(!_isOperationLocked, "Sponsor: this operation is locked");
        _isOperationLocked = true;
        _;
        _isOperationLocked = false;
    }

    /// @notice Modifier used when the status of the current participant should be checked and updated
    /// @dev Called together with mint(), swap(), and extendParticipationPeriod() functions
    modifier update() {
        if ((lastBlock[msg.sender] == 0 && block.number != 0) || remainingTime[msg.sender] == 0) {
            lastBlock[msg.sender] = block.number;
        }
        uint256 elapsedTime = block.number - lastBlock[msg.sender];
        if (elapsedTime > remainingTime[msg.sender] && participants[msg.sender].isParticipating) {
            _removeParticipant(msg.sender);
        }
        _;
        remainingTime[msg.sender] = (elapsedTime > remainingTime[msg.sender]) ? 0 : remainingTime[msg.sender] - elapsedTime;
        lastBlock[msg.sender] = block.number;
        if (remainingTime[msg.sender] >= elapsedTime && remainingTime[msg.sender] > 0 && !participants[msg.sender].isParticipating) {
            _addParticipant(msg.sender);
        }
    }

    //
    /// @notice Add a participant and adjusts the participants chained list
    /// @dev The current participant added is sent to the end of the list
    /// @param participant The address of the participant
    function _addParticipant(address participant) private {
        if (participant != address(0) && !participants[participant].isParticipating) {
            participants[participant].previousParticipant = lastParticipant;
            participants[participant].nextParticipant = address(0);
            if (firstParticipant == address(0)) {
                firstParticipant = participant;
            }
            if (lastParticipant != address(0)) {
                participants[lastParticipant].nextParticipant = participant;
            }
            lastParticipant = participant;
            participants[participant].isParticipating = true;
            numberOfParticipants++;
            emit ParticipantAdded(participant);
        }
    }

    /// @notice Burn some TIME tokens in order to regulate the market inflation
    /// @dev It runs with try { } catch to not revert in case of being unsuccessful
    function _burnTime() private {
        uint256 balanceInTime = timeToken.balanceOf(address(this));
        if (balanceInTime > 0) {
            try timeToken.burn(balanceInTime.mulDiv(TIME_BURNING_RATE, 10_000)) { } catch { }
        }
    }

    /// @notice Resets the entire list of participants in the contract
    /// @dev It also should clean the participants' score/pontuation, if the case
    function _cleanParticipantsList() private {
        address currentParticipant = firstParticipant;
        address nextParticipant;
        while (currentParticipant != address(0)) {
            nextParticipant = participants[currentParticipant].nextParticipant;
            participants[currentParticipant].previousParticipant = address(0);
            participants[currentParticipant].nextParticipant = address(0);
            participants[currentParticipant].isParticipating = false;
            participants[currentParticipant].wasSelected = false;
            participants[currentParticipant].interactionPoints[round] = 0;
            participants[currentParticipant].valuePoints[round] = 0;
            remainingTime[currentParticipant] = 0;
            lastBlock[currentParticipant] = block.number;
            currentParticipant = nextParticipant;
        }
        firstParticipant = address(0);
        lastParticipant = address(0);
        numberOfParticipants = 0;
        emit ParticipantsListCleaned();
    }

    /// @notice Deposits the resources used as prizes (main and additional)
    /// @dev Indirectly called by admins and third parties (as additional deposit)
    /// @param amount The main deposit amount
    /// @param additionalAmount The additional deposit amount
    function _depositPrize(uint256 amount, uint256 additionalAmount) private {
        require(msg.value > 0, "Sponsor: please deposit some amount");
        if (_canReceiveAdditionalFunds) {
            if (amount > 0) {
                accumulatedPrize += amount;
                if (currentPrize == 0) {
                    currentPrize = accumulatedPrize / 2;
                    currentTarget = (currentPrize + currentPrize.mulDiv(PERCENTAGE_PROFIT_TARGET, 10_000)).mulDiv(10_000, CURRENT_FEES_PERCENTAGE);
                }
            }
            if (additionalAmount > 0) {
                uint256 halfAdditionalAmount = (additionalAmount / 2);
                accumulatedPrize += additionalAmount;
                currentAdditionalPrize += halfAdditionalAmount;
                currentRebate += halfAdditionalAmount.mulDiv(REBATE_PERCENTAGE, 10_000);
            }
        }
    }

    /// @notice Receives additional resources from the TIME and TUP contracts
    /// @dev It calls the TUP contract indirectly, using Claimer
    function _earnAdditionalResources() private canReceiveAdditional {
        if (timeToken.withdrawableShareBalance(address(this)) > 0) {
            try timeToken.withdrawShare() { } catch { }
        }
        if (tupToken.queryPublicReward() > 0) {
            try tupToken.splitSharesWithReward() { } catch { }
        }
    }

    /// @notice Calculates and storage the received points of a participant, but only if the negotiated amount is above the minimum established
    /// @dev It classifies operations according to its relevance for the protocol
    /// @param participant The address of participant to register points
    /// @param operation Type of the operation called by a participant and relayed to the TimeExchange contract
    /// @param amount The amount of native tokens moved by the participant
    function _registerPoints(address participant, OperationType operation, uint256 amount) private {
        if (amount >= minAmountToEarnPoints && participant != address(0)) {
            uint256 weight = isOperationTypeFlipped ? (uint256(type(OperationType).max) - uint256(operation)) + 1 : uint256(operation) + 1;
            participants[participant].interactionPoints[round] += weight;
            participants[participant].valuePoints[round] += (amount * weight);
            if (participants[participant].interactionPoints[round] > maxInteractionPoints) {
                maxInteractionPoints = participants[participant].interactionPoints[round];
                currentLeader = participant;
            }
        }
    }

    /// @notice Remove a participant and adjusts the participants chained list of the contract
    /// @dev It concatenates the right next participant of the current participant with the previous one
    /// @param participant The address of a participant which will be removed of the chained list
    function _removeParticipant(address participant) private {
        if (participant != address(0) && participants[participant].isParticipating) {
            address previousParticipant = participants[participant].previousParticipant;
            address nextParticipant = participants[participant].nextParticipant;
            if (lastParticipant == participant) {
                lastParticipant = previousParticipant;
            }
            if (firstParticipant == participant) {
                firstParticipant = nextParticipant;
            }
            if (previousParticipant != address(0)) {
                participants[previousParticipant].nextParticipant = nextParticipant;
            }
            if (nextParticipant != address(0)) {
                participants[nextParticipant].previousParticipant = previousParticipant;
            }
            if (participant == currentLeader) {
                currentLeader = address(0);
                maxInteractionPoints = 0;
            }
            participants[participant].previousParticipant = address(0);
            participants[participant].nextParticipant = address(0);
            participants[participant].isParticipating = false;
            participants[participant].wasSelected = false;
            participants[participant].interactionPoints[round] = 0;
            participants[participant].valuePoints[round] = 0;
            numberOfParticipants--;
            emit ParticipantRemoved(participant);
        }
    }

    /// @notice Performs the reward and close the current round
    /// @dev Another round is automatically initiated
    function _rewardWinnersAndCloseRound() private nonReentrant {
        uint256 totalPrize = queryCurrentTotalPrize();
        if (totalPrize <= address(this).balance) {
            uint256 prizeShares = totalPrize / 10;
            if (!checkParticipation(currentLeader)) {
                _removeParticipant(currentLeader);
                if (numberOfParticipants < MININUM_NUMBER_OF_PARTICIPANTS) {
                    return;
                }
                currentLeader = _selectRandomWinner();
            } else {
                participants[currentLeader].wasSelected = true;
            }
            uint256 earnedPrize = (NUMBER_OF_SELECTED_WINNERS * prizeShares);
            prizeToClaim[currentLeader] += earnedPrize;
            emit RoundWinner(round, currentLeader, earnedPrize);
            address[] memory winners = _selectRoundWinners();
            for (uint256 i = 0; i < winners.length; i++) {
                earnedPrize = (winners.length - i) * prizeShares;
                prizeToClaim[winners[i]] += earnedPrize;
                emit RoundWinner(round, winners[i], earnedPrize);
            }
            roundWinners[round].first = currentLeader;
            roundWinners[round].second = winners[0];
            roundWinners[round].third = winners[1];
            roundWinners[round].fourth = winners[2];
            accumulatedPrize -= totalPrize;
            currentPrize = accumulatedPrize / 2;
            currentTarget = currentPrize > 0 ? (currentPrize + currentPrize.mulDiv(PERCENTAGE_PROFIT_TARGET, 10_000)).mulDiv(10_000, CURRENT_FEES_PERCENTAGE) : 0;
            currentAdditionalPrize = 0;
            currentRebate = 0;
            currentValueMoved = 0;
            _burnTime();
            _cleanParticipantsList();
            maxInteractionPoints = 0;
            currentLeader = address(0);
            round++;
        }
    }

    /// @notice Picks a randomly selected winner
    /// @dev It traverses the whole chained list of participants to pick those who match with a random index number. It marks the winner from that list right after the selection
    /// @return randomWinner The address of the picked random winner
    function _selectRandomWinner() private returns (address randomWinner) {
        uint256 nonce = 1;
        while (randomWinner == address(0)) {
            address currentParticipant = firstParticipant;
            uint256 randomWinnerIndex = uint256(
                keccak256(
                    abi.encode(
                        nonce++, block.number, block.timestamp, block.prevrandao, address(this), currentPrize, currentValueMoved, currentTarget
                    )
                )
            ) % numberOfParticipants;
            uint256 currentIndex;
            while (currentParticipant != address(0)) {
                if (currentIndex == randomWinnerIndex && checkParticipation(currentParticipant)) {
                    if (participants[currentParticipant].wasSelected) {
                        if (randomWinnerIndex == numberOfParticipants - 1) {
                            currentIndex = 0;
                            randomWinnerIndex = 0;
                            currentParticipant = firstParticipant;
                        } else {
                            randomWinnerIndex++;
                        }
                        continue;
                    }
                    participants[currentParticipant].wasSelected = true;
                    randomWinner = currentParticipant;
                    break;
                }
                currentIndex++;
                currentParticipant = participants[currentParticipant].nextParticipant;
            }
        }
    }

    /// @notice Select the round winners with the highest value points earned. The last winner is randomly selected
    /// @dev It traverses the whole chained list of participants to pick those with the highest earned points. It marks the winners from that list right after the selection
    /// @return winners Array containing addresses of the round winners
    function _selectRoundWinners() private returns (address[] memory winners) {
        winners = new address[](NUMBER_OF_SELECTED_WINNERS - 1);
        uint256[] memory maxPoint = new uint256[](winners.length);
        address currentParticipant;
        address nextParticipant;
        for (uint256 i = 0; i < winners.length - 1; i++) {
            currentParticipant = firstParticipant;
            while (currentParticipant != address(0)) {
                nextParticipant = participants[currentParticipant].nextParticipant;
                if (
                    participants[currentParticipant].valuePoints[round] > maxPoint[i] && checkParticipation(currentParticipant)
                        && !participants[currentParticipant].wasSelected
                ) {
                    maxPoint[i] = participants[currentParticipant].valuePoints[round];
                    winners[i] = currentParticipant;
                }
                currentParticipant = nextParticipant;
            }
            // If still has no winner, it picks randomly
            if (winners[i] == address(0)) {
                winners[i] = _selectRandomWinner();
            }
            participants[winners[i]].wasSelected = true;
        }
        // It now picks a random winner as the last winner
        winners[winners.length - 1] = _selectRandomWinner();
        return winners;
    }

    /// @notice Withdraws the total prize received by the sponsors
    /// @dev Called by a user after receiveing a prize for his address. The prize remains in the contract for an indefinite time. Non reentrant
    function claimPrize() external nonReentrant {
        require(prizeToClaim[msg.sender] > 0, "Sponsor: there is no prize to claim for the caller address");
        require(prizeToClaim[msg.sender] <= address(this).balance, "Sponsor: there is no enough amount to withdraw");
        uint256 amount = prizeToClaim[msg.sender];
        prizeToClaim[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /// @notice Informs if a participant is active in the current sponsorship round
    /// @dev It must check if the participant also has enough TIME to be consumed
    /// @param participant The participant's address
    /// @return isParticipating If the informed address is participating in the sponsorship round indeed
    function checkParticipation(address participant) public view returns (bool) {
        return ((remainingTime[participant] >= (block.number - lastBlock[participant])) && participants[participant].isParticipating);
    }

    /// @notice Deposit the main contract prize (Usually called by the sponsors - admins). The contract can receive additional funds directly from other sources
    /// @dev Only admins can call this function. It calls a private function by chaging the order of parameters, meaning that it is the main deposit
    function depositPrize() external payable admin {
        _depositPrize(msg.value, 0);
    }

    /// @notice Withdraws all the funds of the contract to the administrator address and restarts the contract variables
    /// @dev Only admin can call this function. For emergency only!
    function emergencyWithdraw() external admin {
        _cleanParticipantsList();
        accumulatedPrize = 0;
        currentAdditionalPrize = 0;
        currentPrize = 0;
        currentRebate = 0;
        currentTarget = 0;
        currentValueMoved = 0;
        currentLeader = address(0);
        maxInteractionPoints = 0;
        uint256 tupBalance = tupToken.balanceOf(address(this));
        if (tupBalance > 0) {
            try tupToken.transfer(administrator, tupBalance) { } catch { }
        }
        try timeToken.transfer(administrator, timeToken.balanceOf(address(this))) { } catch { }
        payable(administrator).transfer(address(this).balance);
    }

    /// @notice Enables participation in the sponsorship by depositing TIME
    /// @dev User must approve TIME to be spent before calling this function
    /// @param amountTime The amount of TIME the user would like to deposit in order to participate the current sponsorship round
    function extendParticipationPeriod(uint256 amountTime) external cannotReceiveAdditional checkEndOfRound update {
        require(
            timeToken.allowance(msg.sender, address(this)) >= amountTime, "Sponsor: please approve the TIME amount to extend your sponsorship period"
        );
        require(amountTime >= D, "Sponsor: you should deposit 1 TIME or more to extend your sponsorship period");
        timeToken.transferFrom(msg.sender, address(this), amountTime);
        remainingTime[msg.sender] += amountTime.mulDiv(1, D);
    }

    /// @notice Flip the operation type so the most value operation turns into the lesser one, and vice-versa
    /// @dev The isOperationTypeFlipped is used in _registerPoints() function to adjust the weight applied over the operation number
    function flipOperationType() external admin {
        isOperationTypeFlipped = !isOperationTypeFlipped;
    }

    /// @notice Performs mint of TUP tokens by demand
    /// @dev Relays the mint function to the TimeIsUp contract, but observing and registering additional information
    /// @param amountTime The amount of TIME the user wants to use to mint TUP
    function mint(uint256 amountTime) external payable cannotReceiveAdditional checkEndOfRound onlyOncePerBlock update {
        require(
            timeToken.allowance(msg.sender, address(this)) >= amountTime, "Sponsor: you should allow TIME to be spent before calling the function"
        );
        if (amountTime > 0) {
            timeToken.transferFrom(msg.sender, address(this), amountTime);
            timeToken.approve(address(tupToken), amountTime);
        }
        uint256 balanceBefore = tupToken.balanceOf(address(this));
        try tupToken.mint{ value: msg.value }(amountTime) {
            currentValueMoved += msg.value;
            uint256 balanceAfter = tupToken.balanceOf(address(this));
            tupToken.transfer(msg.sender, balanceAfter - balanceBefore);
            if (checkParticipation(msg.sender) && amountTime == 0) {
                _registerPoints(msg.sender, OperationType.MINT, msg.value);
                _earnAdditionalResources();
            }
        } catch {
            revert("Sponsor: unable to relay mint");
        }
    }

    /// @notice Query for the amount needed to unlock the prize for round winners
    /// @return amountRemaining The amount which is remaining to achieve the current target for prize unlock
    function queryAmountRemainingForPrize() public view returns (uint256) {
        return currentTarget > (currentRebate + currentValueMoved) ? currentTarget - (currentRebate + currentValueMoved) : 0;
    }

    /// @notice Query for the prize amount deposited by admins and earned by the contract
    /// @return totalPrize Current prize + additional prize earned
    function queryCurrentTotalPrize() public view returns (uint256) {
        return (currentPrize + currentAdditionalPrize);
    }

    /// @notice Query for the interaction points of a participant
    /// @return interactionPoints Informs the number of interactions (times an operation weight) a given user address interacted with the Sponsor contract
    function queryInteractionPoints(address participant) external view returns (uint256) {
        return checkParticipation(participant) ? participants[participant].interactionPoints[round] : 0;
    }

    /// @notice Query for the value points of a participant
    /// @return valuePoints Informs the amount of native tokens (times an operation weight) a given user address negotiated with the Sponsor contract
    function queryValuePoints(address participant) external view returns (uint256) {
        return checkParticipation(participant) ? participants[participant].valuePoints[round] : 0;
    }

    /// @notice Changes the new administrator address
    /// @dev Only the owner of the contract can access
    /// @param newAdministrator The new address value to be set.
    function setAdministrator(address newAdministrator) public admin {
        administrator = newAdministrator;
    }

    /// @notice Adjusts the new fees percentage charged by the protocol
    /// @dev Only the owner of the contract can access
    /// @param newCurrentFeesPercentage The new value to be set. Factor of 10_000. Example: if percentage is 1%, it should be set as 100
    function setCurrentFeesPercentage(uint256 newCurrentFeesPercentage) public admin {
        CURRENT_FEES_PERCENTAGE = newCurrentFeesPercentage;
    }

    /// @notice Adjusts the minimum amount a participant should trade to earn points in the protocol
    /// @dev Only the owner of the contract can access
    /// @param newMinAmount The new value to be set. It should be defined in terms of the native token of the underlying network
    function setMinAmountToEarnPoints(uint256 newMinAmount) public admin {
        minAmountToEarnPoints = newMinAmount;
    }

    /// @notice Adjusts the percentage of the desirable profit
    /// @dev Only the owner of the contract can access
    /// @param newProfitTargetPercentage The new value to be set. Factor of 10_000. Example: if percentage is 1%, it should be set as 100
    function setPercentageProfitTarget(uint256 newProfitTargetPercentage) external admin {
        PERCENTAGE_PROFIT_TARGET = newProfitTargetPercentage;
    }

    /// @notice Adjusts the percentage of rebates to achieve prize targets
    /// @dev Only the owner of the contract can access
    /// @param newRebatePercentage The new value to be set. Factor of 10_000. Example: if percentage is 1%, it should be set as 100
    function setRebatePercentage(uint256 newRebatePercentage) external admin {
        REBATE_PERCENTAGE = newRebatePercentage;
    }

    /// @notice It relay swaps to TimeExchange contract, but register points only for native currency to another token
    /// @dev It should inform address(0) as tokenFrom or tokenTo when considering native currency
    /// @param tokenFrom The address of the token to be swapped
    /// @param tokenTo The address of the token to be swapped
    /// @param amount The token or native currency amount to be swapped
    function swap(address tokenFrom, address tokenTo, uint256 amount)
        external
        payable
        cannotReceiveAdditional
        checkEndOfRound
        onlyOncePerBlock
        update
    {
        IERC20 tokenToTransfer;
        uint256 balanceBefore;
        if (tokenFrom != address(0)) {
            IERC20 tokenFromTransfer = IERC20(tokenFrom);
            require(tokenFromTransfer.allowance(msg.sender, address(this)) >= amount, "Sponsor: please approve the amount to swap");
            tokenFromTransfer.transferFrom(msg.sender, address(this), amount);
            tokenFromTransfer.approve(address(timeExchange), amount);
        }
        if (tokenTo != address(0)) {
            tokenToTransfer = IERC20(tokenTo);
            balanceBefore = tokenToTransfer.balanceOf(address(this));
        } else {
            balanceBefore = address(this).balance;
        }
        try timeExchange.swap{ value: msg.value }(tokenFrom, tokenTo, amount) {
            uint256 balanceAfter;
            if (tokenTo != address(0)) {
                balanceAfter = tokenToTransfer.balanceOf(address(this));
                tokenToTransfer.transfer(msg.sender, balanceAfter - balanceBefore);
            } else {
                balanceAfter = address(this).balance;
                payable(msg.sender).transfer(balanceAfter - balanceBefore);
            }
            if (tokenFrom == address(0)) {
                if (checkParticipation(msg.sender)) {
                    _registerPoints(msg.sender, tokenTo == address(timeToken) ? OperationType.SWAP_TIME : OperationType.SWAP_TUP, msg.value);
                    _earnAdditionalResources();
                }
                currentValueMoved += msg.value;
            }
        } catch {
            revert("Sponsor: unable to relay swap");
        }
    }

    /// @notice Withdraw native tokens given to address zero
    /// @dev Eventually the winners don't have remaining TIME deposited when a round is finished. When this happens, the prize goes to the address(0)
    function withdrawFromAddressZeroPrizes() external admin {
        require(prizeToClaim[address(0)] > 0, "Sponsor: there is no prize to claim for the zero address");
        require(prizeToClaim[address(0)] <= address(this).balance, "Sponsor: there is no enough amount to withdraw");
        uint256 amount = prizeToClaim[address(0)];
        prizeToClaim[address(0)] = 0;
        payable(administrator).transfer(amount);
    }
}
