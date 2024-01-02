// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
            BETBUDDY BOT

    TG: t.me/BetBuddyPortal
    Website: https://betbuddy.bot/
    Twitter https://twitter.com/BetBuddyBot
 */


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



pragma solidity ^0.8.0;


/**

 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: PoolBet.sol


pragma solidity ^0.8.0;



contract PoolBet is Ownable {
    struct Bet {
        uint matchId;
        uint optionQty;
        uint totalAmount;
        bool resolved;
        bool reverted;
        uint winnerOption;
        uint timestamp;
    }

    IERC20 public token;
    IERC20 public tokenCheck;
    uint public betCounter;
    mapping(address => uint) public userWinnings;
    mapping(uint => Bet) public bets;
    mapping(address => uint) public userEarnings;
    mapping(uint => mapping(address => uint)) amountByBetUser;
    mapping(uint => mapping(uint => uint)) amountByBetOption;
    mapping(uint => mapping(uint => address[])) addressesByBetOption;

    uint public maxAmountInTokens;
    uint public minTokenHoldingToPlay;

    event BetCreated(uint betId, uint matchId);
    event BetPlaced(uint betId, address indexed bettor, uint option, uint amount);
    event BetResolved(uint betId, uint winnerOption);

    constructor(IERC20 _token, IERC20 _tokenCheck, uint _maxAmountInTokens, uint _minTokenHoldingToPlay) {
        token = _token;
        tokenCheck = _tokenCheck;
        maxAmountInTokens = _maxAmountInTokens;
        minTokenHoldingToPlay = _minTokenHoldingToPlay;
    }

    function createBet(uint matchId, uint optionQty, uint timestamp) external onlyOwner returns (uint) {
        betCounter++;
        bets[betCounter] = Bet(matchId, optionQty, 0, false, false, 0, timestamp);
        emit BetCreated(betCounter, matchId);
        return betCounter;
    }

    function placeBet(uint betId, uint option, uint amount) external {
        require(bets[betId].matchId != 0, "Bet does not exist");
        require(!bets[betId].resolved, "Bet already resolved");
        require(amount > 0, "Amount has to be more than 0");
        require(block.timestamp < bets[betId].timestamp, "Bet Due");
        require(amount <= maxAmountInTokens, "Has to bet less value");
        require(tokenCheck.balanceOf(msg.sender) >= minTokenHoldingToPlay, "You need more tokens to play");

        token.transferFrom(msg.sender, address(this), amount);

        bets[betId].totalAmount += amount;
        amountByBetUser[betId][msg.sender] += amount;
        amountByBetOption[betId][option] += amount;
        addressesByBetOption[betId][option].push(msg.sender);

        emit BetPlaced(betId, msg.sender, option, amount);
    }

    function resolveBet(uint betId, uint winnerOption) external onlyOwner {
        require(bets[betId].matchId != 0, "Bet does not exist");
        require(!bets[betId].resolved, "Bet already resolved");

        bets[betId].resolved = true;
        bets[betId].winnerOption = winnerOption;
        uint totalEarnings = bets[betId].totalAmount - amountByBetOption[betId][winnerOption];

        uint256 walletCount = addressesByBetOption[betId][winnerOption].length;

        for (uint256 i = 0; i < walletCount; i++) {
            address user = addressesByBetOption[betId][winnerOption][i];
            uint256 userBalance = amountByBetUser[betId][user];
            uint userDividensDivident = userBalance * totalEarnings;
            userEarnings[user] += userDividensDivident / bets[betId].totalAmount;
            userEarnings[user] += userBalance;
            userWinnings[user] += userDividensDivident / bets[betId].totalAmount;
        }

        amountByBetOption[betId][winnerOption] = 0;

        emit BetResolved(betId, winnerOption);
    }

    function rollBackBet(uint betId) external onlyOwner {
        require(bets[betId].matchId != 0, "Bet does not exist");
        require(!bets[betId].resolved, "Bet already resolved");

        bets[betId].reverted = true;

        for (uint256 i = 0; i < bets[betId].optionQty; i++) {
            for (uint256 j=0; j < addressesByBetOption[betId][i].length; j++) 
            {
                address user = addressesByBetOption[betId][i][j];
                uint256 userBalance = amountByBetUser[betId][user];
                userEarnings[user] += userBalance;
            }
        }

    }

    function claimDividends() public {
        uint256 claimedAmount = userEarnings[msg.sender];
        require(claimedAmount > 0, "No dividends to claim");
        bool approve_done = token.approve(address(this), claimedAmount);
        require(approve_done, "CA cannot approve tokens");
        token.transferFrom(address(this), msg.sender, claimedAmount);
        userEarnings[msg.sender] = 0;
    }

    function getAmountsByBetOption(uint _betId, uint _option) public view returns (uint) {
        return amountByBetOption[_betId][_option];
    }

    function setParameters (uint _maxAmountInTokens, uint _minTokenHoldingToPlay) onlyOwner public {
        maxAmountInTokens = _maxAmountInTokens;
        minTokenHoldingToPlay = _minTokenHoldingToPlay;
    }

    function unstuck(uint256 _amount, address _addy) onlyOwner public {
        if (_addy == address(0)) {
            (bool sent,) = address(msg.sender).call{value: _amount}("");
            require(sent, "funds has to be sent");
        } else {
            bool approve_done = IERC20(_addy).approve(address(this), IERC20(_addy).balanceOf(address(this)));
            require(approve_done, "CA cannot approve tokens");
            require(IERC20(_addy).balanceOf(address(this)) > 0, "No tokens");
            IERC20(_addy).transfer(msg.sender, _amount);
        }
    }
}