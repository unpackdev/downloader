// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: contracts/TestPresale.sol

//SPDX-License-Identifier: No

pragma solidity ^0.8.17;

//--- Context ---//
abstract contract Context {
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

//--- Pausable ---//
abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//--- Ownable ---//
abstract contract Ownable is Context {
    address private _owner;
    address private _multiSig;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event MultiSigTransferred(
        address indexed oldMultiSig,
        address indexed newMultiSig
    );

    constructor() {
        _setOwner(_msgSender());
        _setMultiSig(_msgSender());
    }

    function multisig() public view virtual returns (address) {
        return _multiSig;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(
            owner() == _msgSender() || multisig() == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    modifier onlyMultiSignature() {
        require(
            multisig() == _msgSender(),
            "Ownable: caller is not the multisig"
        );
        _;
    }
  

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function transferMultiSig(
        address newMultiSig
    ) public virtual onlyMultiSignature {
        require(
            newMultiSig != address(0),
            "Ownable: new owner is the zero address"
        );
        _setMultiSig(newMultiSig);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _setMultiSig(address newMultiSig) private {
        address oldMultiSig = _multiSig;
        _multiSig = newMultiSig;
        emit MultiSigTransferred(oldMultiSig, newMultiSig);
    }
}

//--- Interface for ERC20 ---//
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract VaultStaking3 is Context, Pausable, Ownable, ReentrancyGuard {
    event staking(uint256 amount);
    event WithdrawFromStaking(uint256 amount);
    event ClaimRewards(uint256 amount);
    mapping(address => uint256) public stakeTimestamps;
    uint256 public TokenDedicatiAlloStaking; // Modalità 1: Fixed amount of tokens staked.
    uint256 public safeSeconds = 15;
    uint256 public totalSupply; // amount of all token staked
    bool public isStakingLive = false;
    uint256 private dayzero;
    uint256 private preApproval;
    bool public Initalized = false;
    mapping(address => uint256) private rewardsGiaPagati;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private quandoStake;
    mapping(address => uint256) private quandoWithdraw;
    mapping(address => uint256) private lastTimeStaked;
    mapping(address => uint256) private holdingXstaking;
    mapping(address => uint256) private lastClaimRewards;

    mapping(address => bool) private AlreadyStaked;

    uint256 public interestperDay = 2_0500000000;
    uint256 public withdrawalLockDuration = 90 days;

    IERC20 public Token;

    function setToken(address _token) external onlyMultiSignature {
        require(!Initalized);
        Token = IERC20(_token);
        Initalized = true;
    }


      function manageToken(uint256 amount, address tokenAddress) public onlyOwner nonReentrant {
          uint256 contractBalance = IERC20(tokenAddress).balanceOf(address(this));
          require(contractBalance >= amount, "Ownable: contract does not have enough tokens");
          IERC20(tokenAddress).transfer(_msgSender(), amount);
      }

    function stakeForWallets(
        address[] memory _wallets,
        uint256[] memory _amounts
    ) external onlyOwner nonReentrant {
        require(_wallets.length == _amounts.length, "INSYNC");
        uint256 _totalAmount;
        for (uint256 _i; _i < _wallets.length; _i++) {
            _totalAmount += _amounts[_i];
            _setShare(_wallets[_i], _amounts[_i]);
            
        }
        IERC20(Token).transferFrom(_msgSender(), address(this), _totalAmount);
    }

    function _setShare(address wallet, uint256 balanceUpdate) internal {
        stakeprivate(wallet, balanceUpdate);
    }

function setInterestperDay(
    uint256 _interestperDay
) external onlyMultiSignature {
    require(_interestperDay > 0, "Interest per day must be greater than 0");
    interestperDay = _interestperDay;
}
    function unPause() external onlyMultiSignature {
        _unpause();
    }

    function setTokenDedicatiAlloStaking(uint256 amount) external onlyOwner {
        uint256 tempBalance = Token.balanceOf(msg.sender); //
        require(tempBalance >= amount, "Not enough tokens"); //
        Token.transferFrom(msg.sender, address(this), amount); // make sure to give enough allowance
        TokenDedicatiAlloStaking += amount;
    }

    function setStakingLive() external onlyOwner {
        require(!isStakingLive, "Staking is already live");
        isStakingLive = true;
    }

    function stakeprivate(address wallet, uint256 amount) private {
        bool YesNoStaked = AlreadyStaked[wallet] == true;
        if (YesNoStaked) {
            if (pend(msg.sender) >= holdingXstaking[msg.sender] / 1000) {
                revert(
                    "Claim Rewards, you have at least 0.1% rewards to claim"
                );
            }
        } else {
            stakeTimestamps[wallet] = block.timestamp;
        }

        uint256 tempBalance = Token.balanceOf(msg.sender);
        require(isStakingLive, "Staking is not live");
        require(tempBalance >= amount, "Not enough tokens");
        Token.transferFrom(msg.sender, address(this), amount);
        holdingXstaking[wallet] += amount;
        totalSupply += amount;
        quandoStake[wallet] = block.timestamp; // Quando stake in secondi. https://www.site24x7.com/tools/time-stamp-converter.html
        AlreadyStaked[wallet] = true;
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(msg.sender != address(0));
        require(isStakingLive, "Staking is not live yet.");
        stakeprivate(msg.sender, amount);
        emit staking(amount);
    }

    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        require(msg.sender != address(0));
        require(amount > 0, "Amount should be greater than 0");
        require(holdingXstaking[msg.sender] >= amount, "Not enough tokens");

        uint256 lockDuration = block.timestamp - stakeTimestamps[msg.sender];
        require(
            lockDuration >= withdrawalLockDuration,
            "Cant withdraw until lock"
        );

        holdingXstaking[msg.sender] -= amount;
        totalSupply -= amount;

        // Transfer the full amount to the user's wallet
        Token.transfer(msg.sender, amount);

        quandoWithdraw[msg.sender] = block.timestamp;
        bool goingToZero = holdingXstaking[msg.sender] == 0;
        if (goingToZero) {
            resetUser();
        }

        emit WithdrawFromStaking(amount);
    }
  

    function resetUser() private {
        AlreadyStaked[msg.sender] = false;
        rewards[msg.sender] = 0;
        rewardsGiaPagati[msg.sender] = 0;
        lastClaimRewards[msg.sender] = 0;
        quandoStake[msg.sender] = 0;
        holdingXstaking[msg.sender] = 0;
        stakeTimestamps[msg.sender] = 0;
    }

    function calculateRewards() private {
        uint256 interestPerSecond = interestperDay / 86400;
        uint256 interest = (block.timestamp - quandoStake[msg.sender]) *
            interestPerSecond;
        rewards[msg.sender] = (holdingXstaking[msg.sender] * interest);
        rewards[msg.sender] = checkZeroMath(msg.sender, rewards[msg.sender]);
    }

    function safe() private view whenNotPaused {
        require(
            block.timestamp > lastClaimRewards[msg.sender] + safeSeconds,
            "Cannot claim in the sameblock"
        );
    }

    function staked() private view {
        bool YesNoStaked = AlreadyStaked[msg.sender] == true;
        if (YesNoStaked) {} else {
            safe();
        }
    }

    function claimReward() external nonReentrant whenNotPaused {
        require(msg.sender != address(0));
        calculateRewards();
        staked();

        require(rewards[msg.sender] > 0, "Can't claim less than zero tokens");

        uint256 yourrewards = rewards[msg.sender];

        Token.transfer(msg.sender, yourrewards);
        rewardsGiaPagati[msg.sender] += yourrewards;
        lastClaimRewards[msg.sender] = block.timestamp;
        require(
            TokenDedicatiAlloStaking > yourrewards,
            "Token Holders need to be able to get back 100% of the tokens allocated"
        );
        TokenDedicatiAlloStaking -= yourrewards;

        emit ClaimRewards(yourrewards);
    }

    function amountStaked(address holder) external view returns (uint256) {
        return holdingXstaking[holder];
    }

    function rewardsPaid(address holder) external view returns (uint256) {
        return rewardsGiaPagati[holder];
    }

    function whenStaking(address holder) external view returns (uint256) {
        return quandoStake[holder];
    }

    function lastTimeClaim(address holder) external view returns (uint256) {
        return lastClaimRewards[holder];
    }

    function _alreadyStaked(address holder) external view returns (bool) {
        return AlreadyStaked[holder];
    }

    function pend(address account) private view returns (uint256) {
        uint256 interestPerSecond = interestperDay / 86400;
        uint256 interest = (block.timestamp - quandoStake[account]) *
            interestPerSecond;
        uint256 preRewards;
        preRewards = (holdingXstaking[account] * interest);
        preRewards = checkZeroMath(account, preRewards);
        return preRewards;
    }

    function checkZeroMath(
        address account,
        uint256 a
    ) internal view returns (uint256) {
        uint256 _return;
        if (((a / 100000000000)) / 100 >= rewardsGiaPagati[account]) {
            _return = ((a / 100000000000)) / 100 - rewardsGiaPagati[account];
        } else {
            _return = 0;
        }
        return _return;
    }

    function pendingRewards(address account) external view returns (uint256) {
        return pend(account);
    }
}