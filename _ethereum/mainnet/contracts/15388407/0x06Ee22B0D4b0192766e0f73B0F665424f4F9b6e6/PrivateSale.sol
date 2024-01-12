// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IWTON.sol";
import "./IPrivateSale.sol";
import "./ProxyAccessCommon.sol";

import "./OnApprove.sol";
import "./PrivateSaleStorage.sol";


contract PrivateSale is 
    PrivateSaleStorage, 
    ProxyAccessCommon, 
    ReentrancyGuard, 
    OnApprove, 
    IPrivateSale 
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event Buyinfo(
        address user,
        uint256 inputAmount,
        uint256 totalOutPutamount,
        uint256 inputTime
    );

    event Claiminfo(
        address user,
        uint256 claimAmount
    );

    event Withdrawinfo(
        address user,
        uint256 withdrawAmount
    );

    event AddList(
        address account,
        uint256 amount
    );

    event DelList(
        address account,
        uint256 amount
    );

    modifier settingCheck() {
        require(!pauseSetting || isProxyAdmin(msg.sender), "setting is Pause");
        _;
    }

    /* ========== onlyPolicyOwner ========== */
    /// @dev Set pause state
    /// @param _pause true:pause or false:resume
    function setSettingPause(bool _pause) external onlyProxyOwner {
        pauseSetting = _pause;
    }

    /* ========== onlyOwner ========== */

    /// @dev address setting
    /// @param _saleToken saleTokenAddress (contract have token)
    /// @param _getToken getTokenAddress (TON)
    /// @param _ownerToken get TON transfer to wallet
    function addressSetting(
        address _saleToken,
        address _getToken,
        address _ownerToken
    ) 
        external 
        override 
        onlyOwner 
        settingCheck
    {
        changeTokenAddress(_saleToken,_getToken);
        changeGetAddress(_ownerToken);
    }

    function changeWTONAddress(address _wton) 
        external 
        override 
        onlyOwner
        settingCheck 
    {
        wton = _wton;
    }

    function changeTokenAddress(address _saleToken, address _getToken) 
        public 
        override 
        onlyOwner
        settingCheck 
    {
        saleToken = IERC20(_saleToken);
        getToken = IERC20(_getToken);
    }

    function changeGetAddress(address _address) 
        public 
        override 
        onlyOwner 
        settingCheck
    {
        getTokenOwner = _address;
    }

    /**
     * @notice AllsettingFunction
     * @param  _saleTime _saleTime[0] = SalestartTime, _saleTime[1] = SaleEndTime
     * @param  _tokenPrice _tokenPrice[0] = saleTokenPrice, _tokenPrice[1] = TONTokenPrice
     * @param  _claimCounts claimTotalCounts
     * @param  _claimTimes _claimTimeArray
     * @param  _claimPercents claimPercents
     */
    function setAllsetting(
        uint256[2] calldata _saleTime,
        uint256[2] calldata _tokenPrice,
        uint16 _claimCounts,
        uint256[] calldata _claimTimes,
        uint32[] calldata _claimPercents
    ) 
        external
        override 
        onlyOwner
        settingCheck 
    {
        settingSaleTime(
            _saleTime[0],
            _saleTime[1]
        );
        setTokenPrice(
            _tokenPrice[0],
            _tokenPrice[1]
        );
        setClaimArray(
            _claimCounts,
            _claimTimes,
            _claimPercents
        );
    }

    function settingSaleTime(
        uint256 _startTime,
        uint256 _endTime
    )
        public 
        override 
        onlyOwner 
        settingCheck
    {
        saleStartTime = _startTime;
        saleEndTime = _endTime;
    }

    function setTokenPrice(uint256 _saleTokenPrice, uint256 _getTokenPrice)
        public
        override
        onlyOwner
        settingCheck
    {
        saleTokenPrice = _saleTokenPrice;
        getTokenPrice = _getTokenPrice;
    }

    function setClaimArray(
        uint16 _claimCounts,
        uint256[] calldata _claimTimes,
        uint32[] calldata _claimPercents
    ) 
        public
        override
        onlyOwner
        settingCheck 
    {
        if(totalClaimCounts != 0) {
            delete claimTimes;
            delete claimPercents;
        }

        totalClaimCounts = _claimCounts;
        uint256 i = 0;
        uint32 y = 0;
        for (i = 0; i < _claimCounts; i++) {
            claimTimes.push(_claimTimes[i]);
            if (i != 0){
                require(claimTimes[i-1] < claimTimes[i], "PublicSale: claimtime err");
            }
            claimPercents.push(_claimPercents[i]);
            y = y + _claimPercents[i];
        }

        require(y == 10000, "claimPercents err");
    }

    function addWhiteList(address _account,uint256 _amount) external override onlyOwner {
        WhiteList storage userwhite = usersWhite[_account];
        userwhite.amount = userwhite.amount.add(_amount);

        emit AddList(_account, _amount);
    }

    function addWhiteListArray(address[] calldata _account, uint256[] calldata _amount) external override onlyOwner {
        for(uint i = 0; i < _account.length; i++) {
            WhiteList storage userwhite = usersWhite[_account[i]];
            userwhite.amount = userwhite.amount.add(_amount[i]);

            emit AddList(_account[i], _amount[i]);
        }
    }

    function delWhiteList(address _account, uint256 _amount) external override onlyOwner {
        WhiteList storage userwhite = usersWhite[_account];
        userwhite.amount = userwhite.amount.sub(_amount);

        emit DelList(_account, _amount);
    }

    /* ========== VIEW ========== */

    /// @dev calculator the SaleAmount(input TON how many get the anotherToken)
    /// @param _amount input the TON amount
    function calculSaleToken(uint256 _amount)
        public
        override
        view
        returns (uint256)
    {
        uint256 tokenSaleAmount = _amount.mul(getTokenPrice).div(saleTokenPrice);
        return tokenSaleAmount;
    }

    /// @dev calculator the getAmount(want to get _amount how many input the TON?)
    /// @param _amount input the anotherTokenAmount
    function calculGetToken(uint256 _amount)
        public
        override
        view
        returns (uint256)
    {
        uint256 tokenGetAmount = _amount.mul(saleTokenPrice).div(getTokenPrice);
        return tokenGetAmount;
    }

    function currentRound() public view returns (uint16 round) {
        if (block.timestamp > claimTimes[totalClaimCounts-1]) {
            return totalClaimCounts;
        }
        for (uint16 i = 0; i < totalClaimCounts; i++) {
            if (block.timestamp < claimTimes[i]) {
                return i;
            }
        }
    }

    function calculClaimAmount(address _account, uint16 _round)
        public
        view
        returns (uint256 _amount)
    {
        if (block.timestamp < claimTimes[0]) return 0;

        UserInfoAmount memory user = usersAmount[_account];
        if(user.inputamount == 0) return 0;

        if (totalClaimCounts == _round ) {
            return user.totaloutputamount.sub(user.getAmount);
        }

        uint256 roundClaimPercent;
        for (uint16 i = 0; i < _round; i++) {
            roundClaimPercent = roundClaimPercent.add(claimPercents[i]);
        }
        
        uint256 userGetAmount = (user.totaloutputamount.mul(roundClaimPercent).div(10000)).sub(user.getAmount);
        return userGetAmount;
    }

    function saleTokenAddress() public view returns (address) {
        return address(saleToken);
    }

    /**
     * @dev transform WAD to RAY
     */
    function _toRAY(uint256 v) internal pure returns (uint256) {
        return v * 10 ** 9;
    }

    /**
     * @dev transform RAY to WAD
     */
    function _toWAD(uint256 v) public override pure returns (uint256) {
        return v / 10 ** 9;
    }

    function decodeApproveData(
        bytes memory data
    ) public override pure returns (uint256 approveData) {
        assembly {
            approveData := mload(add(data, 0x20))
        }
    }

    function decodeAddressData(
        bytes memory data
    ) public override pure returns (address claimAddress_) {
        require(data.length == 0x20);

        assembly {
            claimAddress_ := mload(add(data, 0x20))
        }
    }

    function encodeAddressData(
        address _claimAddress
    ) external override pure returns (bytes memory data) {
        data = new bytes(0x20);

        assembly {
            mstore(add(data, 0x20), _claimAddress)
        }
    }

    /* ========== Anyone can execute ========== */

    function onApprove(
        address sender,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(msg.sender == address(getToken) || msg.sender == address(IWTON(wton)), "PrivateSale: only accept TON and WTON approve callback");
        
        address claimAddress = decodeAddressData(data);
        
        if(msg.sender == address(getToken)) {
            buy(sender,claimAddress,amount);
        } else if (msg.sender == address(IWTON(wton))) {
            uint256 wtonAmount = _toWAD(amount);
            buy(sender,claimAddress,wtonAmount);
        }
        
        return true;
    }

    function directBuy(
        address _claimAddress,
        uint256 _amount
    ) public override {
        require(saleStartTime != 0 && saleEndTime != 0, "need to setting saleTime");
        require(block.timestamp >= saleStartTime && block.timestamp <= saleEndTime, "privaSale period end");
        WhiteList storage userwhite = usersWhite[msg.sender];
        require(userwhite.amount >= _amount, "need to add whiteList amount");

        _buy(msg.sender,_claimAddress,_amount);
        userwhite.amount = userwhite.amount.sub(_amount);
    }

    function buy(
        address _sender,
        address _claimAddress,
        uint256 _amount
    ) internal {
        require(saleStartTime != 0 && saleEndTime != 0, "need to setting saleTime");
        require(block.timestamp >= saleStartTime && block.timestamp <= saleEndTime, "privaSale period end");
        WhiteList storage userwhite = usersWhite[_sender];
        require(userwhite.amount >= _amount, "need to add whiteList amount");

        _buy(_sender,_claimAddress,_amount);
        userwhite.amount = userwhite.amount.sub(_amount);
    }

    function _buy(
        address _sender,
        address _claimAddress,
        uint256 _amount
    )
        internal
    {
        if(_claimAddress == address(0)){
            _claimAddress = _sender;
        }

        UserInfoAmount storage user = usersAmount[_claimAddress];

        uint256 tokenSaleAmount = calculSaleToken(_amount);
        uint256 Saledtoken = totalSaleAmount.add(tokenSaleAmount);
        uint256 tokenBalance = saleToken.balanceOf(address(this));

        require(
            tokenBalance >= Saledtoken,
            "don't have token amount"
        );

        uint256 tonAllowance = getToken.allowance(_sender, address(this));
        uint256 tonBalance = getToken.balanceOf(_sender);

        if(tonAllowance > tonBalance) {
            tonAllowance = tonBalance;  //tonAllowance가 tonBlance보다 더 클때 문제가 된다.
        }
        if(tonAllowance < _amount) {
            uint256 needUserWton;
            uint256 needWton = _amount.sub(tonAllowance);
            needUserWton = _toRAY(needWton);
            require(IWTON(wton).allowance(_sender, address(this)) >= needUserWton, "privateSale: wton amount exceeds allowance");
            require(IWTON(wton).balanceOf(_sender) >= needUserWton, "need more wton");
            IERC20(wton).safeTransferFrom(_sender,address(this),needUserWton);
            IWTON(wton).swapToTON(needUserWton);
            require(tonAllowance >= _amount.sub(needWton), "privateSale: ton amount exceeds allowance");
            if(_amount.sub(needWton) > 0) {
                getToken.safeTransferFrom(_sender, address(this), _amount.sub(needWton));   
            }
            getToken.safeTransfer(getTokenOwner, _amount);
        } else {
            require(tonAllowance >= _amount && tonBalance >= _amount, "privateSale: ton amount exceeds allowance");

            getToken.safeTransferFrom(_sender, address(this), _amount);
            getToken.safeTransfer(getTokenOwner, _amount);
        }

        user.inputamount = user.inputamount.add(_amount);
        user.totaloutputamount = user.totaloutputamount.add(tokenSaleAmount);
        user.getAmount = user.getAmount;
        user.inputAddress = _sender;

        totalGetAmount = totalGetAmount.add(_amount);
        totalSaleAmount = totalSaleAmount.add(tokenSaleAmount);

        emit Buyinfo(
            msg.sender, 
            user.inputamount, 
            user.totaloutputamount,
            block.timestamp
        );
    }

    function claim() external override {
        require(saleEndTime != 0, "need to setting Time");
        require(block.timestamp > saleEndTime, "need the endSale");
        require(block.timestamp > claimTimes[0], "need the claimTime");
        _claim();
        
    }

    function _claim() internal {
        require(block.timestamp >= claimTimes[0], "need the time for claim");

        UserInfoAmount storage user = usersAmount[msg.sender];

        require(user.inputamount > 0, "need to buy the token");
        require(user.totaloutputamount > user.getAmount, "already getAllreward");

        uint256 giveTokenAmount = calculClaimAmount(msg.sender, currentRound());
    
        require(user.totaloutputamount.sub(user.getAmount) >= giveTokenAmount, "user is already getAllreward");
        require(saleToken.balanceOf(address(this)) >= giveTokenAmount, "dont have saleToken in pool");

        user.getAmount = user.getAmount.add(giveTokenAmount);

        saleToken.safeTransfer(msg.sender, giveTokenAmount);

        emit Claiminfo(msg.sender, giveTokenAmount);
    }


    function withdraw(
        uint256 _amount
    ) 
        external 
        onlyOwner
        settingCheck 
    {
        require(
            saleToken.balanceOf(address(this)) >= _amount,
            "dont have token amount"
        );
        saleToken.safeTransfer(msg.sender, _amount);

        emit Withdrawinfo(msg.sender, _amount);
    }

}
