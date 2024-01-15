// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IFloorPricePredictionV2.sol";
import "./FloorPricePredictionStorage.sol";

contract FloorPricePredictionV2 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IFloorPricePredictionV2,
    FloorPricePredictionStorageV1
{
    function _onlyAdmin() internal view {
        // NA: Not Admin
        require(msg.sender == adminAddress, "NA");
    }

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    function _whenNotPaused(address market) internal view {
        require(!markets[market].paused, "Pausable: paused");
    }

    modifier notContract() {
        // CNA: contract not allowed
        require(!_isContract(msg.sender), "CNA");
        // PCNA: Proxy contract not allowed
        require(msg.sender == tx.origin, "PCNA");
        _;
    }

    modifier whenNotPaused(address market) {
        _whenNotPaused(market);
        _;
    }

    /**
     * @notice initializer
     * @param params: PredictionParams with initializing params
     */
    function initialize(PredictionParams memory params) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        oracle = INftPriceOracle(params._oracleAddress);
        adminAddress = params._adminAddress;
        minBetAmount = params._minBetAmount;
        treasuryFee = params._treasuryFee;
        referralRewardRatio = params._referralRewardRatio;
        houseBetBase = params._houseBetBase;
        for (uint i = 0; i < params._nftContracts.length; i++) {
            nftsContracts.push(params._nftContracts[i]);
            Market storage m = markets[params._nftContracts[i]];
            m.nftContract = params._nftContracts[i];
            for (uint j = 0; j < params._intervals.length; j++) {
                m.intervals.push(params._intervals[j]);
                Period storage p = m.periods[params._intervals[j].intervalSeconds];
                p.intervalSeconds = params._intervals[j].intervalSeconds;
                p.lockIntervalSeconds = params._intervals[j].lockIntervalSeconds;
                p.genesisTimestamp = params._genesisTimestamp;
            }
        }
    }

    function predict(
        address market,
        uint256 intervalSeconds,
        bool isBear,
        address referrer
    ) public payable whenNotPaused(market) nonReentrant notContract {
        _checkBetRequirements(market, intervalSeconds);
        _handleReferral(referrer);
        _safeBet(market, intervalSeconds, isBear);
    }

    function claim(BetInfo[] memory betInfos) external nonReentrant notContract {
        uint256 reward; // Initializes reward
        for (uint256 i = 0; i < betInfos.length; i++) {
            BetInfo memory info = betInfos[i];
            Period storage p = markets[info.market].periods[info.intervalSeconds];
            Round memory r = p.rounds[info.epoch];
            (, r.lockTimestamp, r.closeTimestamp) = _getEpochTimestamps(
                p.genesisTimestamp,
                p.lockIntervalSeconds,
                p.intervalSeconds,
                info.epoch
            );

            if (block.timestamp < r.closeTimestamp) {
                continue;
            }

            bool lockPriceVerified;
            bool closePriceVerified;
            (lockPriceVerified, r.lockPrice) = oracle.getNftPriceByOracleId(
                info.market,
                info.lockPriceOracleId,
                r.lockTimestamp
            );
            (closePriceVerified, r.closePrice) = oracle.getNftPriceByOracleId(
                info.market,
                info.closePriceOracleId,
                r.closeTimestamp
            );
            // IO: Invalid oracleId
            require(lockPriceVerified && closePriceVerified, "IO");

            Bet storage bet = p.ledger[info.epoch][msg.sender][info.nth];
            if (!_claimable(r, bet)) continue;
            uint256 addedReward;
            bool shouldApplyHouseBet = r.bullAmount == 0 || r.bearAmount == 0;
            if (!shouldApplyHouseBet) {
                addedReward = _calculateRewards(r.bullAmount, r.bearAmount, r.closePrice, r.lockPrice, bet.amount);
            } else {
                uint256 addedRewardsFromHouse = _calculateRewardsFromHouse(
                    info.market,
                    info.intervalSeconds,
                    info.epoch,
                    r,
                    bet
                );
                addedReward = addedRewardsFromHouse + bet.amount;
                houseBetFund -= addedRewardsFromHouse;
            }
            reward += addedReward;
            bet.claimed = true;
            if (!shouldApplyHouseBet) {
                emit Claim(msg.sender, addedReward, info.market, info.intervalSeconds, info.epoch, info.nth);
            } else {
                emit ClaimFromHouse(
                    msg.sender,
                    addedReward,
                    houseBetFund,
                    info.market,
                    info.intervalSeconds,
                    info.epoch,
                    info.nth
                );
            }
        }
        if (reward > 0) {
            _safeTransfer(address(msg.sender), reward);
        }
    }

    function claimReferralRewards() external nonReentrant notContract {
        uint256 reward = _referralFunds[msg.sender];
        if (reward > 0) {
            _referralFunds[msg.sender] = 0;
            _safeTransfer(address(msg.sender), reward);
        }
        emit ClaimReferralRewards(msg.sender, reward);
    }

    /////////////////////
    /// EXTERNAL VIEW ///
    /////////////////////
    /**
     * @notice Get rounds and bets data
     * @param user: pass user address when getting certain user's bets
     * @param market: nft contract address
     * @param intervalSeconds: round interval in seconds
     * @param cursor: cursor for pagination
     * @param size: size
     * @return rounds rounds data
     * @return userRoundBets user's bet in each round
     * @return nextCursor next cursor
     */
    function getRounds(
        address user,
        address market,
        uint256 intervalSeconds,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            Round[] memory rounds,
            Bet[][] memory userRoundBets,
            uint256 nextCursor
        )
    {
        // BGT: Before genesis timestamp
        require(block.timestamp >= markets[market].periods[intervalSeconds].genesisTimestamp, "BGT");

        uint256 _cursor = cursor == 0 ? _getCurrentEpoch(market, intervalSeconds) : cursor;
        uint256 length = size > _cursor ? _cursor : size;
        rounds = new Round[](length);
        userRoundBets = new Bet[][](length);
        for (uint i = 0; i < length; i++) {
            Period storage p = markets[market].periods[intervalSeconds];
            rounds[i] = p.rounds[_cursor - i];
            rounds[i].epoch = _cursor - i;
            (rounds[i].startTimestamp, rounds[i].lockTimestamp, rounds[i].closeTimestamp) = _getEpochTimestamps(
                p.genesisTimestamp,
                p.lockIntervalSeconds,
                p.intervalSeconds,
                rounds[i].epoch
            );
            if (block.timestamp >= rounds[i].lockTimestamp) {
                rounds[i].lockPrice = oracle.getNftPriceByTimestamp(market, rounds[i].lockTimestamp);
            }
            if (block.timestamp >= rounds[i].closeTimestamp) {
                rounds[i].closePrice = oracle.getNftPriceByTimestamp(market, rounds[i].closeTimestamp);
            }
            if (user != address(0)) {
                Bet[] memory _userBets = markets[market].periods[intervalSeconds].ledger[_cursor - i][user];
                userRoundBets[i] = new Bet[](_userBets.length);
                for (uint j = 0; j < _userBets.length; j++) {
                    userRoundBets[i][j] = _userBets[j];
                }
            }
        }
        nextCursor = _cursor - length < 0 ? 0 : _cursor - length;
    }

    function getHouseBetAmount(
        address market,
        uint256 intervalSeconds,
        uint256 epoch
    ) public view returns (uint256 bullAmount, uint256 bearAmount) {
        uint256 encodedNumberBear = uint256(keccak256(abi.encodePacked(market, intervalSeconds, epoch)));
        uint256 encodedNumberBull = uint256(keccak256(abi.encodePacked(intervalSeconds, market, epoch)));
        uint256 slicedBear = encodedNumberBear / 10**62;
        uint256 slicedBull = encodedNumberBull / 10**62;
        bearAmount = houseBetBase + slicedBear;
        bullAmount = houseBetBase + slicedBull;
    }

    //////////////////////////
    /// EXTERNAL FOR ADMIN ///
    //////////////////////////

    /**
     * @notice Claim all rewards in treasury
     * @param houseWinRounds: The round that closePrice is equal to lockPrice. Neither bull wins nor bear wins then house wins.
     * @dev Callable by admin
     */
    function claimTreasury(RoundInfo[] calldata houseWinRounds) external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        for (uint256 i = 0; i < houseWinRounds.length; i++) {
            RoundInfo memory info = houseWinRounds[i];
            Market storage m = markets[info.market];
            Period storage p = m.periods[info.intervalSeconds];
            Round storage r = markets[info.market].periods[info.intervalSeconds].rounds[info.epoch];
            (, r.lockTimestamp, r.closeTimestamp) = _getEpochTimestamps(
                p.genesisTimestamp,
                p.lockIntervalSeconds,
                p.intervalSeconds,
                info.epoch
            );
            if (!r.houseWinClaimed) {
                (bool lockPriceVerified, uint256 lockPrice) = oracle.getNftPriceByOracleId(
                    info.market,
                    info.lockPriceOracleId,
                    r.lockTimestamp
                );
                (bool closePriceVerified, uint256 closePrice) = oracle.getNftPriceByOracleId(
                    info.market,
                    info.closePriceOracleId,
                    r.closeTimestamp
                );
                if (lockPriceVerified && closePriceVerified && (lockPrice == closePrice)) {
                    uint256 totalAmount = r.bullAmount + r.bearAmount;
                    currentTreasuryAmount += (totalAmount * (10000 - treasuryFee)) / 10000;
                }
                r.houseWinClaimed = true;
            }
        }
        _safeTransfer(adminAddress, currentTreasuryAmount);
        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice Set minBetAmount
     * @param _minBetAmount: minimum bet amount
     * @dev Callable by admin
     */

    function setMinBetAmount(uint256 _minBetAmount) external onlyAdmin {
        // BAMS0: minBetAmount must be superior to 0
        require(_minBetAmount != 0, "BAMS0");
        minBetAmount = _minBetAmount;

        emit NewMinBetAmount(minBetAmount);
    }

    /**
     * @notice Set treasury fee
     * @param _treasuryFee: treasury fee rate (e.g. 200 = 2%, 150 = 1.50%)
     * @dev Callable by admin
     */
    function setTreasuryFee(uint256 _treasuryFee) external onlyAdmin {
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(treasuryFee);
    }

    /**
     * @notice Set oracle contract address
     * @param _oracleAddress: oracle contract address
     */
    function setOracleAddress(address _oracleAddress) external onlyAdmin {
        oracle = INftPriceOracle(_oracleAddress);
        emit NewOracle(_oracleAddress);
    }

    /**
     * @notice Set admin address
     * @param _adminAddress:  address of the admin
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external onlyAdmin {
        // CBZA: Cannot be zero address
        require(_adminAddress != address(0), "CBZA");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }

    /**
     * @notice Add nft collection to prediction
     * @param _nftContract: nft contract address
     * @param _intervals: time intervals of new market
     * @param _genesisTimestamp: genesis time of new market
     * @dev Callable by admin
     */
    function addNewMarketOrPeriod(
        address _nftContract,
        Interval[] calldata _intervals,
        uint256 _genesisTimestamp,
        bool newMarket
    ) external onlyAdmin {
        Market storage m = markets[_nftContract];
        if (newMarket) {
            // ME:market existed
            require(!_isExistingMarket(_nftContract), "ME");

            nftsContracts.push(_nftContract);
            m.nftContract = _nftContract;
        }

        for (uint i = 0; i < _intervals.length; i++) {
            // PE: period existed
            require(!_isExistingPeriodInMarket(_nftContract, _intervals[i].intervalSeconds), "PE");

            m.intervals.push(_intervals[i]);
            Period storage p = m.periods[_intervals[i].intervalSeconds];
            p.intervalSeconds = _intervals[i].intervalSeconds;
            p.lockIntervalSeconds = _intervals[i].lockIntervalSeconds;
            p.genesisTimestamp = _genesisTimestamp;
        }

        if (newMarket) {
            emit NewMarket(_nftContract, _intervals, _genesisTimestamp);
        } else {
            emit NewPeriodInMarket(_nftContract, _intervals, _genesisTimestamp);
        }
    }

    /**
     * @notice Pause certain market from betting
     * @param _market: nft contract address
     * @dev Callable by admin
     */
    function pauseMarket(address _market) external onlyAdmin {
        markets[_market].paused = true;
        emit MarketPause(_market);
    }

    /**
     * @notice Unpause certain market to recover betting
     * @param _market: nft contract address
     * @dev Callable by admin
     */
    function unpauseMarket(address _market) external onlyAdmin {
        markets[_market].paused = false;
        emit MarketUnpause(_market);
    }

    function setReferralRewardRatio(uint256 _referralRewardRatio) external onlyAdmin {
        referralRewardRatio = _referralRewardRatio;
    }

    function setHouseBetBase(uint256 _houseBetBase) external onlyAdmin {
        houseBetBase = _houseBetBase;
    }

    function addHouseBetFund() external payable {
        houseBetFund += msg.value;
        emit AddHouseBetFund(msg.value);
    }

    //NEF: not enough fund
    function withdrawHouseBetFund(uint256 amount) external onlyAdmin {
        require(houseBetFund >= amount, "NEF");
        houseBetFund -= amount;
        _safeTransfer(adminAddress, amount);
        emit WithdrawHouseBetFund(amount, adminAddress);
    }

    ////////////////
    /// INTERNAL ///
    ////////////////

    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Check if the given nft address exists in market list
     * @param _market: nft contract address
     * @return bool whether the market exists in market list
     */
    function _isExistingMarket(address _market) internal view returns (bool) {
        return markets[_market].nftContract != address(0);
    }

    function _isExistingPeriodInMarket(address _market, uint256 _intervalSeconds) internal view returns (bool) {
        return markets[_market].periods[_intervalSeconds].intervalSeconds == _intervalSeconds;
    }

    /**
     * @notice Check if the given nft address and intervalSeconds has initialized
     * @param _market: nft contract address
     * @param _intervalSeconds: intervalSeconds
     * @return bool whether the market and interval exists
     */
    function _isValidMarketAndInterval(address _market, uint256 _intervalSeconds) internal view returns (bool) {
        return _isExistingMarket(_market) && markets[_market].periods[_intervalSeconds].intervalSeconds != 0;
    }

    /**
     * @notice Calculate treasury fee of a bet amount
     * @param amount: bet amount
     * @return fee treasury fee amount
     */
    function _calculateFee(uint256 amount) internal view returns (uint256 fee) {
        return (amount * treasuryFee) / 10000;
    }

    /**
     * @notice Calculate reward amount with given bull/bear amount, lock/close price and bet amount
     * @param bullAmount: sum of betting bull amount
     * @param bearAmount: sum of betting bear amount
     * @param closePrice: close price of a round
     * @param lockPrice: lock price of a round
     * @param betAmount: amount of the bet
     * @return uint256 anount of reward
     */
    function _calculateRewards(
        uint256 bullAmount,
        uint256 bearAmount,
        uint256 closePrice,
        uint256 lockPrice,
        uint256 betAmount
    ) internal view returns (uint256) {
        uint256 totalAmount = bullAmount + bearAmount;
        if (closePrice > lockPrice) {
            return (betAmount * totalAmount * (10000 - treasuryFee)) / 10000 / bullAmount;
        }
        return (betAmount * totalAmount * (10000 - treasuryFee)) / 10000 / bearAmount;
    }

    function _calculateRewardsFromHouse(
        address market,
        uint256 intervalSeconds,
        uint256 epoch,
        Round memory r,
        Bet memory bet
    ) internal view returns (uint256 reward) {
        (uint256 houseBullAmount, uint256 houseBearAmount) = getHouseBetAmount(market, intervalSeconds, epoch);
        if ((r.bullAmount == 0 || r.bearAmount == 0) && houseBetFund > 0) {
            uint256 winnings = bet.isBear ? houseBullAmount : houseBearAmount;
            uint256 base = bet.isBear ? r.bearAmount : r.bullAmount;
            uint256 baseFromHouse = bet.isBear ? houseBearAmount : houseBullAmount;
            uint256 expectedReward = (winnings * bet.amount) / (base + baseFromHouse);
            if (expectedReward < houseBetFund) {
                reward = expectedReward;
            } else {
                reward = 0;
            }
        } else {
            reward = 0;
        }
    }

    /**
     * @notice Get current epoch by market and period
     * Current timestamp must be within the epoch
     * @param market: nft contract address
     * @param intervalSeconds: round interval in seconds
     * @return epoch round count
     */
    function _getCurrentEpoch(address market, uint256 intervalSeconds) internal view returns (uint256 epoch) {
        epoch =
            (block.timestamp - markets[market].periods[intervalSeconds].genesisTimestamp) /
            markets[market].periods[intervalSeconds].lockIntervalSeconds +
            1;
    }

    /**
     * @notice Calculate start/lock/close timestamps from given epoch
     * @param genesisTimestamp: nft contract address
     * @param lockIntervalSeconds: lock interval in seconds
     * @param intervalSeconds: time interval in seconds
     * @param epoch: round count
     * @return startTimestamp start time of the epoch
     * @return lockTimestamp lock time of the epoch
     * @return closeTimestamp close time of the epoch
     */
    function _getEpochTimestamps(
        uint256 genesisTimestamp,
        uint256 lockIntervalSeconds,
        uint256 intervalSeconds,
        uint256 epoch
    )
        internal
        pure
        returns (
            uint256 startTimestamp,
            uint256 lockTimestamp,
            uint256 closeTimestamp
        )
    {
        startTimestamp = genesisTimestamp + ((epoch - 1) * lockIntervalSeconds);
        lockTimestamp = genesisTimestamp + (epoch * lockIntervalSeconds);
        closeTimestamp = genesisTimestamp + (epoch * lockIntervalSeconds) + intervalSeconds;
    }

    /**
     * @notice Get the claimable stats of specific round and user bet
     * @param round: round data
     * @param bet: bet data
     */
    function _claimable(Round memory round, Bet memory bet) internal pure returns (bool) {
        if (round.lockPrice == round.closePrice || bet.claimed == true) {
            return false;
        }
        return
            bet.amount != 0 &&
            ((round.closePrice > round.lockPrice && bet.isBear == false) ||
                (round.closePrice < round.lockPrice && bet.isBear == true));
    }

    /**
     * @notice Transfer ether in a safe way
     * @param to: address to transfer ether to
     * @param value: ether amount to transfer (in wei)
     */
    function _safeTransfer(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }("");
        // STF: TransferHelper: safe transfer failed
        require(success, "STF");
    }

    function _safeBet(
        address market,
        uint256 intervalSeconds,
        bool isBear
    ) internal {
        uint256 epoch = _getCurrentEpoch(market, intervalSeconds);
        Period storage p = markets[market].periods[intervalSeconds];
        if (isBear) {
            p.rounds[epoch].bearAmount += msg.value;
        } else {
            p.rounds[epoch].bullAmount += msg.value;
        }

        Bet memory bet;
        bet.isBear = isBear;
        bet.amount = msg.value;
        p.ledger[epoch][msg.sender].push(bet);

        treasuryAmount += _calculateFee(msg.value);

        emit NewBet(
            msg.sender,
            msg.value,
            market,
            intervalSeconds,
            p.lockIntervalSeconds,
            epoch,
            p.genesisTimestamp + (epoch * p.lockIntervalSeconds),
            p.genesisTimestamp + (epoch * p.lockIntervalSeconds) + intervalSeconds,
            isBear,
            p.ledger[epoch][msg.sender].length - 1
        );
    }

    function _checkBetRequirements(address market, uint256 intervalSeconds) internal {
        // BMG: Bet amount must be greater than minBetAmount
        require(msg.value >= minBetAmount, "BMG");
        // IVMI: Invalid market and interval
        require(_isValidMarketAndInterval(market, intervalSeconds), "IVMI");
        // BGT: Before genesis timestamp
        require(block.timestamp >= markets[market].periods[intervalSeconds].genesisTimestamp, "BGT");
    }

    function _handleReferral(address _referrer) internal {
        if (_referrers[msg.sender] != address(0)) {
            // already have referrer
            address referrer = _referrers[msg.sender];
            uint256 reward = (msg.value * referralRewardRatio) / 1000;
            _referralFunds[referrer] += reward;
            emit Referral(msg.sender, referrer, reward, false);
        } else if (_referrer != address(0)) {
            // no referrer record
            if (_referrers[_referrer] == msg.sender || _referrer == msg.sender) return;
            _referrers[msg.sender] = _referrer;
            uint256 reward = (msg.value * referralRewardRatio) / 1000;
            _referralFunds[_referrer] += reward;
            emit Referral(msg.sender, _referrer, reward, true);
        }
    }
}
