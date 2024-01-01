/// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import "./OwnableUpgradeable.sol";
import "./Address.sol";
import "./Math.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";

/// @title PerpetualStaking
/// @custom:security-contact tech@brickken.com
contract PerpetualStaking is OwnableUpgradeable {
    using Math for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Instances of BKN
    IERC20Upgradeable public BKNToken;

    uint256 private constant ONE = 1000000000000000000; // 100 % 1e18

    // Auxiliary variables
    bool public isDepositable;
    bool public isClaimable;

    uint256 public minimumDepositTime; // 3 Months minimum stake
    uint256 public twelveMonthsPeriod; // 12 months
    uint256 public yieldPerYear; // 15% per year, 15e16
    uint256 public yieldPerSecond; // yieldPerYear / (365 * 24 * 60 * 60)
    uint256 public penalizationBeforeYear; // 66% penalization if exits before 12 months, 66e16
    
    /*
       In order to calculate solvency (the ability of the contract to pay everyone at once in any given moment)
       We need to find a formula that gives us the minimum balance that the contract should have at any moment.
       Let's define some variables:

       - d0_i -> The initial deposit of user i
       - t0_i -> Time at which user i deposited
       - yieldPerSecond -> yield generated for each second
       
       So we can write the solvency condition as dependant on any given time 't'

       S(t) = SUM (d0_i + d0_i * yieldPerSecond * (t - t0_i)) 
       
       Which represents the sum of all initial deposits plus the yielded amount for each user i

       And we can split into three components

       - SUM(d0_i) -> totalDeposited
       - SUM(yieldPerSecond * d0_i) -> tokensYieldPerSecond
       - SUM(yieldPerSecond * d0_i * t0_i) -> yieldUpToDeposit

       So that our formula becomes

       S(t) = totalDeposited + t * tokensYieldPerSecond - yieldUpToDeposit

       Whenever a new user deposit, totalDeposited, tokensYieldPerSecond and yieldUpToDeposit will increment
       Conversely, when an user exits the same variables will be reduced.
    */
    
    uint256 public totalDeposited;
    uint256 public tokensYieldPerSecond;
    uint256 public yieldUpToDeposit;

    struct UserStake {
        uint256 amountDeposited;
        uint256 latestDepositTimestamp;
    }

    mapping(address => UserStake) public userStakes;

    error DepositsAreClosed();
    error ClaimsAreClosed();
    error NotEnoughTimeStaked();
    error NotEnoughToClaim();
    error ContractHasNotEnoughBalance(uint256 claimingAmount, uint256 balance);
    error AlreadyDeposited(address user);

    /// @dev Gap variable for future upgrades
    uint256[37] __gap;

    modifier whenDepositable() {
        if(!isDepositable) revert DepositsAreClosed();
        _;
    }

    modifier whenClaimable() {
        if(!isClaimable) revert ClaimsAreClosed();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _BKN, address _owner) initializer() external {
        BKNToken = IERC20Upgradeable(_BKN);

        __Ownable_init_unchained();
        __Context_init_unchained();
        _transferOwnership(_owner);

        isClaimable = true;
        isDepositable = true;
        minimumDepositTime = 60*60*24*90; // 3 Months minimum stake
        twelveMonthsPeriod = 60*60*24*30*12; // 12 months
        yieldPerYear = 150000000000000000; // 15% per year, 15e16
        yieldPerSecond = yieldPerYear / (365 * 24 * 60 * 60); // yieldPerYear / (365 * 24 * 60 * 60)
        penalizationBeforeYear = 660000000000000000; // 66% penalization if exits before 12 months, 66e16
    }

    /**
     * @dev Receive fallback payable method. Don't accept ETH.
     */
    receive() external payable {
        assert(false);
    }

    function pauseDeposit() external onlyOwner {
        isDepositable = false;
    }

    function unpauseDeposit() external onlyOwner {
        isDepositable = true;
    }

    function pauseClaim() external onlyOwner {
        isClaimable = false;
    }

    function unpauseClaim() external onlyOwner {
        isClaimable = true;
    }

    function removeTokens(IERC20Upgradeable token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    function changeUserAddress(address from, address to) external onlyOwner {
        userStakes[to] = userStakes[from];
        delete userStakes[from];
    }

    function deposit(address user, uint256 amount) external whenDepositable {
        if(userStakes[user].amountDeposited > 0) revert AlreadyDeposited(user);
        BKNToken.safeTransferFrom(user, address(this), amount);

        userStakes[user].amountDeposited += amount;
        userStakes[user].latestDepositTimestamp = block.timestamp;
        
        // Adjust solvency accounting
        totalDeposited += amount;
        tokensYieldPerSecond += yieldPerSecond * amount;
        yieldUpToDeposit += yieldPerSecond * amount * block.timestamp;
    }

    // It simulates a claim, but it reassign the old deposit + yielded interests + any eventual amount passed in as new position
    function compoundAndDeposit(address user, uint256 amount) external whenDepositable {
        uint256 claimingAmount = getWithdrawableUserBalance(user);
        if(!(claimingAmount > 0)) revert NotEnoughToClaim();

        if(amount > 0) {
            BKNToken.safeTransferFrom(user, address(this), amount);
        }

        uint256 newTotalAmount = claimingAmount + amount;
        uint256 oldDepositedAmount = userStakes[user].amountDeposited;
        uint256 oldDepositedTimestamp = userStakes[user].latestDepositTimestamp;

        userStakes[user].amountDeposited = newTotalAmount;
        userStakes[user].latestDepositTimestamp = block.timestamp;

        // Adjust solvency by summing the new deposits values and removing the old ones next (to avoid underflows)

        totalDeposited += newTotalAmount;
        totalDeposited -= oldDepositedAmount;

        tokensYieldPerSecond += yieldPerSecond * newTotalAmount;
        tokensYieldPerSecond -= yieldPerSecond * oldDepositedAmount;

        yieldUpToDeposit += yieldPerSecond * newTotalAmount * userStakes[user].latestDepositTimestamp;
        yieldUpToDeposit -= yieldPerSecond * oldDepositedAmount * oldDepositedTimestamp;
    }

    function claim(address user) external whenClaimable {
        uint256 claimingAmount = getWithdrawableUserBalance(user);
        if(!(claimingAmount > 0)) revert NotEnoughToClaim();
    
        uint256 initialDeposit = userStakes[user].amountDeposited;

        // Adjust solvency accounting
        totalDeposited -= initialDeposit;
        tokensYieldPerSecond -= yieldPerSecond * initialDeposit;
        yieldUpToDeposit -= yieldPerSecond * initialDeposit * userStakes[user].latestDepositTimestamp;

        delete userStakes[user];

        if(claimingAmount > BKNToken.balanceOf(address(this)))
            revert ContractHasNotEnoughBalance(claimingAmount, BKNToken.balanceOf(address(this)));

        BKNToken.safeTransfer(user, claimingAmount);
    }

    function getTotalFundsNeeded() external view returns(uint256) {
        uint256 currentTime = block.timestamp;
        return totalDeposited + (currentTime * tokensYieldPerSecond) - yieldUpToDeposit;
    }

    function getWithdrawableUserBalance(address user) public view returns(uint256) {
        uint256 currentYieldingAmount = userStakes[user].amountDeposited;
        uint256 howManySecondsHavePassed = block.timestamp - userStakes[user].latestDepositTimestamp;
        
        if(currentYieldingAmount == 0 || howManySecondsHavePassed == 0) return currentYieldingAmount;

        uint256 percentageReward = howManySecondsHavePassed * yieldPerSecond;
        uint256 yieldedAmount = currentYieldingAmount.mulDiv(percentageReward, ONE);

        // Return non penalized amount
        return currentYieldingAmount + yieldedAmount;
    }
}