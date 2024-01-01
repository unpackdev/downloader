// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./AggregatorV3Interface.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./RefProgramCodeGenerator.sol";
import "./AutomateTaskCreator.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

interface IERC20Balance {
    function decimals() external view returns (uint8);
}

interface IPredictionFactory {
    function addEthPayout(uint256 value) external;

    function owner() external view returns (address);
}

interface INonce {
    function generatedNonce(
        address user,
        uint256 roundID
    ) external pure returns (uint256);
}

contract PredictionMarket is Ownable, ReentrancyGuard, AutomateTaskCreator {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    event BetBear(address indexed user, uint256 indexed round, uint256 amount);
    event BetBull(address indexed user, uint256 indexed round, uint256 amount);
    event BullClaimed(
        address indexed user,
        uint256 roundId,
        uint256 amountClaimed
    );
    event BearClaimed(
        address indexed user,
        uint256 roundId,
        uint256 amountClaimed
    );
    event CounterTaskCreated(bytes32 taskId);

    receive() external payable {}

    address public predictionFactory;

    AggregatorV3Interface internal dataFeed;

    bytes32 public taskId;

    address private _refProgramCodeGenerator;
    bool public isRefProgramOpen;

    mapping(address => EnumerableSet.UintSet) private _userActivatedCodes;
    mapping(address => EnumerableSet.UintSet) private _userGeneratedCodes;
    mapping(uint256 => EnumerableSet.AddressSet) private _CodeClaimedAddresses;
    uint256 public totalCodesUsed;

    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public treasuryWallet;
    address public token;
    address public pair;

    uint256 public roundID;
    uint256 public roundPeriod = 5 minutes;
    uint256 public bufferTime = 40;

    uint256 public minimumBet = 0.007 ether;
    uint256 public poolFee = 500;
    bool public isStopped;

    struct Round {
        uint256 startTimestamp;
        uint256 expireTimestamp;
        uint256 openPrice;
        uint256 closePrice;
        uint256 bearBetsAmount;
        uint256 bullBetsAmount;
        uint256 totalEthBets;
        bool roundClose;
    }

    mapping(uint256 => Round) private rounds;

    struct UserEntries {
        uint256 bullEntries;
        uint256 bearEntries;
        uint256 totalEthBetted;
        uint256 totalEthWon;
        bool bullClaimed;
        bool bearClaimed;
    }

    mapping(address => mapping(uint256 => UserEntries)) private userEntries;
    mapping(address => EnumerableSet.UintSet) private _userBetRounds;

    uint256 public totalEthPayoutsMade;

    constructor(
        address _token,
        address _automate,
        address _fundsOwner
    ) payable AutomateTaskCreator(_automate, _fundsOwner) {
        require(hasEthLiquidity(_token), "Pair has no liquidity");
        dataFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );

        token = _token;
        pair = getPair(_token);
        treasuryWallet = _fundsOwner;
        predictionFactory = msg.sender;
        require(pair != address(0), "No pair found");

        depositFunds(msg.value, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        createTask();
    }

    // Ref programm

    function getUserActivatedCodes(
        address user
    ) public view returns (uint256[] memory) {
        return _userActivatedCodes[user].values();
    }

    function getUserGeneratedCodes(
        address user
    ) public view returns (uint256[] memory) {
        return _userGeneratedCodes[user].values();
    }

    function getCodesUsedAddresses(
        uint256 code
    ) public view returns (address[] memory) {
        return _CodeClaimedAddresses[code].values();
    }

    function getCodesUsedCount(uint256 code) public view returns (uint256) {
        return _CodeClaimedAddresses[code].length();
    }

    function getUserGeneratedCodesCount(
        address user
    ) public view returns (uint256) {
        return _userGeneratedCodes[user].length();
    }

    function getUserActivatedCodesCount(
        address user
    ) public view returns (uint256) {
        return _userActivatedCodes[user].length();
    }

    function isCodeUsable(uint256 code) public view returns (bool) {
        if (_CodeClaimedAddresses[code].length() != 1) {
            return false;
        }

        if (_CodeClaimedAddresses[code].at(0) == address(0)) {
            return false;
        }

        return true;
    }

    function updateRefProgrammStatus() public onlyOwner {
        if (!isRefProgramOpen && _refProgramCodeGenerator == address(0)) {
            RefProgramCodeGenerator refProgramCodeGenerator = new RefProgramCodeGenerator();
            _refProgramCodeGenerator = address(refProgramCodeGenerator);
        }
        isRefProgramOpen = !isRefProgramOpen;
    }

    function setRoundPeriod(uint256 _newRoundPeriod) public onlyOwner {
        roundPeriod = _newRoundPeriod;
    }

    // End ref program

    function depositFunds(uint256 _amount, address _token) public payable {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value: ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function createTask() public {
        require(taskId == bytes32(""), "Already started task");

        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeCall(this.checker, ())
        );
        moduleData.args[1] = _proxyModuleArg();

        bytes32 id = _createTask(
            address(this),
            abi.encode(this.startNewRound.selector),
            moduleData,
            address(0)
        );

        taskId = id;
        emit CounterTaskCreated(id);
    }

    function getRoundInfo(
        uint256 roundId
    )
        public
        view
        returns (
            uint256 startTimestamp,
            uint256 expireTimestamp,
            uint256 openPrice,
            uint256 closePrice,
            uint256 bearBetsAmount,
            uint256 bullBetsAmount,
            uint256 totalEthBets,
            bool roundClose
        )
    {
        Round storage round = rounds[roundId];
        return (
            round.startTimestamp,
            round.expireTimestamp,
            round.openPrice,
            round.closePrice,
            round.bearBetsAmount,
            round.bullBetsAmount,
            round.totalEthBets,
            round.roundClose
        );
    }

    function getUserEntries(
        address user,
        uint256 roundId
    )
        public
        view
        returns (
            uint256 bullEntries,
            uint256 bearEntries,
            uint256 totalEthBetted,
            uint256 totalEthWon,
            bool bullClaimed,
            bool bearClaimed
        )
    {
        UserEntries storage entries = userEntries[user][roundId];
        return (
            entries.bullEntries,
            entries.bearEntries,
            entries.totalEthBetted,
            entries.totalEthWon,
            entries.bullClaimed,
            entries.bearClaimed
        );
    }

    function getUserRounds(
        address user
    ) public view returns (uint256[] memory) {
        return _userBetRounds[user].values();
    }

    function getTokenPriceEth() internal view returns (uint256) {
        uint256 totalEth = IERC20(IUniswapV2Router01(router).WETH()).balanceOf(
            pair
        ) * 10 ** IERC20Balance(token).decimals();
        uint256 tokenBalance = IERC20(token).balanceOf(pair);
        return totalEth / tokenBalance;
    }

    function getChainlinkDataFeedLatestAnswer() internal view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function getTokenPriceUSD() public view returns (uint256) {
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());
        uint256 tokenEthPrice = getTokenPriceEth();

        return ethPrice * tokenEthPrice;
    }

    function getPair(address _token) internal view returns (address) {
        address _pair;
        address factory = IUniswapV2Router01(router).factory();
        address wEth = IUniswapV2Router01(router).WETH();
        _pair = IUniswapV2Factory(factory).getPair(_token, wEth);
        return _pair;
    }

    function checker()
        public
        view
        returns (bool canExec, bytes memory execPayload)
    {
        Round storage roundData = rounds[roundID];

        if (roundID == 0 && roundData.startTimestamp == 0) {
            canExec = true;
        } else if (!isStopped) {
            canExec = roundData.expireTimestamp < block.timestamp;
        }

        execPayload = abi.encodeCall(this.startNewRound, ());
    }

    function stop() public {
        require(
            msg.sender == owner() ||
                msg.sender == IPredictionFactory(predictionFactory).owner()
        );
        isStopped = !isStopped;
    }

    function newRoundStartable() public view returns (bool canExec) {
        Round storage roundData = rounds[roundID];

        if (roundID == 0 && roundData.startTimestamp == 0) {
            canExec = true;
        } else if (!isStopped) {
            canExec = roundData.expireTimestamp < block.timestamp;
        }
    }

    function startNewRound() public {
        require(newRoundStartable(), "Round not ended");
        Round storage currentRound = rounds[roundID];
        Round storage nextRound = rounds[roundID + 1];

        if (roundID == 0 && currentRound.startTimestamp == 0) {
            currentRound.startTimestamp = block.timestamp;
            currentRound.expireTimestamp = block.timestamp + roundPeriod;
            currentRound.openPrice = getTokenPriceUSD();
        } else {
            currentRound.closePrice = getTokenPriceUSD();
            currentRound.roundClose = true;

            nextRound.startTimestamp = block.timestamp;
            nextRound.expireTimestamp = block.timestamp + roundPeriod;
            nextRound.openPrice = getTokenPriceUSD();
            roundID++;
        }
    }

    function roundResult(uint256 _roundID) public view returns (bool isBull) {
        Round storage roundData = rounds[_roundID];
        return (roundData.openPrice < roundData.closePrice);
    }

    function isEven(uint256 _roundID) public view returns (bool) {
        Round storage roundData = rounds[_roundID];
        return (roundData.openPrice == roundData.closePrice);
    }

    function bettingOpen() public view returns (bool) {
        Round storage roundData = rounds[roundID];
        return roundData.expireTimestamp - bufferTime > block.timestamp;
    }

    function enterBull(uint256 amount, uint256 refCode) public payable {
        require(amount == msg.value, "Amount incorrect");
        require(msg.value >= minimumBet, "Bet more");
        UserEntries storage userData = userEntries[msg.sender][roundID + 1];
        require(
            userData.bearEntries == 0 && userData.bullEntries == 0,
            "Already entered"
        );
        bool canBet = bettingOpen();
        require(canBet);

        if (isRefProgramOpen) {
            uint256 userNonce = INonce(_refProgramCodeGenerator).generatedNonce(
                _msgSender(),
                roundID
            ) % 9999999;

            _userGeneratedCodes[msg.sender].add(userNonce);
            _userActivatedCodes[msg.sender].add(userNonce);
            _CodeClaimedAddresses[userNonce].add(msg.sender);
            totalCodesUsed++;

            if (refCode != 0) {
                require(isCodeUsable(refCode), "Code does not exist or used");
                uint256 newCode = refCode % 999;
                address sharer = _CodeClaimedAddresses[refCode].at(0);

                _userActivatedCodes[sharer].add(newCode);
                _userActivatedCodes[msg.sender].add(refCode);
                _CodeClaimedAddresses[refCode].add(msg.sender);
            }

            totalCodesUsed + 2;
        }

        Round storage roundData = rounds[roundID + 1];
        uint256 fee = (amount * 500) / 10_000;
        bool success;

        (success, ) = address(treasuryWallet).call{value: fee}("");

        amount -= fee;
        roundData.bullBetsAmount += amount;
        roundData.totalEthBets += amount;

        userData.bullEntries += amount;
        userData.totalEthBetted += amount;
        _userBetRounds[msg.sender].add(roundID + 1);

        emit BetBull(msg.sender, roundID + 1, amount);
    }

    function enterBear(uint256 amount, uint256 refCode) public payable {
        require(amount == msg.value, "Amount incorrect");
        require(msg.value >= minimumBet, "Bet more");
        UserEntries storage userData = userEntries[msg.sender][roundID + 1];
        require(
            userData.bullEntries == 0 || userData.bearEntries == 0,
            "Already entered"
        );
        bool canBet = bettingOpen();
        require(canBet);

        if (isRefProgramOpen) {
            uint256 userNonce = INonce(_refProgramCodeGenerator).generatedNonce(
                _msgSender(),
                roundID
            ) % 9999999;

            _userGeneratedCodes[msg.sender].add(userNonce);
            _userActivatedCodes[msg.sender].add(userNonce);
            _CodeClaimedAddresses[userNonce].add(msg.sender);
            totalCodesUsed++;

            if (refCode != 0) {
                require(isCodeUsable(refCode), "Code does not exist or used");
                address sharer = _CodeClaimedAddresses[refCode].at(0);
                require(msg.sender != sharer, "Code cant be claimed");
                uint256 newCode = refCode % 999;

                _userActivatedCodes[sharer].add(newCode);
                _userActivatedCodes[msg.sender].add(refCode);
                _CodeClaimedAddresses[refCode].add(msg.sender);
            }

            totalCodesUsed + 2;
        }

        Round storage roundData = rounds[roundID + 1];
        uint256 fee = (amount * 500) / 10_000;
        bool success;

        (success, ) = address(treasuryWallet).call{value: fee}("");

        amount -= fee;
        roundData.bearBetsAmount += amount;
        roundData.totalEthBets += amount;

        userData.bearEntries += amount;
        userData.totalEthBetted += amount;
        _userBetRounds[msg.sender].add(roundID + 1);

        emit BetBear(msg.sender, roundID + 1, amount);
    }

    function bullShare(
        address user,
        uint256 _roundID
    ) public view returns (uint256 share) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];

        uint256 bullAmnt = roundData.bullBetsAmount;
        uint256 betAmnt = userData.bullEntries;

        if (betAmnt > 0) {
            share = (betAmnt * 10_000) / bullAmnt;
        } else {
            share = 0;
        }
    }

    function bearShare(
        address user,
        uint256 _roundID
    ) public view returns (uint256 share) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];

        uint256 bearAmnt = roundData.bearBetsAmount;
        uint256 betAmnt = userData.bearEntries;

        if (betAmnt > 0) {
            share = (betAmnt * 10_000) / bearAmnt;
        } else {
            share = 0;
        }
    }

    function bullMutiplier(uint256 _roundID) public view returns (uint256) {
        Round storage roundData = rounds[_roundID];
        uint256 bulls = roundData.bullBetsAmount;
        uint256 bears = roundData.bearBetsAmount;
        uint256 multipiler;

        if (bulls > 0 && bears > 0) {
            multipiler = 10_000 + ((bears * 10_000) / bulls);
        } else if (bears > 0 && bulls == 0) {
            multipiler = 10_000 + ((bears * 10_000) / minimumBet);
        } else {
            multipiler = 10_000;
        }

        return multipiler;
    }

    function bearMutiplier(uint256 _roundID) public view returns (uint256) {
        Round storage roundData = rounds[_roundID];
        uint256 bulls = roundData.bullBetsAmount;
        uint256 bears = roundData.bearBetsAmount;
        uint256 multipiler;

        if (bears > 0 && bulls > 0) {
            multipiler = 10_000 + ((bulls * 10_000) / bears);
        } else if (bulls > 0 && bears == 0) {
            multipiler = 10_000 + ((bulls * 10_000) / minimumBet);
        } else {
            multipiler = 10_000;
        }

        return multipiler;
    }

    function rewardBullsClaimableAmntsView(
        address user,
        uint256 _roundID
    ) public view returns (uint256 amountClaimable) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bullShare(user, _roundID);
        uint256 totalEthPot = roundData.totalEthBets;
        bool isClaimable = totalEthPot > 0 &&
            userShare > 0 &&
            roundData.roundClose &&
            roundResult(_roundID);

        amountClaimable = 0;

        if (isClaimable) {
            amountClaimable = (totalEthPot * userShare) / 10_000;
        } else if (
            !roundResult(_roundID) &&
            roundData.bearBetsAmount == 0 &&
            userShare > 0
        ) {
            amountClaimable = userData.bullEntries;
        }
    }

    function rewardBearsClaimableAmntsView(
        address user,
        uint256 _roundID
    ) public view returns (uint256 amountClaimable) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bearShare(user, _roundID);
        uint256 totalEthPot = roundData.totalEthBets;
        bool isClaimable = totalEthPot > 0 &&
            userShare > 0 &&
            roundData.roundClose &&
            !roundResult(_roundID);

        amountClaimable = 0;

        if (isClaimable) {
            amountClaimable = (totalEthPot * userShare) / 10_000;
        } else if (
            roundResult(_roundID) &&
            roundData.bullBetsAmount == 0 &&
            roundData.roundClose &&
            userShare > 0
        ) {
            amountClaimable = userData.bearEntries;
        }
    }

    function rewardBullsClaimableAmnts(
        address user,
        uint256 _roundID
    ) public view returns (uint256 amountClaimable) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bullShare(user, _roundID);
        uint256 totalEthPot = roundData.totalEthBets;
        bool isClaimable = totalEthPot > 0 &&
            userShare > 0 &&
            roundData.roundClose &&
            roundResult(_roundID) &&
            !userData.bullClaimed;

        if (isClaimable) {
            amountClaimable = (totalEthPot * userShare) / 10_000;
        } else if (
            !roundResult(_roundID) &&
            roundData.bearBetsAmount == 0 &&
            userShare > 0 &&
            roundData.roundClose &&
            !userData.bullClaimed
        ) {
            amountClaimable = userData.bullEntries;
        }
    }

    function rewardBearsClaimableAmnts(
        address user,
        uint256 _roundID
    ) public view returns (uint256 amountClaimable) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bearShare(user, _roundID);
        uint256 totalEthPot = roundData.totalEthBets;
        bool isClaimable = totalEthPot > 0 &&
            userShare > 0 &&
            roundData.roundClose &&
            !roundResult(_roundID) &&
            !userData.bearClaimed;

        if (isClaimable) {
            amountClaimable = (totalEthPot * userShare) / 10_000;
        } else if (
            roundResult(_roundID) &&
            roundData.bullBetsAmount == 0 &&
            userShare > 0 &&
            !userData.bearClaimed
        ) {
            amountClaimable = userData.bearEntries;
        }
    }

    function claimBull(
        address user,
        uint256 _roundID
    ) internal returns (uint256 amntClaimed) {
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bullShare(user, _roundID);
        require(userShare > 0, "No claims");
        require(!userData.bullClaimed, "already claimed");
        require(!isEven(_roundID));

        uint256 totalAmntWon = rewardBullsClaimableAmnts(user, _roundID);

        bool success;

        (success, ) = address(user).call{value: totalAmntWon}("");

        userData.totalEthWon += totalAmntWon;
        userData.bullClaimed = true;
        IPredictionFactory(predictionFactory).addEthPayout(totalAmntWon);

        amntClaimed = totalAmntWon;

        emit BullClaimed(user, _roundID, totalAmntWon);
    }

    function claimBear(
        address user,
        uint256 _roundID
    ) internal returns (uint256 amntClaimed) {
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bearShare(user, _roundID);
        require(userShare > 0, "No claims");
        require(!userData.bearClaimed, "already claimed");
        require(!isEven(_roundID));

        uint256 totalAmntWon = rewardBearsClaimableAmnts(user, _roundID);

        bool success;

        (success, ) = address(user).call{value: totalAmntWon}("");

        userData.totalEthWon += totalAmntWon;
        userData.bearClaimed = true;
        IPredictionFactory(predictionFactory).addEthPayout(totalAmntWon);

        amntClaimed = totalAmntWon;

        emit BearClaimed(user, _roundID, totalAmntWon);
    }

    function claimWinnings(address user, uint256 _roundID) public nonReentrant {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userBullShare = bullShare(user, _roundID);
        uint256 userBearShare = bearShare(user, _roundID);

        require(roundData.roundClose, "Round is not closed");
        require(userBullShare > 0 || userBearShare > 0, "Nothing to claim");

        if (roundResult(_roundID) && !isEven(_roundID) && userBullShare > 0) {
            totalEthPayoutsMade += claimBull(user, _roundID);
        } else if (
            !roundResult(_roundID) && !isEven(_roundID) && userBearShare > 0
        ) {
            totalEthPayoutsMade += claimBear(user, _roundID);
        } else if (isEven(_roundID)) {
            if (userBullShare > 0) {
                bool success;
                (success, ) = address(user).call{value: userData.bullEntries}(
                    ""
                );
                totalEthPayoutsMade += userData.bullEntries;
                userData.totalEthWon += userData.bullEntries;
                userData.bullClaimed = true;

                emit BullClaimed(user, _roundID, userData.bullEntries);
            } else if (userBearShare > 0) {
                bool success;
                (success, ) = address(user).call{value: userData.bearEntries}(
                    ""
                );

                totalEthPayoutsMade += userData.bearEntries;
                userData.totalEthWon += userData.bearEntries;
                userData.bearClaimed = true;

                emit BearClaimed(user, _roundID, userData.bullEntries);
            }
        }

        if (
            userBullShare > 0 &&
            roundData.bearBetsAmount == 0 &&
            !roundResult(_roundID) &&
            !userData.bullClaimed
        ) {
            totalEthPayoutsMade += claimBull(user, _roundID);
        }

        if (
            userBearShare > 0 &&
            roundData.bullBetsAmount == 0 &&
            roundResult(_roundID) &&
            !userData.bearClaimed
        ) {
            totalEthPayoutsMade += claimBear(user, _roundID);
        }
    }

    function hasEthLiquidity(address tokenAddress) public view returns (bool) {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = IUniswapV2Router01(router).WETH();

        try IUniswapV2Router01(router).getAmountsOut(0.01 ether, path) returns (
            uint256[] memory amounts
        ) {
            return amounts[1] > 0;
        } catch {
            return false;
        }
    }
}
