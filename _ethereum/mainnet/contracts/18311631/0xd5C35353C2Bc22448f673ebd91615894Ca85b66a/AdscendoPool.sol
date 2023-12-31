// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./ILido.sol";
import "./IPriceFeed.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

/**
 * @title AdscendoPool
 * @author
 * @notice Leveraged staking pool for ETH
 * @dev Implements minting and redeeming of LSTETH tokens
 */
contract AdscendoPool is Context, ReentrancyGuard {
    // Libraries

    using SafeMath for uint256; // Prevent overflows

    // State variables

    uint private _liquidationPrice; // Liquidation price threshold

    uint private _safePrice; // Safe price threshold

    uint private _mintFee;

    uint private _redeemFee;

    uint private immutable MAX_MINT_FEE = 50; // 5% max mint fee

    uint private immutable MAX_REDEEM_FEE = 50; // 5% max redeem fee

    uint256 private _totalFee;

    // Total amount of staked STETH
    uint256 private _stakedAmount;

    // Address to receive insurance fees
    address private _insurance;

    // Address to receive team fees
    address private _team;

    // Admin address
    address private _admin;

    // Factory contract that created this pool
    address private _factory;

    mapping(address => bool) _stakingPool;

    uint private _teamShare = 30;

    uint private _insuranceShare = 70;

    // AUSD stablecoin token contract
    IERC20 private _AUSD;

    // LSTETH token contract
    IERC20 private _lstETH;

    // STETH token contract
    IERC20 private _stETH;

    ILido private _lido;

    // Price feed contract
    IPriceFeed internal _priceFeed;

    // Flag for liquidation state
    bool internal _liquidated = false;

    /**
     * @notice Emitted when STETH is deposited
     * @param user User address
     * @param amount Amount deposited
     */
    event Mint(address user, uint256 amount);

    /**
     * @notice Emitted when LSTETH is redeemed
     * @param user User address
     * @param amount Amount redeemed
     */
    event Redeem(address user, uint256 amount);

    event EmergencyRedeem(address user, uint256 amount);

    event Liquidation(uint price);

    /**
     * @dev Reverts if pool is liquidated
     */
    modifier onlyNotLiquidated() {
        require(_liquidated == false, "Must be not liquidate");
        _;
    }

    // Modifier to check liquidated
    modifier onlyLiquidated() {
        require(_liquidated == true, "Must be liquidated");
        _;
    }

    // Modifier to check caller is admin
    modifier onlyAdmin() {
        require(_admin == _msgSender(), "Only admin");
        _;
    }

    modifier onlyStakingPool() {
        require(_stakingPool[_msgSender()] == true, "Only staking pool");
        _;
    }

    /**
     * @dev Sets initial state variables
     * @param liquidationPrice_ Liquidation price threshold
     * @param safePrice_ Safe price threshold
     * @param ausdAddress_ AUSD token address
     * @param lstethAddress_ LSTETH token address
     * @param stethAddress_ STETH token address
     * @param priceFeedAddress_ Price feed address
     * @param insurance_ Insurance fee address
     * @param team_ Team fee address
     * @param admin_ Admin address
     * @param mintFee_ Initial minting fee percentage
     * @param redeemFee_ Initial redeem fee percentage
     */
    constructor(
        uint liquidationPrice_,
        uint safePrice_,
        address ausdAddress_,
        address lstethAddress_,
        address stethAddress_,
        address priceFeedAddress_,
        address insurance_,
        address team_,
        address admin_,
        uint mintFee_,
        uint redeemFee_
    ) {
        // Set liquidation and safe price thresholds
        // 18-digit precision uint
        _liquidationPrice = liquidationPrice_;
        _safePrice = safePrice_;

        // Set token contract addresses
        _AUSD = IERC20(ausdAddress_);
        _stETH = IERC20(stethAddress_);
        _lstETH = IERC20(lstethAddress_);
        _lido = ILido(stethAddress_);

        // Set price feed and admin addresses
        _priceFeed = IPriceFeed(priceFeedAddress_);
        _insurance = insurance_;
        _team = team_;
        _admin = admin_;

        // Set factory and starting round
        _factory = _msgSender();

        // Set initial fee percentages
        _mintFee = mintFee_;
        _redeemFee = redeemFee_;
    }

    function lstETH() public view returns (address) {
        return address(_lstETH);
    }

    function stETH() public view returns (address) {
        return address(_stETH);
    }

    function AUSD() public view returns (address) {
        return address(_AUSD);
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function factory() public view returns (address) {
        return _factory;
    }

    function team() public view returns (address) {
        return _team;
    }

    function insurance() public view returns (address) {
        return _insurance;
    }

    function mintFee() public view returns (uint) {
        return _mintFee;
    }

    function redeemFee() public view returns (uint) {
        return _redeemFee;
    }

    function liquidationPrice() public view returns (uint) {
        return _liquidationPrice;
    }

    function safePrice() public view returns (uint) {
        return _safePrice;
    }

    function priceFeed() public view returns (address) {
        return address(_priceFeed);
    }

    function stakedAmount() public view returns (uint256) {
        return _stakedAmount;
    }

    function totalFee() public view returns (uint256) {
        return _totalFee;
    }

    function liquidated() public view returns (bool) {
        return _liquidated;
    }

    function isFeeWhitelist(address account) public view returns (bool) {
        return _stakingPool[account];
    }

    /**
     * @notice Deposits STETH and mints LSTETH + AUSD
     * @dev Only allowed if unliquidated
     * @param stAmount Amount of STETH to deposit
     */
    function mint(uint256 stAmount) external onlyNotLiquidated nonReentrant {
        uint _price = _priceFeed.fetchPrice();
        require(_price > _safePrice, "Current price must above threshold");

        _stETH.transferFrom(_msgSender(), address(this), stAmount);
        _mint(stAmount, _mintFee);
    }

    function mintWithETH(
        address _ref
    ) external payable onlyNotLiquidated nonReentrant {
        uint _price = _priceFeed.fetchPrice();
        require(_price > _safePrice, "Current price must above threshold");

        uint256 stAmount = _depositETHForSTETH(_ref);

        _mint(stAmount, _mintFee);
    }

    function mintNoFee(
        uint256 stAmount
    ) external onlyNotLiquidated onlyStakingPool nonReentrant {
        uint _price = _priceFeed.fetchPrice();
        require(_price > _safePrice, "Current price must above threshold");

        _stETH.transferFrom(_msgSender(), address(this), stAmount);
        _mint(stAmount, 0);
    }

    function mintWithETHNoFee(
        address _ref
    )
        external
        payable
        onlyNotLiquidated
        onlyStakingPool
        nonReentrant
        returns (uint256)
    {
        uint _price = _priceFeed.fetchPrice();
        require(_price > _safePrice, "Current price must above threshold");

        uint256 stAmount = _depositETHForSTETH(_ref);

        _mint(stAmount, 0);

        return stAmount;
    }

    function _depositETHForSTETH(address _ref) internal returns (uint256) {
        uint256 _sharesAmount = _lido.submit{value: msg.value}(_ref);
        uint256 stAmount = _lido.getPooledEthByShares(_sharesAmount);

        return stAmount;
    }

    function _mint(uint256 stAmount, uint mintFee_) internal {
        uint256 _fee = stAmount.mul(mintFee_).div(1000);
        uint256 _amount = stAmount.sub(_fee);

        _AUSD.mint(_msgSender(), _amount.mul(_liquidationPrice).div(10 ** 18));
        _lstETH.mint(_msgSender(), _amount);

        _stakedAmount = _stakedAmount.add(_amount);
        // fees
        _totalFee = _totalFee.add(_fee);

        emit Mint(_msgSender(), stAmount);
    }

    /**
     * @notice Redeems LSTETH for STETH and burns AUSD
     * @dev Only allowed if unliquidated
     * @param stAmount Amount of LSTETH to redeem
     */
    function redeem(uint256 stAmount) external onlyNotLiquidated nonReentrant {
        _redeem(stAmount, _redeemFee);
    }

    function redeemNoFee(
        uint256 stAmount
    ) external onlyNotLiquidated onlyStakingPool nonReentrant {
        _redeem(stAmount, 0);
    }

    function _redeem(uint256 stAmount, uint redeemFee_) internal {
        uint _price = _priceFeed.fetchPrice();
        require(
            _price > _liquidationPrice,
            "Current price must above threshold"
        );

        // Calculate fee
        uint256 _fee = stAmount.mul(redeemFee_).div(1000);
        uint256 _amount = stAmount.sub(_fee);

        // Burn AUSD and LSTETH
        _AUSD.burn(_msgSender(), stAmount.mul(_liquidationPrice).div(10 ** 18));
        _lstETH.burn(_msgSender(), stAmount);

        // Transfer STETH minus fee
        _stETH.transfer(_msgSender(), _amount);

        // Update staked amount
        _stakedAmount = _stakedAmount.sub(stAmount);

        // fees
        _totalFee = _totalFee.add(_fee);

        emit Redeem(_msgSender(), stAmount);
    }

    /**
     * @notice Liquidates the pool
     * @dev Changes liquidated state to true
     */
    function liquidation() external {
        uint _price = _priceFeed.fetchPrice();

        require(
            _price < _liquidationPrice,
            "Current price must below threshold"
        );

        // Set liquidated flag
        _liquidated = true;

        emit Liquidation(_price);
    }

    /**
     * @notice Emergency redeem post liquidation
     * @dev Allows redeem if price > safe
     * @param ausdAmount Amount of AUSD to redeem
     * @return stETHAmount Amount of STETH withdrawn
     */
    function emergencyRedeem(
        uint256 ausdAmount
    ) external onlyLiquidated nonReentrant returns (uint256) {
        uint _price = _priceFeed.fetchPrice();

        require(_price > _safePrice, "Current price must above threshold");

        return _emergencyRedeem(ausdAmount, _price, _redeemFee);
    }

    /**
     * @notice Maintenance redeem post liquidation
     * @dev Allows admin to redeem LSTETH if liquidated
     * @param ausdAmount Amount of AUSD to redeem
     * @return stETHAmount Amount of STETH withdrawn
     */
    function mantenceRedeem(
        uint256 ausdAmount
    ) external onlyAdmin onlyLiquidated nonReentrant returns (uint256) {
        uint _price = _priceFeed.fetchPrice();

        return _emergencyRedeem(ausdAmount, _price, _redeemFee);
    }

    function emergencyRedeemNoFee(
        uint ausdAmount
    ) external onlyStakingPool onlyLiquidated nonReentrant returns (uint256) {
        uint _price = _priceFeed.fetchPrice();

        return _emergencyRedeem(ausdAmount, _price, 0);
    }

    /**
     * @dev Internal logic for emergency redeem
     * @param ausdAmount AUSD amount to redeem
     * @param price Current price of ETH
     * @return stETHAmount Amount of STETH withdrawn
     */
    function _emergencyRedeem(
        uint256 ausdAmount,
        uint price,
        uint redeemFee_
    ) internal returns (uint256) {
        require(_stakedAmount > 0, "Nothing left");

        uint256 stAmount = ausdAmount.mul(10 ** 18).div(price);
        uint256 fee = stAmount.mul(redeemFee_).div(1000);
        uint256 redeemAmount = stAmount.sub(fee);

        _AUSD.burn(_msgSender(), ausdAmount);

        if (stAmount > _stakedAmount) {
            _stETH.transfer(_msgSender(), _stakedAmount.sub(fee));
            _stakedAmount = 0;
        } else {
            _stETH.transfer(_msgSender(), redeemAmount);
            _stakedAmount = _stakedAmount.sub(stAmount);
        }

        _totalFee = _totalFee.add(fee);

        emit EmergencyRedeem(_msgSender(), stAmount);

        return redeemAmount;
    }

    /**
     * @notice Set minting fee percentage
     * @dev Only callable by admin
     * @param value_ New minting fee percentage
     */
    function setMintFee(uint value_) external onlyAdmin {
        require(value_ <= MAX_MINT_FEE, "Can not greater than max mint fee");
        _mintFee = value_;
    }

    /**
     * @notice Set redeeming fee percentage
     * @dev Only callable by admin
     * @param value_ New redeeming fee percentage
     */
    function setRedeemFee(uint value_) external onlyAdmin {
        require(
            value_ <= MAX_REDEEM_FEE,
            "Can not greater than max redeem fee"
        );
        _redeemFee = value_;
    }

    function withdrawSTETHReward() external onlyAdmin {
        uint256 _balance = _stETH.balanceOf(address(this));
        uint256 _reward = _balance.sub(_stakedAmount).sub(_totalFee);

        if (_reward <= 0) {
            revert();
        }

        _stETH.transfer(_admin, _reward);
    }

    function distributeCollectedFees() external onlyAdmin {
        require(_totalFee > 0, "No fee collected yet");

        _stETH.transfer(_team, _totalFee.mul(_teamShare).div(100));
        _stETH.transfer(_insurance, _totalFee.mul(_insuranceShare).div(100));

        _totalFee = 0;
    }

    function setTeamShare(uint value) external onlyAdmin {
        require(value < 100, "Value should less than 100");

        _teamShare = value;
        _insuranceShare = 100 - value;
    }

    function setStakingPool(address account, bool value) external onlyAdmin {
        require(account != address(0), "No Zero address");

        _stakingPool[account] = value;
    }
}
