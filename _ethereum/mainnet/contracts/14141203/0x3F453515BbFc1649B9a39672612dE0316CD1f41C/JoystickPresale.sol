// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Math.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Authorizable.sol";
import "./xJoyToken.sol";

contract JoystickPresale is Context, Authorizable {
    using SafeMath for uint256;

    // Info of each coin like USDT, USDC
    struct CoinInfo {
        address addr;
        uint256 rate;
    }

    // Info of each Purchaser
    struct UserInfo {
        uint256 depositedAmount;      // How many Coins amount the user has deposited.
        uint256 purchasedAmount;      // How many JOY tokens the user has purchased.
        uint256 withdrawnAmount;      // Withdrawn amount
        uint256 lastWithdrawnTime;    // Last Withdrawn time  
    }

    // Sale flag and related times.
    bool public SALE_FLAG;
    uint256 public SALE_START;
    uint256 public SALE_DURATION;
    uint256 public LOCKING_DURATION;
    uint256 public VESTING_DURATION;

    // Coin Info list
    mapping(uint => CoinInfo) public coinInfo;
    uint8 public coinInfoCount;
    uint8 public COIN_DECIMALS = 18;

    // The JOY Token
    IERC20 public govToken;
    // The xJOY Token
    IERC20 public xGovToken;
    // User address => UserInfo
    mapping(address => UserInfo) public userInfo;
    address[] public userAddrs;

    // total tokens amounts (all 18 decimals)
    uint256 public totalSaleAmount;
    uint256 public totalCoinAmount;
    uint256 public totalSoldAmount;

    // treasury address
    address public treasuryAddress;

    // Events.
    event TokensPurchased(address indexed purchaser, uint256 coinAmount, uint256 tokenAmount);
    event TokensWithdrawed(address indexed purchaser, uint256 tokenAmount);

    // Modifiers.
    modifier whenSale() {
        require(checkSalePeriod(), "This is not sale period.");
        _;
    }
    modifier whenVesting() {
        require(checkVestingPeriod(), "This is not vesting period.");
        _;
    }

    constructor(IERC20 _govToken, IERC20 _xGovToken, CoinInfo[] memory _coinInfo, uint256 _totalSaleAmount)
    {
        addAuthorized(_msgSender());
        
        treasuryAddress = _msgSender();
        govToken = _govToken;
        xGovToken = _xGovToken;
        totalSaleAmount = _totalSaleAmount.mul(10 ** ERC20(address(xGovToken)).decimals());

        for (uint i=0; i<_coinInfo.length; i++) {
            addCoinInfo(_coinInfo[i].addr, _coinInfo[i].rate);
        }

        SALE_FLAG = true;
        SALE_START = block.timestamp;
        SALE_DURATION = 60 days;
        LOCKING_DURATION = 730 days;
        VESTING_DURATION = 365 days;
    }

    // Update token
    function updateTokens(IERC20 _govToken, IERC20 _xGovToken) public onlyAuthorized {
        govToken = _govToken;
        xGovToken = _xGovToken;
    }

    // Start stop sale
    function startSale(bool bStart) public onlyAuthorized {
        SALE_FLAG = bStart;
        if (bStart) {
            SALE_START = block.timestamp;
        }
    }

    // Set durations
    function setDurations(uint256 saleDuration, uint256 lockingDuration, uint256 vestingDuration) public onlyAuthorized {
        SALE_DURATION = saleDuration;
        LOCKING_DURATION = lockingDuration;
        VESTING_DURATION = vestingDuration;
    }

    // check sale period
    function checkSalePeriod() public view returns (bool) {
        return SALE_FLAG && block.timestamp >= SALE_START && block.timestamp <= SALE_START.add(SALE_DURATION);
    }

    // check locking period
    function checkLockingPeriod() public view returns (bool) {
        return block.timestamp >= SALE_START && block.timestamp <= SALE_START.add(LOCKING_DURATION);
    }

    // check vesting period
    function checkVestingPeriod() public view returns (bool) {
        uint256 VESTING_START = SALE_START.add(LOCKING_DURATION);
        return block.timestamp >= VESTING_START;
    }

    // Add coin info
    function addCoinInfo(address addr, uint256 rate) public onlyAuthorized {
        coinInfo[coinInfoCount] = CoinInfo(addr, rate);
        coinInfoCount++;
    }

    // Set coin info
    function setCoinInfo(address addr, uint256 rate, uint8 index) public onlyAuthorized {
        coinInfo[index] = CoinInfo(addr, rate);
    }

    // Set total sale amount
    function setTotalSaleAmount(uint256 amount) public onlyAuthorized {
        totalSaleAmount = amount;
    }

    // Get user count
    function getUserCount() public view returns (uint256) {
        return userAddrs.length;
    }

    // Get user addrs
    function getUserAddrs() public view returns (address[] memory) {
        address[] memory returnData = new address[](userAddrs.length);
        for (uint i=0; i<userAddrs.length; i++) {
            returnData[i] = userAddrs[i];
        }
        return returnData;
    }
    
    // Get user infos
    function getUserInfos() public view returns (UserInfo[] memory returnData) {
        returnData = new UserInfo[](userAddrs.length);
        for (uint i=0; i<userAddrs.length; i++) {
            UserInfo memory _userInfo = userInfo[userAddrs[i]];
            returnData[i] = _userInfo;
        }
        return returnData;
    }

    // set User Info
    function setUserInfo(address addr, uint256 depositedAmount, uint256 purchasedAmount, uint256 withdrawnAmount) public onlyAuthorized {
       UserInfo storage _userInfo = userInfo[addr];
       if (_userInfo.depositedAmount == 0) {
           userAddrs.push(addr);
       } else {
           totalCoinAmount = totalCoinAmount.sub(Math.min(totalCoinAmount, _userInfo.depositedAmount));
           totalSoldAmount = totalSoldAmount.sub(Math.min(totalSoldAmount, _userInfo.purchasedAmount));
       }
        totalCoinAmount = totalCoinAmount.add(depositedAmount);
        totalSoldAmount = totalSoldAmount.add(purchasedAmount);

       _userInfo.depositedAmount = depositedAmount;
       _userInfo.purchasedAmount = purchasedAmount;
       _userInfo.withdrawnAmount = withdrawnAmount;
    }


    // deposit
    // coinAmount (decimals: COIN_DECIMALS) 
    function deposit(uint256 _coinAmount, uint8 coinIndex) external whenSale {
        require( totalSaleAmount >= totalSoldAmount, "totalSaleAmount >= totalSoldAmount");

        CoinInfo memory _coinInfo = coinInfo[coinIndex];
        IERC20 coin = IERC20(_coinInfo.addr);

        // calculate token amount to be transferred
        (uint256 tokenAmount, uint256 coinAmount) = calcTokenAmount(_coinAmount, coinIndex);
        uint256 availableTokenAmount = totalSaleAmount.sub(totalSoldAmount);

        // if the token amount is less than remaining
        if (availableTokenAmount < tokenAmount) {
            tokenAmount = availableTokenAmount;
            (_coinAmount, coinAmount) = calcCoinAmount(availableTokenAmount, coinIndex);
        }

        // validate purchasing
        _preValidatePurchase(_msgSender(), tokenAmount, coinAmount, coinIndex);

        // transfer coin and token
        coin.transferFrom(_msgSender(), address(this), coinAmount);
        xGovToken.transfer(_msgSender(), tokenAmount);

        // transfer coin to treasury
        if (treasuryAddress != 0x0000000000000000000000000000000000000000) {
            coin.transfer(treasuryAddress, coinAmount);
        }

        // update global state
        totalCoinAmount = totalCoinAmount.add(_coinAmount);
        totalSoldAmount = totalSoldAmount.add(tokenAmount);
        
       // update purchased token list
       UserInfo storage _userInfo = userInfo[_msgSender()];
       if (_userInfo.depositedAmount == 0) {
           userAddrs.push(_msgSender());
       }
       _userInfo.depositedAmount = _userInfo.depositedAmount.add(_coinAmount);
       _userInfo.purchasedAmount = _userInfo.purchasedAmount.add(tokenAmount);
       
       emit TokensPurchased(_msgSender(), _coinAmount, tokenAmount);

       xJoyToken _xJoyToken = xJoyToken(address(xGovToken));
       _xJoyToken.addPurchaser(_msgSender(), tokenAmount);
    }

    // withdraw
    function withdraw() external whenVesting {
        uint256 withdrawalAmount = calcWithdrawalAmount(_msgSender());
        uint256 govTokenAmount = govToken.balanceOf(address(this));
        uint256 xGovTokenAmount = xGovToken.balanceOf(address(_msgSender()));
        uint256 withdrawAmount = Math.min(withdrawalAmount, Math.min(govTokenAmount, xGovTokenAmount));
       
        require(withdrawAmount > 0, "No withdraw amount!");
        require(xGovToken.allowance(msg.sender, address(this)) >= withdrawAmount, "withdraw's allowance is low!");

        xGovToken.transferFrom(_msgSender(), address(this), withdrawAmount);
        govToken.transfer(_msgSender(), withdrawAmount);

        UserInfo storage _userInfo = userInfo[_msgSender()];
        _userInfo.withdrawnAmount = _userInfo.withdrawnAmount.add(withdrawAmount);
        _userInfo.lastWithdrawnTime = block.timestamp;

        emit TokensWithdrawed(_msgSender(), withdrawAmount);
    }

    // Calc token amount by coin amount
    function calcWithdrawalAmount(address addr) public view returns (uint256) {
        require(checkVestingPeriod(), "This is not vesting period.");

        uint256 VESTING_START = SALE_START.add(LOCKING_DURATION);

        UserInfo memory _userInfo = userInfo[addr];
        uint256 totalAmount = 0;
        if (block.timestamp >= VESTING_START.add(VESTING_DURATION)) {
            totalAmount = _userInfo.purchasedAmount;
        } else {
            totalAmount = _userInfo.purchasedAmount.mul(block.timestamp.sub(VESTING_START)).div(VESTING_DURATION);
        }

        uint256 withdrawalAmount = totalAmount.sub(_userInfo.withdrawnAmount);
        return withdrawalAmount;
    }

    // Calc token amount by coin amount
    function calcTokenAmount(uint256 _coinAmount, uint8 coinIndex) public view returns (uint256, uint256) {
        require( coinInfoCount >= coinIndex, "coinInfoCount >= coinIndex");

        CoinInfo memory _coinInfo = coinInfo[coinIndex];
        ERC20 coin = ERC20(_coinInfo.addr);
        uint256 rate = _coinInfo.rate;

        uint tokenDecimal =  ERC20(address(xGovToken)).decimals() + coin.decimals() - COIN_DECIMALS;
        uint256 tokenAmount = _coinAmount
        .mul(10**tokenDecimal)
        .div(rate);
        
        uint coinDecimal =  COIN_DECIMALS - coin.decimals();
        uint256 coinAmount = _coinAmount
        .div(10**coinDecimal);

        return (tokenAmount, coinAmount);
    }

    // Calc coin amount by token amount
    function calcCoinAmount(uint256 _tokenAmount, uint8 coinIndex) public view returns (uint256, uint256) {
        require( coinInfoCount >= coinIndex, "coinInfoCount >= coinIndex");

        CoinInfo memory _coinInfo = coinInfo[coinIndex];
        ERC20 coin = ERC20(_coinInfo.addr);
        uint256 rate = _coinInfo.rate;

        uint _coinDecimal =  ERC20(address(xGovToken)).decimals() + coin.decimals() - COIN_DECIMALS;
        uint256 _coinAmount = _tokenAmount
        .div(10**_coinDecimal)
        .mul(rate);
        
        uint coinDecimal =  COIN_DECIMALS - coin.decimals();
        uint256 coinAmount = _coinAmount
        .div(10**coinDecimal);

        return (_coinAmount, coinAmount);
    }

    // Calc max coin amount to be deposit
    function calcMaxCoinAmountToBeDeposit(uint8 coinIndex) public view returns (uint256) {
        uint256 availableTokenAmount = totalSaleAmount.sub(totalSoldAmount);
        (uint256 _coinAmount,) = calcCoinAmount(availableTokenAmount, coinIndex);
        return _coinAmount;
    }

    // Validate purchase
    function _preValidatePurchase(address purchaser, uint256 tokenAmount, uint256 coinAmount, uint8 coinIndex) internal view {
        require( coinInfoCount >= coinIndex, "coinInfoCount >= coinIndex");
        CoinInfo memory _coinInfo = coinInfo[coinIndex];
        IERC20 coin = IERC20(_coinInfo.addr);

        require(purchaser != address(0), "Purchaser is the zero address");
        require(coinAmount != 0, "Coin amount is 0");
        require(tokenAmount != 0, "Token amount is 0");

        require(xGovToken.balanceOf(address(this)) >= tokenAmount, "$xJoyToken amount is lack!");
        require(coin.balanceOf(msg.sender) >= coinAmount, "Purchaser's coin amount is lack!");
        require(coin.allowance(msg.sender, address(this)) >= coinAmount, "Purchaser's allowance is low!");

        this;
    }

    // update the treasury address
    function updateTreasuryAddress(address treasury) public onlyOwner {
        treasuryAddress = treasury;
    }

    /**
     * withdraw all coins by owner
     */
    function withdrawAllCoins(address treasury) public onlyOwner {
        for (uint i=0; i<coinInfoCount; i++) {
            CoinInfo memory _coinInfo = coinInfo[i];
            IERC20 _coin = IERC20(_coinInfo.addr);
            uint256 coinAmount = _coin.balanceOf(address(this));
            _coin.transfer(treasury, coinAmount);
        }
    }

    /**
     * withdraw all xJOY by owner
     */
    function withdrawAllxGovTokens(address treasury) public onlyOwner {
        uint256 tokenAmount = xGovToken.balanceOf(address(this));
        xGovToken.transfer(treasury, tokenAmount);
    }

    /**
     * withdraw all $JOY by owner
     */
    function withdrawAllGovTokens(address treasury) public onlyOwner {
        uint256 tokenAmount = govToken.balanceOf(address(this));
        govToken.transfer(treasury, tokenAmount);
    }    
}