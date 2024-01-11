// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IHelixToken.sol";
import "./IFeeMinter.sol";
import "./FeeCollector.sol";
import "./Percent.sol";
import "./OwnableTimelockUpgradeable.sol";

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

/// Users (referrers) refer other users (referred) and referrers earn rewards when
/// referred users perform stakes or swaps
contract ReferralRegister is 
    FeeCollector, 
    Initializable, 
    OwnableUpgradeable, 
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableTimelockUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    IFeeMinter public feeMinter;

    /// Token distributed as referrer rewards
    address public helixToken;

    /// Reward percent for staker referrers
    uint256 public stakeRewardPercent;

    /// Reward percent for swap referrers
    uint256 public swapRewardPercent;

    /// Last block that reward tokens were minted
    uint256 public lastMintBlock;

    /// Accounts approved by the contract owner which can call the "record" functions
    EnumerableSetUpgradeable.AddressSet private _recorders;

    /// Referral fees are stored as: referred address => referrer address
    mapping(address => address) public referrers;

    /// referrer address => referred addresses
    mapping(address => address[]) public referees;

    /// Rewards balance of each referrer.
    mapping(address => uint256) public rewards;

    // Emitted when a referrer earns a reward because referred made a stake transaction
    event RewardStake(
        address indexed referrer,
        address indexed referred,
        uint256 indexed reward,
        uint256 stakeAmount
    );

    // Emitted when a referrer earns a reward because referred made a swap transaction
    event RewardSwap(
        address indexed referrer,
        address indexed referred,
        uint256 indexed reward,
        uint256 swapAmount
    );

    // Emitted when the stakeRewardPercent is set
    event SetStakeRewardPercent(address indexed setter, uint256 stakeRewardPercent);

    // Emitted when the swapRewardPercent is set
    event SetSwapRewardPercent(address indexed setter, uint256 stakeRewardPercent);

    // Emitted when a referred adds a referrer
    event AddReferrer(address referred, address referrer);

    // Emitted when a referred removes their referrer
    event ReferrerRemoved(address referred);

    // Emitted when a new feeMinter is set
    event SetFeeMinter(address indexed setter, address indexed feeMinter);

    // Emitted when a referrer withdraws their earned referral rewards
    event Withdraw(
        address indexed referrer,
        uint256 indexed referrerReward,
        uint256 indexed collectorFee,
        uint256 rewardBalance
    );

    // Emitted when the contract is updated and new tokens are minted
    event Update(uint256 minted);

    // Emitted when the lastMintBlock is manually set
    event SetLastRewardBlock(address indexed setter, uint256 lastMintBlock);

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "ReferralRegister: zero address");
        _;
    }

    modifier onlyRecorder() {
        require(isRecorder(msg.sender), "ReferralRegister: not a recorder");
        _;
    }

    function initialize(
        address _helixToken, 
        address _feeHandler,
        address _feeMinter,
        uint256 _stakeRewardPercent, 
        uint256 _swapRewardPercent,
        uint256 _lastMintBlock,
        uint256 _collectorPercent
    ) external initializer {
        __Ownable_init();
        __OwnableTimelock_init();
        __ReentrancyGuard_init();
        feeMinter = IFeeMinter(_feeMinter);
        _setFeeHandler(_feeHandler);
        _setCollectorPercentAndDecimals(_collectorPercent, 2); // Default to 2 decimals of precision

        helixToken = _helixToken;
        stakeRewardPercent = _stakeRewardPercent;
        swapRewardPercent = _swapRewardPercent;
        lastMintBlock = _lastMintBlock != 0 ? _lastMintBlock : block.number;
    }

    /// Reward _referred's referrer when _referred _stakeAmount
    function rewardStake(address _referred, uint256 _stakeAmount) 
        external 
        onlyRecorder 
        onlyValidAddress(_referred) 
    {
        address referrer = referrers[_referred];
        uint256 reward = _reward(referrer, _stakeAmount, stakeRewardPercent);
        emit RewardStake(referrer, _referred, reward, _stakeAmount);
    }

    /// Reward _referred's referrer when _referred _swapAmount
    function rewardSwap(address _referred, uint256 _swapAmount) 
        external 
        onlyRecorder 
        onlyValidAddress(_referred) 
    {
        address referrer = referrers[_referred];
        uint256 reward = _reward(referrer, _swapAmount, swapRewardPercent);
        emit RewardSwap(referrer, _referred, reward, _swapAmount);
    }

    /// Called by a referrer to withdraw their accrued rewards
    function withdraw() external whenNotPaused nonReentrant {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "ReferralRegister: nothing to withdraw");
        
        _update();

        uint256 contractBalance = IERC20Upgradeable(helixToken).balanceOf(address(this));
        require(contractBalance > 0, "ReferralRegister: no helix in contract");
    
        // Prevent withdrawing more than the contract balance
        reward = reward < contractBalance ? reward : contractBalance;

        // Update the referrer's reward balance
        rewards[msg.sender] -= reward;
    
        // Split the reward and extract the collector fee
        (uint256 collectorFee, uint256 referrerReward) = getCollectorFeeSplit(reward);
        if (referrerReward > 0) {
            IERC20Upgradeable(helixToken).safeTransfer(msg.sender, referrerReward);
        }
        if (collectorFee > 0) {
            _delegateTransfer(IERC20(helixToken), address(this), collectorFee);
        }

        emit Withdraw(msg.sender, referrerReward, collectorFee, rewards[msg.sender]);
    }

    /// Called by the owner to set the percent earned by referrers on stake transactions
    function setStakeRewardPercent(uint256 _stakeRewardPercent) external onlyTimelock {
        stakeRewardPercent = _stakeRewardPercent;
        emit SetStakeRewardPercent(msg.sender, _stakeRewardPercent);
    }

    /// Called by the owner to set the percent earned by referrers on swap transactions
    function setSwapRewardPercent(uint256 _swapRewardPercent) external onlyTimelock {
        swapRewardPercent = _swapRewardPercent;
        emit SetSwapRewardPercent(msg.sender, _swapRewardPercent);
    }

    /// Return the assigned toMintPerBlock rate
    function getToMintPerBlock() external view returns (uint256) {
        return _getToMintPerBlock();
    }

    /// Set the caller's (referred's) referrer
    function addReferrer(address _referrer) external {
        require(referrers[msg.sender] == address(0), "ReferralRegister: referrer already set");
        require(msg.sender != _referrer, "ReferralRegister: no self referral");
        referrers[msg.sender] = _referrer;
        referees[_referrer].push(msg.sender);
        emit AddReferrer(msg.sender, _referrer);
    }

    function getReferees(address _referrer) view external returns (address[] memory) {
        return referees[_referrer];
    }

    /// Remove the caller's referrer
    function removeReferrer() external {
        referrers[msg.sender] = address(0);
        emit ReferrerRemoved(msg.sender);
    }

    /// Mint new reward tokens to the contract according to the mint rate
    function update() external nonReentrant {
        _update();
    }

    // Mint new helix tokens to the contract according to the mint rate
    function _update() private {
        if (block.number <= lastMintBlock) {
            return;
        }      

        uint256 toMint = (block.number - lastMintBlock) * _getToMintPerBlock();
        lastMintBlock = block.number;

        IHelixToken(helixToken).mint(address(this), toMint);
        emit Update(toMint);
    }
    
    /// Called by the owner to register a new recorder
    function addRecorder(address _recorder) external onlyOwner onlyValidAddress(_recorder) returns (bool) {
        return EnumerableSetUpgradeable.add(_recorders, _recorder);
    }
    
    /// Called by the owner to remove a recorder
    function removeRecorder(address _recorder) external onlyOwner onlyValidAddress(_recorder) returns (bool) {
        return EnumerableSetUpgradeable.remove(_recorders, _recorder);
    }
    
    /// Called by the owner to set the _lastMintBlock
    function setLastRewardBlock(uint256 _lastMintBlock) external onlyOwner {
        lastMintBlock = _lastMintBlock;
        emit SetLastRewardBlock(msg.sender, _lastMintBlock);
    }

    /// Called by owner to pause contract
    function pause() external onlyOwner {
        _pause();
    }

    /// Called by owner to unpause contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// Called by owner to set feeHandler address
    function setFeeHandler(address _feeHandler) external onlyTimelock {
        _setFeeHandler(_feeHandler);
    }

    /// Called by owner to set _feeMinter address
    function setFeeMinter(address _feeMinter) external onlyTimelock {
        feeMinter = IFeeMinter(_feeMinter);
        emit SetFeeMinter(msg.sender, _feeMinter);
    }
   
    /// Called by the owner to set the percent charged on withdrawals
    function setCollectorPercentAndDecimals(uint256 _collectorPercent, uint256 _decimals) 
        external 
        onlyTimelock 
    {
        _setCollectorPercentAndDecimals(_collectorPercent, _decimals);
    }

    /// Return the address of the recorder at _index
    function getRecorder(uint256 _index) external view returns (address) {
        require(_index <= getRecorderLength() - 1, "ReferralRegister: index out of bounds");
        return EnumerableSetUpgradeable.at(_recorders, _index);
    }

    /// Return number of recorders.
    function getRecorderLength() public view returns (uint256) {
        return EnumerableSetUpgradeable.length(_recorders);
    }

    /// Return true if _address is a recorder and false otherwise
    function isRecorder(address _address) public view returns (bool) {
        return EnumerableSetUpgradeable.contains(_recorders, _address);
    }

    // Return the toMintPerBlock rate of this contract
    function _getToMintPerBlock() private view returns (uint256) {
        require(address(feeMinter) != address(0), "ReferralRegister: fee minter is unassigned");
        return feeMinter.getToMintPerBlock(address(this));
    }

    // Reward _referred's referrer based on transaction _amount and _rate
    function _reward(address _referrer, uint256 _amount, uint256 _rate)
        private
        returns (uint256 reward)
    {
        reward = Percent.getPercentage(_amount, _rate);
        rewards[_referrer] += reward;
    }
}
