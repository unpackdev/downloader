// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

import "./IERC20.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";

contract MemeMaster2023Presale is ReentrancyGuard, Ownable {
  uint256 public presaleId;
  uint256 public BASE_MULTIPLIER;

  struct Presale {
    address saleToken;
    uint256 startTime;
    uint256 endTime;
    uint256 price;
    uint256 tokensToSell;
    uint256 baseDecimals;
    uint256 inSale;
    uint256 vestingStartTime;
    uint256 vestingCliff;
    uint256 enableBuyWithEth;
    uint256 enableBuyWithUsdt;
    address payout;
  }

  struct Vesting {
    uint256 totalAmount;
    uint256 claimedAmount;
    uint256 claimStart;
  }

  IERC20 public USDTInterface;
  AggregatorV3Interface internal aggregatorInterface; // https://docs.chain.link/docs/ethereum-addresses/ => (ETH / USD)

  mapping(uint256 => bool) public paused;
  mapping(uint256 => Presale) public presale;
  mapping(address => mapping(uint256 => Vesting)) public userVesting;

  event PresaleCreated(
    uint256 indexed _id,
    uint256 _totalTokens,
    uint256 _startTime,
    uint256 _endTime,
    uint256 enableBuyWithEth,
    uint256 enableBuyWithUsdt,
    address _payout
  );

  event PresaleUpdated(bytes32 indexed key, uint256 prevValue, uint256 newValue, uint256 timestamp);

  event TokensBought(
    address indexed user,
    uint256 indexed id,
    address indexed purchaseToken,
    uint256 tokensBought,
    uint256 amountPaid,
    uint256 timestamp
  );

  event TokensClaimed(address indexed user, uint256 indexed id, uint256 amount, uint256 timestamp);

  event PresaleTokenAddressUpdated(address indexed prevValue, address indexed newValue, uint256 timestamp);

  event PresalePayoutAddressUpdated(address indexed prevValue, address indexed newValue, uint256 timestamp);

  event PresalePaused(uint256 indexed id, uint256 timestamp);
  event PresaleUnpaused(uint256 indexed id, uint256 timestamp);

  /**
   * @dev Initializes the contract and sets key parameters
   * @param _oracle Oracle contract to fetch ETH/USDT price
   * @param _usdt USDT token contract address
   */
  constructor(address _oracle, address _usdt) {
    require(_oracle != address(0), "Zero aggregator address");
    require(_usdt != address(0), "Zero USDT address");

    aggregatorInterface = AggregatorV3Interface(_oracle);
    USDTInterface = IERC20(_usdt);
    BASE_MULTIPLIER = (10**18);
  }

  /**
   * @dev Creates a new presale
   * @param _startTime start time of the sale
   * @param _endTime end time of the sale
   * @param _price Per token price multiplied by (10**18)
   * @param _tokensToSell No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
   * @param _baseDecimals No of decimals for the token. (10**18), for 18 decimal token
   * @param _vestingStartTime Start time for the vesting - UNIX timestamp
   * @param _vestingCliff Cliff period for vesting in seconds
   * @param _enableBuyWithEth Enable/Disable buy of tokens with ETH
   * @param _enableBuyWithUsdt Enable/Disable buy of tokens with USDT
   * @param _payout Ethereum address where presale contributions will be moved
   */
  function createPresale(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _price,
    uint256 _tokensToSell,
    uint256 _baseDecimals,
    uint256 _vestingStartTime,
    uint256 _vestingCliff,
    uint256 _enableBuyWithEth,
    uint256 _enableBuyWithUsdt,
    address _payout
  ) external onlyOwner {
    require(_startTime > block.timestamp && _endTime > _startTime, "Invalid time");
    require(_price > 0, "Zero price");
    require(_tokensToSell > 0, "Zero tokens to sell");
    require(_baseDecimals > 0, "Zero decimals for the token");
    require(_vestingStartTime >= _endTime, "Vesting starts before Presale ends");

    presaleId++;

    presale[presaleId] = Presale(
      address(0),
      _startTime,
      _endTime,
      _price,
      _tokensToSell,
      _baseDecimals,
      _tokensToSell,
      _vestingStartTime,
      _vestingCliff,
      _enableBuyWithEth,
      _enableBuyWithUsdt,
      _payout
    );

    emit PresaleCreated(presaleId, _tokensToSell, _startTime, _endTime, _enableBuyWithEth, _enableBuyWithUsdt, _payout);
  }

  /**
   * @dev To update the oracle address address
   * @param _newAddress oracle address
   */

  function changeOracleAddress(address _newAddress) external onlyOwner {
    require(_newAddress != address(0), "Zero token address");
    aggregatorInterface = AggregatorV3Interface(_newAddress);
  }


  /**
   * @dev To update the usdt token address
   * @param _newAddress Sale token address
   */
  function changeUsdtAddress(address _newAddress) external onlyOwner {
    require(_newAddress != address(0), "Zero token address");
    USDTInterface = IERC20(_newAddress);
  }

  /**
   * @dev To update the sale times before presale starts
   * @param _id Presale id to update
   * @param _startTime New start time
   * @param _endTime New end time
   */
  function changeSaleTimes(
    uint256 _id,
    uint256 _startTime,
    uint256 _endTime
  ) external checkPresaleId(_id) onlyOwner {
    require(_startTime > 0 || _endTime > 0, "Invalid parameters");
    if (_startTime > 0) {
      require(block.timestamp < presale[_id].startTime, "Sale already started");
      require(block.timestamp < _startTime, "Sale time in past");
      uint256 prevValue = presale[_id].startTime;
      presale[_id].startTime = _startTime;
      emit PresaleUpdated(bytes32("START"), prevValue, _startTime, block.timestamp);
    }

    if (_endTime > 0) {
      require(block.timestamp < _endTime, "End time in the past");
      require(_endTime > presale[_id].startTime, "Invalid endTime");
      uint256 prevValue = presale[_id].endTime;
      presale[_id].endTime = _endTime;
      emit PresaleUpdated(bytes32("END"), prevValue, _endTime, block.timestamp);
    }
  }


  /**
   * @dev To update the end time of presale after it starts
   * @param _id Presale id to update
   * @param _newEndTime New end time
   */
  function changePresaleEndtime(
    uint256 _id,
    uint256 _newEndTime
  ) external checkPresaleId(_id) onlyOwner {

    if (_newEndTime > 0) {
      require(block.timestamp < _newEndTime, "End time in the past");
      require(_newEndTime > presale[_id].startTime, "Invalid endTime");
      uint256 prevValue = presale[_id].endTime;
      presale[_id].endTime = _newEndTime;
      emit PresaleUpdated(bytes32("END"), prevValue, _newEndTime, block.timestamp);
    }
  }

  /**
   * @dev To update the vesting start time
   * @param _id Presale id to update
   * @param _vestingStartTime New vesting start time
   */
  function changeVestingStartTime(uint256 _id, uint256 _vestingStartTime) external checkPresaleId(_id) onlyOwner {
    require(_vestingStartTime >= presale[_id].endTime, "Vesting starts before Presale ends");
    uint256 prevValue = presale[_id].vestingStartTime;
    presale[_id].vestingStartTime = _vestingStartTime;
    emit PresaleUpdated(bytes32("VESTING_START_TIME"), prevValue, _vestingStartTime, block.timestamp);
  }

  /**
   * @dev To update the sale token address
   * @param _id Presale id to update
   * @param _newAddress Sale token address
   */
  function changeSaleTokenAddress(uint256 _id, address _newAddress) external checkPresaleId(_id) onlyOwner {
    require(_newAddress != address(0), "Zero token address");
    address prevValue = presale[_id].saleToken;
    presale[_id].saleToken = _newAddress;
    emit PresaleTokenAddressUpdated(prevValue, _newAddress, block.timestamp);
  }

  /**
   * @dev To update the payout address
   * @param _id Presale id to update
   * @param _newAddress payout address
   */
  function changePayoutAddress(uint256 _id, address _newAddress) external checkPresaleId(_id) onlyOwner {
    require(_newAddress != address(0), "Zero token address");
    address prevValue = presale[_id].payout;
    presale[_id].payout = _newAddress;
    emit PresalePayoutAddressUpdated(prevValue, _newAddress, block.timestamp);
  }

  /**
   * @dev To update the price
   * @param _id Presale id to update
   * @param _newPrice New sale price of the token
   */
  function changePrice(uint256 _id, uint256 _newPrice) external checkPresaleId(_id) onlyOwner {
    require(_newPrice > 0, "Zero price");
    require(presale[_id].startTime > block.timestamp, "Sale already started");
    uint256 prevValue = presale[_id].price;
    presale[_id].price = _newPrice;
    emit PresaleUpdated(bytes32("PRICE"), prevValue, _newPrice, block.timestamp);
  }

  /**
   * @dev To update possibility to buy with ETH
   * @param _id Presale id to update
   * @param _enableToBuyWithEth New value of enable to buy with ETH
   */
  function changeEnableBuyWithEth(uint256 _id, uint256 _enableToBuyWithEth) external checkPresaleId(_id) onlyOwner {
    uint256 prevValue = presale[_id].enableBuyWithEth;
    presale[_id].enableBuyWithEth = _enableToBuyWithEth;
    emit PresaleUpdated(bytes32("ENABLE_BUY_WITH_ETH"), prevValue, _enableToBuyWithEth, block.timestamp);
  }

  /**
   * @dev To update possibility to buy with Usdt
   * @param _id Presale id to update
   * @param _enableToBuyWithUsdt New value of enable to buy with Usdt
   */
  function changeEnableBuyWithUsdt(uint256 _id, uint256 _enableToBuyWithUsdt) external checkPresaleId(_id) onlyOwner {
    uint256 prevValue = presale[_id].enableBuyWithUsdt;
    presale[_id].enableBuyWithUsdt = _enableToBuyWithUsdt;
    emit PresaleUpdated(bytes32("ENABLE_BUY_WITH_USDT"), prevValue, _enableToBuyWithUsdt, block.timestamp);
  }

  /**
   * @dev To pause the presale
   * @param _id Presale id to update
   */
  function pausePresale(uint256 _id) external checkPresaleId(_id) onlyOwner {
    require(!paused[_id], "Already paused");
    paused[_id] = true;
    emit PresalePaused(_id, block.timestamp);
  }

  /**
   * @dev To unpause the presale
   * @param _id Presale id to update
   */
  function unPausePresale(uint256 _id) external checkPresaleId(_id) onlyOwner {
    require(paused[_id], "Not paused");
    paused[_id] = false;
    emit PresaleUnpaused(_id, block.timestamp);
  }

  /**
   * @dev To get latest ethereum price in 10**18 format
   */
  function getLatestPrice() public view returns (uint256) {
    (, int256 price, , , ) = aggregatorInterface.latestRoundData();
    price = (price * (10**10));
    return uint256(price);
  }

  modifier checkPresaleId(uint256 _id) {
    require(_id > 0 && _id <= presaleId, "Invalid presale id");
    _;
  }

  modifier checkSaleState(uint256 _id, uint256 amount) {
    require(block.timestamp >= presale[_id].startTime && block.timestamp <= presale[_id].endTime, "Invalid time for buying");
    require(amount > 0 && amount <= presale[_id].inSale, "Invalid sale amount");
    _;
  }

  /**
   * @dev To buy into a presale using USDT
   * @param _id Presale id
   * @param amount No of tokens to buy
   */
  function buyWithUSDT(uint256 _id, uint256 amount) external checkPresaleId(_id) checkSaleState(_id, amount) returns (bool) {
    require(!paused[_id], "Presale paused");
    require(presale[_id].enableBuyWithUsdt > 0, "Not allowed to buy with USDT");
    uint256 usdPrice = amount * presale[_id].price;
    usdPrice = usdPrice / (10**12);
    presale[_id].inSale -= amount;

    Presale memory _presale = presale[_id];

    if (userVesting[_msgSender()][_id].totalAmount > 0) {
      userVesting[_msgSender()][_id].totalAmount += (amount * _presale.baseDecimals);
    } else {
      userVesting[_msgSender()][_id] = Vesting((amount * _presale.baseDecimals), 0, _presale.vestingStartTime + _presale.vestingCliff);
    }

    uint256 ourAllowance = USDTInterface.allowance(_msgSender(), address(this));
    require(usdPrice <= ourAllowance, "Make sure to add enough allowance");
    (bool success, ) = address(USDTInterface).call(
      abi.encodeWithSignature("transferFrom(address,address,uint256)", _msgSender(), _presale.payout, usdPrice)
    );
    require(success, "Token payment failed");
    emit TokensBought(_msgSender(), _id, address(USDTInterface), amount, usdPrice, block.timestamp);
    return true;
  }

  /**
   * @dev To buy into a presale using ETH
   * @param _id Presale id
   * @param amount No of tokens to buy
   */
  function buyWithEth(uint256 _id, uint256 amount) external payable checkPresaleId(_id) checkSaleState(_id, amount) nonReentrant returns (bool) {
    require(!paused[_id], "Presale paused");
    require(presale[_id].enableBuyWithEth > 0, "Not allowed to buy with ETH");
    uint256 usdPrice = amount * presale[_id].price;
    uint256 ethAmount = (usdPrice * BASE_MULTIPLIER) / getLatestPrice();
    require(msg.value >= ethAmount, "Less payment");
    uint256 excess = msg.value - ethAmount;
    presale[_id].inSale -= amount;
    Presale memory _presale = presale[_id];

    if (userVesting[_msgSender()][_id].totalAmount > 0) {
      userVesting[_msgSender()][_id].totalAmount += (amount * _presale.baseDecimals);
    } else {
      userVesting[_msgSender()][_id] = Vesting((amount * _presale.baseDecimals), 0, _presale.vestingStartTime + _presale.vestingCliff);
    }
    sendValue(payable(_presale.payout), ethAmount);
    if (excess > 0) sendValue(payable(_msgSender()), excess);
    emit TokensBought(_msgSender(), _id, address(0), amount, ethAmount, block.timestamp);
    return true;
  }

  /**
   * @dev Helper funtion to get ETH price for given amount
   * @param _id Presale id
   * @param amount No of tokens to buy
   */
  function ethBuyHelper(uint256 _id, uint256 amount) external view checkPresaleId(_id) returns (uint256 ethAmount) {
    uint256 usdPrice = amount * presale[_id].price;
    ethAmount = (usdPrice * BASE_MULTIPLIER) / getLatestPrice();
  }

  /**
   * @dev Helper funtion to get USDT price for given amount
   * @param _id Presale id
   * @param amount No of tokens to buy
   */
  function usdtBuyHelper(uint256 _id, uint256 amount) external view checkPresaleId(_id) returns (uint256 usdPrice) {
    usdPrice = amount * presale[_id].price;
    usdPrice = usdPrice / (10**12);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Low balance");
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "ETH Payment failed");
  }

  /**
   * @dev To get total tokens user can claim for a given presale based on their contributions.
   * @param user User address
   * @param _id Presale id
   */
  function tokenRewards(address user, uint256 _id) public view checkPresaleId(_id) returns (uint256) {
    Vesting memory _user = userVesting[user][_id];
    uint256 amount = _user.totalAmount - _user.claimedAmount;

    return amount / presale[_id].baseDecimals;
  }

  /**
   * @dev Helper funtion to get claimable tokens for a given presale after vesting period when presale claiming for claimning has started.
   * @param user User address
   * @param _id Presale id
   */
  function claimableAmount(address user, uint256 _id) public view checkPresaleId(_id) returns (uint256) {
    Vesting memory _user = userVesting[user][_id];
    require(_user.totalAmount > 0, "Nothing to claim");
    uint256 amount = _user.totalAmount - _user.claimedAmount;
    require(amount > 0, "Already claimed");

    if (block.timestamp < _user.claimStart) return 0;

    uint256 amountToClaim = amount * (10 ** presale[_id].baseDecimals);

    return amountToClaim / presale[_id].baseDecimals;
  }

  /**
   * @dev To claim tokens after vesting cliff from a presale
   * @param user User address
   * @param _id Presale id
   */
  function claim(address user, uint256 _id) public returns (bool) {
    uint256 amount = claimableAmount(user, _id);
    require(amount > 0, "Zero claim amount");
    require(presale[_id].saleToken != address(0), "Presale token address not set");
    require(amount <= IERC20(presale[_id].saleToken).balanceOf(address(this)), "Not enough tokens in the contract");

    uint256 claimedAmount = (amount * presale[_id].baseDecimals) / (10 ** presale[_id].baseDecimals);

    userVesting[user][_id].claimedAmount += claimedAmount;
    bool status = IERC20(presale[_id].saleToken).transfer(user, amount);
    require(status, "Token transfer failed");
    emit TokensClaimed(user, _id, amount, block.timestamp);
    return true;
  }

  /**
   * @dev To claim tokens after vesting cliff from a presale
   * @param users Array of user addresses
   * @param _id Presale id
   */
  function claimMultipleAccounts(address[] calldata users, uint256 _id) external returns (bool) {
    require(users.length > 0, "Zero users length");
    for (uint256 i; i < users.length; i++) {
      require(claim(users[i], _id), "Claim failed");
    }
    return true;
  }


  /**
   * @dev To claim tokens after vesting cliff from multiple presales
   * @param _ids Array of presale ids
   * @param _user Address of user
   */
  function claimMultipleStages(uint256[] calldata _ids, address _user) external returns (bool) {
    require(_ids.length > 0, "Zero users length");
    for (uint256 i; i < _ids.length; i++) {
      require(claim(_user, _ids[i]), "Claim failed");
    }
    return true;
  }

  //Use this in case Coins are sent to the contract by mistake
  function rescueETH(uint256 weiAmount) external onlyOwner {
    require(address(this).balance >= weiAmount, "insufficient Token balance");
    payable(msg.sender).transfer(weiAmount);
  }

  function rescueAnyERC20Tokens(
    address _tokenAddr,
    address _to,
    uint256 _amount
  ) public onlyOwner {
    IERC20(_tokenAddr).transfer(_to, _amount);
  }

  receive() external payable {}

  //override ownership renounce function from ownable contract
  function renounceOwnership() public pure override(Ownable) {
    revert("Unfortunately you cannot renounce Ownership of this contract!");
  }
}
