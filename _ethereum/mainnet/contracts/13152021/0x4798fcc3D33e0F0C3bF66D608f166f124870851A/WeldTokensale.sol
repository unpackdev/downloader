// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Detailed.sol";

contract WeldTokensale is OwnableUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * EVENTS
     **/
    event WELDPurchased(address indexed user, address indexed purchaseToken, uint256 WELDAmount);
    event TokensClaimed(address indexed user, uint256 AmoWELDunt);

    /**
     * CONSTANTS
     **/

    // *** TOKENSALE PARAMETERS START ***
    uint256 public constant PRECISION = 1000000; //Up to 0.000001

    uint256 private WITHDRAWAL_PERIOD;
    // *** TOKENSALE PARAMETERS END ***


    /***
     * STORAGE
     ***/

     enum Stages{
        Stage0,
        Stage1,
        Stage2,
        Stage3,
        Stage4,
        Ended,
        None
    }

    struct Stage{
        uint stage_start;
        uint stage_end;
        uint stage_pool;
        uint purchased;
    }

    Stage[] public stages;

    uint256 public maxTokensAmount;
    uint256 public maxGasPrice;

    // *** VESTING PARAMETERS START ***

    uint256 public vestingStart;
    uint256 public vestingDuration;
    
    // *** VESTING PARAMETERS END ***
    address public WELDToken;
    address internal USDTToken; // 0xdAC17F958D2ee523a2206206994597C13D831ec7
    address internal USDCToken; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address internal DAIToken; // 0x6B175474E89094C44Da98b954EedeAC495271d0F

    mapping (uint256=>mapping(address => uint256)) public purchasedAtStage;
    mapping (uint256 => uint256) public totalPurchasedAtStage;
    mapping (address => uint256) public purchased;
    uint256 public totalPurchased;
    mapping (address => uint256) internal _claimed;
    uint256 public ETHRate;
    mapping (address => uint256) public rates;

    address private _treasury;

    uint public stages_count;

    mapping(address=>bool) public isWhitelisted;

    bool public vestingStarted;
    
    /***
     * MODIFIERS
     ***/

    /**
     * @dev Throws if called with not supported token.
     */

    modifier whitelistOnly{
        require(isWhitelisted[_msgSender()], "Address is not in whitelist");
        _;
    }
    modifier supportedCoin(address _token) {
        require(_token == USDTToken || _token == USDCToken|| _token == DAIToken, "Token not supported");
        _;
    }

    modifier vestingNotStarted(){
        require(!vestingStarted, "Vesting is already started");
        _;

    }


    /**
    * @dev Throws if gas price exceeds gas limit.
    */
    modifier correctGas() {
        require(maxGasPrice == 0 || tx.gasprice <= maxGasPrice, "Gas price exceeds limit");
        _;
    }

    /***
     * INITIALIZER AND SETTINGS
     ***/

    function initialize(address _USDTToken, address _USDCToken, address _DAIToken, address WELD,
        uint s1_start, uint s1_end, uint s2_start, uint s2_end, uint withdrawal_period, 
        uint s1_pool, uint s2_pool, uint vest_duration) public initializer {
        require(WELD != address(0), "Zero address");


        USDTToken = _USDTToken;
        USDCToken = _USDCToken;
        DAIToken = _DAIToken;
        __Ownable_init();
        __Pausable_init(); 

        WELDToken = WELD;
        
        vestingStart = 0;
        maxTokensAmount = 1000000 * (10 ** 18);
        stages.push(Stage(s1_start, s1_end, s1_pool* (10 ** 18), 0));
        stages.push(Stage(s2_start, s2_end, s2_pool* (10 ** 18), 0));
        stages_count = 2;
        WITHDRAWAL_PERIOD = withdrawal_period * (1 days);
        vestingDuration = vest_duration * (1 days);
    }

    /**
     * @notice Updates current vesting start time. Can be used once
     */
    function adminVestingStart()  vestingNotStarted public onlyOwner{
        require(false, "Disabled");
        require(currentStage() != Stages.Ended, "Sale is not over");
        vestingStart = block.timestamp;
    }

    function adminAddStage(uint _start, uint _end, uint _pool) vestingNotStarted public onlyOwner{
        require(stages_count<=5, "Only 5 stages is allowed to be added");
        stages.push(Stage(_start, _end, _pool, 0));
        stages_count++;
    }

    /**
     * @notice Sets the rate for the chosen token based on the contracts precision
     * @param _token ERC20 token address or zero address for ETH
     * @param _rate Exchange rate based on precision (e.g. _rate = PRECISION corresponds to 1:1)
     */
    function adminSetRates(address _token, uint256 _rate) external onlyOwner {
        if (_token == address(0))
            ETHRate = _rate;
        else
            rates[_token] = _rate;
    }

    /**
    * @notice Allows owner to change the treasury address. Treasury is the address where all funds from sale go to
    * @param treasury New treasury address
    */
    function adminSetTreasury(address treasury) external onlyOwner {
        _treasury = treasury;
    }

    /**
    * @notice Allows owner to change max allowed WELD token per address.
    * @param _maxWELD New max WELD amount
    */ 
    function adminSetMaxWELD(uint256 _maxWELD) external onlyOwner {
        maxTokensAmount = _maxWELD;
    }

    /**
    * @notice Allows owner to change the max allowed gas price. Prevents gas wars
    * @param _maxGasPrice New max gas price
    */
    function adminSetMaxGasPrice(uint256 _maxGasPrice) external onlyOwner {
        maxGasPrice = _maxGasPrice;
    }

    /**
     * @notice Updates sales pool maximum
     * @param _pool New pool WELD maximum value
     */
    function adminSetPool(uint256 _stage, uint256 _pool) external onlyOwner {
        stages[_stage].stage_pool=_pool * (10 ** 18);
    }


    /**
    * @notice Stops purchase functions. Owner only
    */
    function adminPause() external onlyOwner {
        _pause();
    }

    /**
    * @notice Unpauses purchase functions. Owner only
    */
    function adminUnpause() external onlyOwner {
        _unpause();
    }

    
    function adminAddPurchase(address _receiver, uint256 _amount) external onlyOwner {
        purchased[_receiver] = purchased[_receiver].add(_amount);
    }
    
    function adminAddWhitelist(address[] memory _users) external onlyOwner {
        for(uint i=0; i<_users.length; i++){
            isWhitelisted[_users[i]] = true;
        }
    }

    function adminRemoveWhitelist(address[] memory _users) external onlyOwner {
        for(uint i=0; i<_users.length; i++){
            isWhitelisted[_users[i]] = false;
        }
    }
    /***
     * PURCHASE FUNCTIONS
     ***/

    /**
     * @notice For purchase with ETH
     */
    receive() external payable whenNotPaused vestingNotStarted{
        _purchaseWELDwithETH();
    }

    /**
     * @notice For purchase with allowed stablecoin (USDT and USDC)
     * @param ERC20token Address of the token to be paid in
     * @param ERC20amount Amount of the token to be paid in
     */
    function purchaseWELDwithERC20(address ERC20token, uint256 ERC20amount) external supportedCoin(ERC20token) vestingNotStarted whenNotPaused whitelistOnly correctGas {
        require(_treasury!=address(0), "Treasury has not been set");
        require(ERC20amount > 0, "Zero amount");
        uint256 purchaseAmount = _calcPurchaseAmount(ERC20token, ERC20amount);
        Stages  current_stage = currentStage();
        require(current_stage!=Stages.Ended && current_stage!=Stages.None, "Stage is not started or sale is over");
        _checkCapReached(purchaseAmount);
        
        require(stages[uint(current_stage)].purchased.add(purchaseAmount) <= stages[uint(current_stage)].stage_pool, "Not enough WELD in presale pool");
        stages[uint(current_stage)].purchased = stages[uint(current_stage)].purchased.add(purchaseAmount);
            
        purchasedAtStage[uint(current_stage)][_msgSender()] =  purchasedAtStage[uint(current_stage)][_msgSender()].add(purchaseAmount);
        totalPurchasedAtStage[uint(current_stage)] = totalPurchasedAtStage[uint(current_stage)].add(purchaseAmount);
        purchased[_msgSender()] = purchased[_msgSender()].add(purchaseAmount);
        totalPurchased=totalPurchased.add(purchaseAmount);

        IERC20Upgradeable(ERC20token).safeTransferFrom(_msgSender(), _treasury, ERC20amount); // send ERC20 to Treasury

        emit WELDPurchased(_msgSender(), ERC20token, purchaseAmount);
    }

    /**
     * @notice For purchase with ETH. ETH is left on the contract until withdrawn to treasury
     */
    function purchaseWELDwithETH() external payable vestingNotStarted whenNotPaused whitelistOnly {
        require(msg.value > 0, "No ETH sent");
        _purchaseWELDwithETH();
    }

    function _purchaseWELDwithETH() correctGas private {
        require(_treasury!=address(0), "Treasury has not been set");
        uint256 purchaseAmount = _calcEthPurchaseAmount(msg.value);
        Stages current_stage = currentStage();
        require(current_stage!=Stages.Ended, "Sale is over");
        _checkCapReached(purchaseAmount);

        require(stages[uint(current_stage)].purchased.add(purchaseAmount) <= stages[uint(current_stage)].stage_pool, "Not enough WELD in presale pool");
        stages[uint(current_stage)].purchased = stages[uint(current_stage)].purchased.add(purchaseAmount);

        purchasedAtStage[uint(current_stage)][_msgSender()] =  purchasedAtStage[uint(current_stage)][_msgSender()].add(purchaseAmount);
        totalPurchasedAtStage[uint(current_stage)] = totalPurchasedAtStage[uint(current_stage)].add(purchaseAmount);
        purchased[_msgSender()] = purchased[_msgSender()].add(purchaseAmount);
        totalPurchased=totalPurchased.add(purchaseAmount);

        payable(_treasury).transfer(msg.value);

        emit WELDPurchased(_msgSender(), address(0), purchaseAmount);
    }


    /**
     * @notice Function for the administrator to withdraw token (except WELD)
     * @notice Withdrawals allowed only if there is no sale pending stage
     * @param ERC20token Address of ERC20 token to withdraw from the contract
     */
    function adminWithdrawERC20(address ERC20token) external onlyOwner{
        require(_treasury!=address(0), "Treasury has not been set");
        Stages current_stage = currentStage();
        require(current_stage==Stages.Ended, "Sale is not over");
        uint256 tokenBalance = IERC20Upgradeable(ERC20token).balanceOf(address(this));
        IERC20Upgradeable(ERC20token).safeTransfer(_treasury, tokenBalance);
    }

    /**
     * @notice Function for the administrator to withdraw ETH for refunds
     * @notice Withdrawals allowed only if there is no sale pending stage
     */
    function adminWithdraw() external onlyOwner{
        require(_treasury!=address(0), "Treasury has not been set");
        Stages current_stage = currentStage();
        require(current_stage!=Stages.Ended, "Sale is not over");
        require(address(this).balance > 0, "Nothing to withdraw");
        (bool success, ) = _treasury.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Returns WELD amount for 1 external token
     * @param _token External toke (DAI, USDT, NUX, 0 address for ETH)
     */
    function rateForToken(address _token) external view returns(uint256) {
        if (_token == address(0)) {
            return _calcEthPurchaseAmount(10**18);
        }
        else {
            return _calcPurchaseAmount(_token, 10**( uint256(IERC20Detailed(_token).decimals()) ));
        }
    }

    /***
     * VESTING INTERFACE
     ***/

    /**
     * @notice Transfers available for claim vested tokens to the user.
     */
 
    function claim() external {
        require(vestingStart!=0, "Vesting has not been started");
        uint256 unclaimed = claimable(_msgSender());
        require(unclaimed > 0, "TokenVesting: no tokens are due");

        _claimed[_msgSender()] = _claimed[_msgSender()].add(unclaimed);
        IERC20Upgradeable(WELDToken).safeTransfer(_msgSender(), unclaimed);
        emit TokensClaimed(_msgSender(), unclaimed);
    }

    /**
     * @notice Gets the amount of tokens the user has already claimed
     * @param _user Address of the user who purchased tokens
     * @return The amount of the token claimed.
     */
    function claimed(address _user) external view returns (uint256) {
        return _claimed[_user];
    }

    /**
     * @notice Calculates the amount that has already vested but hasn't been claimed yet.
     * @param _user Address of the user who purchased tokens
     * @return The amount of the token vested and unclaimed.
     */
    function claimable(address _user) public view returns (uint256) {
        return _vestedAmount(_user).sub(_claimed[_user]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param _user Address of the user who purchased tokens
     * @return Amount of WELD already vested
     */
    function _vestedAmount(address _user) private view returns (uint256) {
        if (block.timestamp >= vestingStart.add(vestingDuration)) {
            return purchased[_user];
        } else {
            uint allowed = purchased[_user].mul(15).div(100);
            uint vested = purchased[_user]-allowed;
            return allowed.add(vested.mul(block.timestamp.sub(vestingStart)).div(vestingDuration));
        }
    }

     /**
    * @dev Checks current stage
    * @return Current stage
     */ 
    function currentStage() public view returns(Stages){
        if(block.timestamp>=stages[stages_count-1].stage_end){
             return Stages.Ended;
        }
        for(uint i=0; i<stages.length; i++){
            if(block.timestamp<stages[i].stage_end && block.timestamp>=stages[i].stage_start){
                return Stages(i);
            }
        }
        return Stages.None;
    }

    /***
     * INTERNAL HELPERS
     ***/

   

    /**
     * @dev Checks if public sale stage is over.
     * @return True is public sale is over
     */

    /**
     * @dev Calculates WELD amount based on rate and token.
     * @param _token Supported ERC20 token
     * @param _amount Token amount to convert to WELD
     * @return WELD amount
     */
    function _calcPurchaseAmount(address _token, uint256 _amount) private view returns (uint256) {
        uint256 purchaseAmount = _amount.mul(rates[_token]).div(PRECISION);
        require(purchaseAmount > 0, "Rates not set");

        uint8 _decimals = IERC20Detailed(_token).decimals();
        if (_decimals < 18) {
            purchaseAmount = purchaseAmount.mul(10 ** (18 - uint256(_decimals)));
        }
        return purchaseAmount;
    }

    /**
     * @dev Calculates WELD amount based on rate and ETH amount.
     * @param _amount ETH amount to convert to WELD
     * @return WELD amount
     */
    function _calcEthPurchaseAmount(uint256 _amount) private view returns (uint256) {
        uint256 purchaseAmount = _amount.mul(ETHRate).div(PRECISION);
        require(purchaseAmount > 0, "Rates not set");
        return purchaseAmount;
    }

    /**
     * @dev Checks if currently purchased amount does not reach cap per wallet.
     * @param purchaseAmount WELD tokens currently purchased
     */
    function _checkCapReached(uint256 purchaseAmount) private view {
        Stages current_stage = currentStage();
        require(purchaseAmount.add(purchasedAtStage[uint(current_stage)][msg.sender]) <= maxTokensAmount, "Maximum allowed exceeded");
    }


}