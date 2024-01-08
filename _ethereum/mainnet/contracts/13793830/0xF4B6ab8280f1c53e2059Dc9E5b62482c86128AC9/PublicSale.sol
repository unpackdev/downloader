// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ILockTOS.sol";
import "./IPublicSale.sol";
import "./IWTON.sol";
import "./AccessibleCommon.sol";
import "./PublicSaleStorage.sol";

contract PublicSale is
    PublicSaleStorage,
    AccessibleCommon,
    ReentrancyGuard,
    IPublicSale
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event AddedWhiteList(address indexed from, uint256 tier);
    event ExclusiveSaled(address indexed from, uint256 amount);
    event Deposited(address indexed from, uint256 amount);

    event Claimed(address indexed from, uint256 amount);
    event Withdrawal(address indexed from, uint256 amount);
    event DepositWithdrawal(address indexed from, uint256 amount);

    modifier nonZero(uint256 _value) {
        require(_value > 0, "PublicSale: zero");
        _;
    }

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "PublicSale: zero address");
        _;
    }

    modifier beforeStartAddWhiteTime() {
        require(
            startAddWhiteTime == 0 ||
                (startAddWhiteTime > 0 && block.timestamp < startAddWhiteTime),
            "PublicSale: not beforeStartAddWhiteTime"
        );
        _;
    }

    modifier beforeEndAddWhiteTime() {
        require(
            endAddWhiteTime == 0 ||
                (endAddWhiteTime > 0 && block.timestamp < endAddWhiteTime),
            "PublicSale: not beforeEndAddWhiteTime"
        );
        _;
    }

    modifier greaterThan(uint256 _value1, uint256 _value2) {
        require(_value1 > _value2, "PublicSale: non greaterThan");
        _;
    }

    modifier lessThan(uint256 _value1, uint256 _value2) {
        require(_value1 < _value2, "PublicSale: non less than");
        _;
    }

    /// @inheritdoc IPublicSale
    function changeTONOwner(address _address) external override onlyOwner {
        getTokenOwner = _address;
    }

    /// @inheritdoc IPublicSale
    function setAllValue(
        uint256 _snapshot,
        uint256[4] calldata _exclusiveTime,
        uint256[2] calldata _openSaleTime,
        uint256[4] calldata _claimTime
    ) external override onlyOwner beforeStartAddWhiteTime {
        require(
            (_exclusiveTime[0] < _exclusiveTime[1]) &&
                (_exclusiveTime[2] < _exclusiveTime[3])
        );
        require(
            (_openSaleTime[0] < _openSaleTime[1])
        );
        setSnapshot(_snapshot);
        setExclusiveTime(
            _exclusiveTime[0],
            _exclusiveTime[1],
            _exclusiveTime[2],
            _exclusiveTime[3]
        );
        setOpenTime(
            _openSaleTime[0],
            _openSaleTime[1]
        );
        setClaim(
            _claimTime[0],
            _claimTime[1],
            _claimTime[2],
            _claimTime[3]
        );
    }

    /// @inheritdoc IPublicSale
    function setSnapshot(uint256 _snapshot)
        public
        override
        onlyOwner
        nonZero(_snapshot)
    {
        snapshot = _snapshot;
    }

    /// @inheritdoc IPublicSale
    function setExclusiveTime(
        uint256 _startAddWhiteTime,
        uint256 _endAddWhiteTime,
        uint256 _startExclusiveTime,
        uint256 _endExclusiveTime
    )
        public
        override
        onlyOwner
        nonZero(_startAddWhiteTime)
        nonZero(_endAddWhiteTime)
        nonZero(_startExclusiveTime)
        nonZero(_endExclusiveTime)
        beforeStartAddWhiteTime
    {
        startAddWhiteTime = _startAddWhiteTime;
        endAddWhiteTime = _endAddWhiteTime;
        startExclusiveTime = _startExclusiveTime;
        endExclusiveTime = _endExclusiveTime;
    }

    /// @inheritdoc IPublicSale
    function setOpenTime(
        uint256 _startDepositTime,
        uint256 _endDepositTime
    )
        public
        override
        onlyOwner
        nonZero(_startDepositTime)
        nonZero(_endDepositTime)
        beforeStartAddWhiteTime
    {
        startDepositTime = _startDepositTime;
        endDepositTime = _endDepositTime;
    }

    /// @inheritdoc IPublicSale
    function setClaim(
        uint256 _startClaimTime,
        uint256 _claimInterval,
        uint256 _claimPeriod,
        uint256 _claimFirst
    )
        public
        override
        onlyOwner
        nonZero(_startClaimTime)
        nonZero(_claimInterval)
        nonZero(_claimPeriod)
        beforeStartAddWhiteTime
    {
        startClaimTime = _startClaimTime;
        claimInterval = _claimInterval;
        claimPeriod = _claimPeriod;
        claimFirst = _claimFirst;
    }

    /// @inheritdoc IPublicSale
    function setAllTier(
        uint256[4] calldata _tier,
        uint256[4] calldata _tierPercent
    ) external override onlyOwner {
        setTier(
            _tier[0],
            _tier[1],
            _tier[2],
            _tier[3]
        );
        setTierPercents(
            _tierPercent[0],
            _tierPercent[1],
            _tierPercent[2],
            _tierPercent[3]
        );
    }

    /// @inheritdoc IPublicSale
    function setTier(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    )
        public
        override
        onlyOwner
        nonZero(_tier1)
        nonZero(_tier2)
        nonZero(_tier3)
        nonZero(_tier4)
        beforeStartAddWhiteTime
    {
        tiers[1] = _tier1;
        tiers[2] = _tier2;
        tiers[3] = _tier3;
        tiers[4] = _tier4;
    }

    /// @inheritdoc IPublicSale
    function setTierPercents(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    )
        public
        override
        onlyOwner
        nonZero(_tier1)
        nonZero(_tier2)
        nonZero(_tier3)
        nonZero(_tier4)
        beforeStartAddWhiteTime
    {
        require(
            _tier1.add(_tier2).add(_tier3).add(_tier4) == 10000,
            "PublicSale: Sum should be 10000"
        );
        tiersPercents[1] = _tier1;
        tiersPercents[2] = _tier2;
        tiersPercents[3] = _tier3;
        tiersPercents[4] = _tier4;
    }

    /// @inheritdoc IPublicSale
    function setAllAmount(
        uint256[2] calldata _expectAmount,
        uint256[2] calldata _priceAmount
    ) external override onlyOwner {
        setSaleAmount(
            _expectAmount[0],
            _expectAmount[1]
        );
        setTokenPrice(
            _priceAmount[0],
            _priceAmount[1]
        );
    }

    /// @inheritdoc IPublicSale
    function setSaleAmount(
        uint256 _totalExpectSaleAmount,
        uint256 _totalExpectOpenSaleAmount
    )
        public
        override
        onlyOwner
        nonZero(_totalExpectSaleAmount.add(_totalExpectOpenSaleAmount))
        beforeStartAddWhiteTime
    {
        totalExpectSaleAmount = _totalExpectSaleAmount;
        totalExpectOpenSaleAmount = _totalExpectOpenSaleAmount;
    }

    /// @inheritdoc IPublicSale
    function setTokenPrice(uint256 _saleTokenPrice, uint256 _payTokenPrice)
        public
        override
        onlyOwner
        nonZero(_saleTokenPrice)
        nonZero(_payTokenPrice)
        beforeStartAddWhiteTime
    {
        saleTokenPrice = _saleTokenPrice;
        payTokenPrice = _payTokenPrice;
    }

    /// @inheritdoc IPublicSale
    function totalExpectOpenSaleAmountView() public view override returns(uint256){
        if(block.timestamp < endExclusiveTime) return totalExpectOpenSaleAmount;
        else return totalExpectOpenSaleAmount.add(totalRound1NonSaleAmount());
    }

    /// @inheritdoc IPublicSale
    function totalRound1NonSaleAmount() public view override returns(uint256){
        return totalExpectSaleAmount.sub(totalExSaleAmount);
    }


    function _toRAY(uint256 v) internal pure returns (uint256) {
        return v * 10 ** 9;
    }

    /// @inheritdoc IPublicSale
    function calculSaleToken(uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 tokenSaleAmount =
            _amount.mul(payTokenPrice).div(saleTokenPrice);
        return tokenSaleAmount;
    }

    /// @inheritdoc IPublicSale
    function calculPayToken(uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 tokenPayAmount = _amount.mul(saleTokenPrice).div(payTokenPrice);
        return tokenPayAmount;
    }

    /// @inheritdoc IPublicSale
    function calculTier(address _address)
        public
        view
        override
        nonZeroAddress(address(sTOS))
        nonZero(tiers[1])
        nonZero(tiers[2])
        nonZero(tiers[3])
        nonZero(tiers[4])
        returns (uint256)
    {
        uint256 sTOSBalance = sTOS.balanceOfAt(_address, snapshot);
        uint256 tier;
        if (sTOSBalance >= tiers[1] && sTOSBalance < tiers[2]) {
            tier = 1;
        } else if (sTOSBalance >= tiers[2] && sTOSBalance < tiers[3]) {
            tier = 2;
        } else if (sTOSBalance >= tiers[3] && sTOSBalance < tiers[4]) {
            tier = 3;
        } else if (sTOSBalance >= tiers[4]) {
            tier = 4;
        } else if (sTOSBalance < tiers[1]) {
            tier = 0;
        }
        return tier;
    }

    /// @inheritdoc IPublicSale
    function calculTierAmount(address _address)
        public
        view
        override
        returns (uint256)
    {
        UserInfoEx storage userEx = usersEx[_address];
        uint256 tier = calculTier(_address);
        if (userEx.join == true && tier > 0) {
            uint256 salePossible =
                totalExpectSaleAmount
                    .mul(tiersPercents[tier])
                    .div(tiersAccount[tier])
                    .div(10000);
            return salePossible;
        } else if (tier > 0) {
            uint256 tierAccount = tiersAccount[tier].add(1);
            uint256 salePossible =
                totalExpectSaleAmount
                    .mul(tiersPercents[tier])
                    .div(tierAccount)
                    .div(10000);
            return salePossible;
        } else {
            return 0;
        }
    }

    /// @inheritdoc IPublicSale
    function calculOpenSaleAmount(address _account, uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        UserInfoOpen storage userOpen = usersOpen[_account];
        uint256 depositAmount = userOpen.depositAmount.add(_amount);
        uint256 openSalePossible =
            totalExpectOpenSaleAmountView().mul(depositAmount).div(
                totalDepositAmount.add(_amount)
            );
        return openSalePossible;
    }

    /// @inheritdoc IPublicSale
    function calculClaimAmount(address _account, uint256 _period)
        public
        view
        override
        returns (uint256 _reward, uint256 _totalClaim)
    {
        if(block.timestamp < startClaimTime) return (0, 0);
        if(_period > claimPeriod) return (0,0);

        UserClaim storage userClaim = usersClaim[_account];
        (, uint256 realSaleAmount, ) = totalSaleUserAmount(_account);

        if (realSaleAmount == 0 ) return (0, 0);
        if (userClaim.claimAmount >= realSaleAmount) return (0, realSaleAmount);

        uint256 difftime = block.timestamp.sub(startClaimTime);
        uint256 totalClaimReward = realSaleAmount;
        uint256 firstReward = totalClaimReward.mul(claimFirst).div(100);
        uint256 periodReward = (totalClaimReward.sub(firstReward)).div(claimPeriod.sub(1));

        if(_period == 0) {
            if (difftime < claimInterval) {
                uint256 reward = firstReward.sub(userClaim.claimAmount);
                return (reward, totalClaimReward);
            } else {
                uint256 period = (difftime / claimInterval).add(1);
                if (period >= claimPeriod) {
                    uint256 reward =
                        totalClaimReward.sub(userClaim.claimAmount);
                    return (reward, totalClaimReward);
                } else {
                    uint256 reward = firstReward.add(periodReward.mul(period.sub(1))).sub(userClaim.claimAmount);
                    return (reward, totalClaimReward);
                }
            }
        } else if(_period == 1){
            return (firstReward, totalClaimReward);
        } else {
            if(_period == claimPeriod) {
                uint256 reward =
                    totalClaimReward.sub((firstReward.add(periodReward.mul(claimPeriod.sub(2)))));
                return (reward, totalClaimReward);
            } else {
                return (periodReward, totalClaimReward);
            }
        }
    }

    /// @inheritdoc IPublicSale
    function totalSaleUserAmount(address user) public override view returns (uint256 _realPayAmount, uint256 _realSaleAmount, uint256 _refundAmount) {
        UserInfoEx storage userEx = usersEx[user];

        if(userEx.join){
            (uint256 realPayAmount, uint256 realSaleAmount, uint256 refundAmount) = openSaleUserAmount(user);
            return ( realPayAmount.add(userEx.payAmount), realSaleAmount.add(userEx.saleAmount), refundAmount);
        }else {
            return openSaleUserAmount(user);
        }
    }

    /// @inheritdoc IPublicSale
    function openSaleUserAmount(address user) public override view returns (uint256 _realPayAmount, uint256 _realSaleAmount, uint256 _refundAmount) {
        UserInfoOpen storage userOpen = usersOpen[user];

        if(!userOpen.join || userOpen.depositAmount == 0) return (0, 0, 0);

        uint256 openSalePossible = calculOpenSaleAmount(user, 0);
        uint256 realPayAmount = calculPayToken(openSalePossible);
        uint256 depositAmount = userOpen.depositAmount;
        uint256 realSaleAmount = 0;
        uint256 returnAmount = 0;

        if (realPayAmount < depositAmount) {
           returnAmount = depositAmount.sub(realPayAmount);
           realSaleAmount = calculSaleToken(realPayAmount);
        } else {
            realPayAmount = userOpen.depositAmount;
            realSaleAmount = calculSaleToken(depositAmount);
        }

        return (realPayAmount, realSaleAmount, returnAmount);
    }
    
    /// @inheritdoc IPublicSale
    function totalOpenSaleAmount() public override view returns (uint256){
        uint256 _calculSaleToken = calculSaleToken(totalDepositAmount);
        uint256 _totalAmount = totalExpectOpenSaleAmountView();

        if(_calculSaleToken < _totalAmount) return _calculSaleToken;
        else return _totalAmount;
    }

    /// @inheritdoc IPublicSale
    function totalOpenPurchasedAmount() public override view returns (uint256){
        uint256 _calculSaleToken = calculSaleToken(totalDepositAmount);
        uint256 _totalAmount = totalExpectOpenSaleAmountView();
        if(_calculSaleToken < _totalAmount) return totalDepositAmount;
        else return  calculPayToken(_totalAmount);
    }

    /// @inheritdoc IPublicSale
    function addWhiteList() external override nonReentrant {
        require(
            block.timestamp >= startAddWhiteTime,
            "PublicSale: whitelistStartTime has not passed"
        );
        require(
            block.timestamp < endAddWhiteTime,
            "PublicSale: end the whitelistTime"
        );
        uint256 tier = calculTier(msg.sender);
        require(tier >= 1, "PublicSale: need to more sTOS");
        UserInfoEx storage userEx = usersEx[msg.sender];
        require(userEx.join != true, "PublicSale: already attended");

        whitelists.push(msg.sender);
        totalWhitelists = totalWhitelists.add(1);

        userEx.join = true;
        userEx.tier = tier;
        userEx.saleAmount = 0;
        tiersAccount[tier] = tiersAccount[tier].add(1);

        emit AddedWhiteList(msg.sender, tier);
    }

    /// @inheritdoc IPublicSale
    function exclusiveSale(uint256 _amount)
        external
        override
        nonZero(_amount)
        nonZero(claimPeriod)
        nonReentrant
    {
        require(
            block.timestamp >= startExclusiveTime,
            "PublicSale: exclusiveStartTime has not passed"
        );
        require(
            block.timestamp < endExclusiveTime,
            "PublicSale: end the exclusiveTime"
        );
        UserInfoEx storage userEx = usersEx[msg.sender];
        require(userEx.join == true, "PublicSale: not registered in whitelist");
        uint256 tokenSaleAmount = calculSaleToken(_amount);
        uint256 salePossible = calculTierAmount(msg.sender);

        require(
            salePossible >= userEx.saleAmount.add(tokenSaleAmount),
            "PublicSale: just buy tier's allocated amount"
        );

        if(userEx.payAmount == 0) {
            totalRound1Users = totalRound1Users.add(1);
            totalUsers = totalUsers.add(1);
        }

        userEx.payAmount = userEx.payAmount.add(_amount);
        userEx.saleAmount = userEx.saleAmount.add(tokenSaleAmount);

        totalExPurchasedAmount = totalExPurchasedAmount.add(_amount);
        totalExSaleAmount = totalExSaleAmount.add(tokenSaleAmount);

        uint256 tier = calculTier(msg.sender);
        tiersExAccount[tier] = tiersExAccount[tier].add(1);
        
        uint256 tonAllowance = getToken.allowance(msg.sender, address(this));
        uint256 tonBalance = getToken.balanceOf(msg.sender);
        if(tonAllowance < _amount) {
            uint256 needUserWton;
            uint256 needWton = _amount.sub(tonAllowance);
            needUserWton = _toRAY(needWton);
            require(IWTON(wton).allowance(msg.sender, address(this)) >= needUserWton, "PublicSale: wton amount exceeds allowance");
            require(IWTON(wton).balanceOf(msg.sender) >= needUserWton, "need more wton");
            IERC20(wton).safeTransferFrom(msg.sender,address(this),needUserWton);
            IWTON(wton).swapToTON(needUserWton);
            require(tonAllowance >= _amount.sub(needWton), "PublicSale: ton amount exceeds allowance");
            if(_amount.sub(needWton) > 0) {
                getToken.safeTransferFrom(msg.sender, address(this), _amount.sub(needWton));   
            }
            getToken.safeTransfer(getTokenOwner, _amount);
        } else {
            require(tonAllowance >= _amount && tonBalance >= _amount, "PublicSale: ton amount exceeds allowance");

            getToken.safeTransferFrom(msg.sender, address(this), _amount);
            getToken.safeTransfer(getTokenOwner, _amount);
        }

        emit ExclusiveSaled(msg.sender, _amount);
    }

    /// @inheritdoc IPublicSale
    function deposit(uint256 _amount) external override nonReentrant {
        require(
            block.timestamp >= startDepositTime,
            "PublicSale: don't start depositTime"
        );
        require(
            block.timestamp < endDepositTime,
            "PublicSale: end the depositTime"
        );

        UserInfoOpen storage userOpen = usersOpen[msg.sender];

        if (!userOpen.join) {
            depositors.push(msg.sender);
            userOpen.join = true;

            totalRound2Users = totalRound2Users.add(1);
            UserInfoEx storage userEx = usersEx[msg.sender];
            if(userEx.payAmount == 0) totalUsers = totalUsers.add(1);
        }
        userOpen.depositAmount = userOpen.depositAmount.add(_amount);
        userOpen.saleAmount = 0;
        totalDepositAmount = totalDepositAmount.add(_amount);

        uint256 tonAllowance = getToken.allowance(msg.sender, address(this));
        uint256 tonBalance = getToken.balanceOf(msg.sender);
        if(tonAllowance < _amount) {
            uint256 needUserWton;
            uint256 needWton = _amount.sub(tonAllowance);
            needUserWton = _toRAY(needWton);
            require(IWTON(wton).allowance(msg.sender, address(this)) >= needUserWton, "PublicSale: wton amount exceeds allowance");
            require(IWTON(wton).balanceOf(msg.sender) >= needUserWton, "need more wton");
            IERC20(wton).safeTransferFrom(msg.sender,address(this),needUserWton);
            IWTON(wton).swapToTON(needUserWton);
            require(tonAllowance >= _amount.sub(needWton), "PublicSale: ton amount exceeds allowance");
            if(_amount.sub(needWton) > 0) {
                getToken.safeTransferFrom(msg.sender, address(this), _amount.sub(needWton));   
            }
        } else {
            require(tonAllowance >= _amount && tonBalance >= _amount, "PublicSale: ton amount exceeds allowance");

            getToken.safeTransferFrom(msg.sender, address(this), _amount);
        }


        emit Deposited(msg.sender, _amount);
    }

    /// @inheritdoc IPublicSale
    function claim() external override {
        require(
            block.timestamp >= startClaimTime,
            "PublicSale: don't start claimTime"
        );
        UserClaim storage userClaim = usersClaim[msg.sender];
        UserInfoOpen storage userOpen = usersOpen[msg.sender];

        (, uint256 realSaleAmount, ) = totalSaleUserAmount(msg.sender);
        (, ,uint256 refundAmount ) = openSaleUserAmount(msg.sender);

        require(
            realSaleAmount > 0,
            "PublicSale: no purchase amount"
        );

        (uint256 reward, ) = calculClaimAmount(msg.sender, 0);
        require(reward > 0, "PublicSale: no reward");
        require(
            realSaleAmount.sub(userClaim.claimAmount) >= reward,
            "PublicSale: user is already getAllreward"
        );
        require(
            saleToken.balanceOf(address(this)) >= reward,
            "PublicSale: dont have saleToken in pool"
        );

        userClaim.claimAmount = userClaim.claimAmount.add(reward);

        saleToken.safeTransfer(msg.sender, reward);

        if(!userClaim.exec && userOpen.join) {
            totalRound2UsersClaim = totalRound2UsersClaim.add(1);
            userClaim.exec = true;
        }

        if(refundAmount > 0 && userClaim.refundAmount == 0){
            require(refundAmount <= getToken.balanceOf(address(this)), "PublicSale: dont have refund ton");
            userClaim.refundAmount = refundAmount;
            getToken.safeTransfer(msg.sender, refundAmount);
        }

        emit Claimed(msg.sender, reward);
    }
    
    /// @inheritdoc IPublicSale
    function depositWithdraw() external override onlyOwner {
        require(block.timestamp > endDepositTime,"PublicSale: need to end the depositTime");
        uint256 getAmount;
        if(totalRound2Users == totalRound2UsersClaim){
            getAmount = getToken.balanceOf(address(this));
        } else {
            getAmount = totalOpenPurchasedAmount().sub(10 ether);
        }
        require(getAmount <= getToken.balanceOf(address(this)), "PublicSale: no token to receive");
        getToken.safeTransfer(getTokenOwner, getAmount);
        emit DepositWithdrawal(msg.sender, getAmount);
    }

    /// @inheritdoc IPublicSale
    function withdraw() external override onlyOwner{
        if(block.timestamp <= endDepositTime){
            uint256 balance = saleToken.balanceOf(address(this));
            require(balance > totalExpectSaleAmount.add(totalExpectOpenSaleAmount), "PublicSale: no withdrawable amount");
            uint256 withdrawAmount = balance.sub(totalExpectSaleAmount.add(totalExpectOpenSaleAmount));
            require(withdrawAmount != 0, "PublicSale: don't exist withdrawAmount");
            saleToken.safeTransfer(msg.sender, withdrawAmount);
            emit Withdrawal(msg.sender, withdrawAmount);
        } else {
            require(block.timestamp > endDepositTime, "PublicSale: end the openSaleTime");
            require(!adminWithdraw, "already admin called withdraw");
            adminWithdraw = true;
            uint256 saleAmount = totalOpenSaleAmount();
            require(totalExpectSaleAmount.add(totalExpectOpenSaleAmount) > totalExSaleAmount.add(saleAmount), "PublicSale: don't exist withdrawAmount");

            uint256 withdrawAmount = totalExpectSaleAmount.add(totalExpectOpenSaleAmount).sub(totalExSaleAmount).sub(saleAmount);

            require(withdrawAmount != 0, "PublicSale: don't exist withdrawAmount");
            saleToken.safeTransfer(msg.sender, withdrawAmount);
            emit Withdrawal(msg.sender, withdrawAmount);
        }
    }
}