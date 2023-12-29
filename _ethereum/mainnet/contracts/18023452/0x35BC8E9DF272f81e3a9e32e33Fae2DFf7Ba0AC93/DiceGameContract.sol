// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract DiceGameContract is Ownable {
    address public revenueWallet;
    IERC20 public bettingToken;
    IERC20 public WETH;
    uint256 public immutable minimumBet;
    uint256 public immutable revenueBps;

    constructor(
        address _bettingToken,
        address _WETH,
        uint256 _minimumBet,
        uint256 _revenueBps,
        address _revenueWallet
    ) {
        revenueWallet = _revenueWallet;
        revenueBps = _revenueBps;
        bettingToken = IERC20(_bettingToken);
        WETH = IERC20(_WETH);
        minimumBet = _minimumBet;
    }

    struct Game {
        uint256 minBet;
        uint256[] betAmounts;
        address[] players;
        bool inProgress;
        uint16 loser;
    }

    mapping(int64 => Game) public games;
    int64[] public activeTgGroups;

    event Bet(int64 tgChatId, address player, uint256 amount);
    event Win(int64 tgChatId, address player, uint256 amount);
    event Loss(int64 tgChatId, address player, uint256 amount);
    event Revenue(int64 tgChatId, uint256 amount);

    function isGameInProgress(int64 _tgChatId) public view returns (bool) {
        return games[_tgChatId].inProgress;
    }

    function removeTgId(int64 _tgChatId) internal {
        for (uint256 i = 0; i < activeTgGroups.length; i++) {
            if (activeTgGroups[i] == _tgChatId) {
                activeTgGroups[i] = activeTgGroups[activeTgGroups.length - 1];
                activeTgGroups.pop();
            }
        }
    }

    function newGame(
        int64 _tgChatId,
        uint256 _minBet,
        address[] memory _players,
        uint256[] memory _bets,
        bool useWETH
    ) public returns (uint256[] memory) {
        require(
            _players.length == _bets.length,
            "Players/bets length mismatch"
        );
        require(
            !isGameInProgress(_tgChatId),
            "There is already a game in progress"
        );

        uint256 betTotal = 0;
        for (uint16 i = 0; i < _bets.length; i++) {
            require(_bets[i] >= _minBet, "Bet is smaller than the minimum");
            betTotal += _bets[i];
        }

        IERC20 chosenToken = useWETH ? WETH : bettingToken;

        for (uint16 i = 0; i < _bets.length; i++) {
            require(
                chosenToken.allowance(_players[i], address(this)) >= _bets[i],
                "Not enough allowance"
            );
            bool isSent = chosenToken.transferFrom(
                _players[i],
                address(this),
                _bets[i]
            );
            require(isSent, "Funds transfer failed");

            emit Bet(_tgChatId, _players[i], _bets[i]);
        }

        Game memory g;
        g.minBet = _minBet;
        g.betAmounts = _bets;
        g.players = _players;
        g.inProgress = true;

        games[_tgChatId] = g;
        activeTgGroups.push(_tgChatId);

        return _bets;
    }

    function endGame(
        int64 _tgChatId,
        address _winner,
        bool usedWETH
    ) public onlyOwner {
        require(
            isGameInProgress(_tgChatId),
            "No game in progress for this Telegram chat ID"
        );

        Game storage g = games[_tgChatId];
        require(g.inProgress, "Game is not in progress");

        g.inProgress = false;
        removeTgId(_tgChatId);

        uint256 totalBets = 0;
        for (uint16 i = 0; i < g.betAmounts.length; i++) {
            totalBets += g.betAmounts[i];
        }

        uint256 revenueShare = (totalBets * revenueBps) / 10000; // Calculate revenue share
        uint256 winnings = totalBets - revenueShare;

        IERC20 chosenToken = usedWETH ? WETH : bettingToken;

        // Transfer winnings to the winner
        chosenToken.transfer(_winner, winnings);
        emit Win(_tgChatId, _winner, winnings);

        // Transfer revenue share to the revenue wallet (funding wallet)
        chosenToken.transfer(revenueWallet, revenueShare);
        emit Revenue(_tgChatId, revenueShare);
    }

    function abortGame(int64 _tgChatId, bool usedWETH) public onlyOwner {
        require(
            isGameInProgress(_tgChatId),
            "No game in progress for this Telegram chat ID"
        );
        Game storage g = games[_tgChatId];

        IERC20 chosenToken = usedWETH ? WETH : bettingToken;

        for (uint16 i = 0; i < g.players.length; i++) {
            bool isSent = chosenToken.transfer(g.players[i], g.betAmounts[i]);
            require(isSent, "Funds transfer failed");
        }

        g.inProgress = false;
        removeTgId(_tgChatId);
    }

    function abortAllGames(bool usedWETH) public onlyOwner {
        int64[] memory _activeTgGroups = activeTgGroups;
        for (uint256 i = 0; i < _activeTgGroups.length; i++) {
            abortGame(_activeTgGroups[i], usedWETH);
        }
    }

    function setBettingToken(address _newBettingToken) public onlyOwner {
        require(_newBettingToken != address(0), "Invalid token address");
        bettingToken = IERC20(_newBettingToken);
    }

    function setrevenueWallet(address _revenueWallet) public onlyOwner {
        revenueWallet = address(_revenueWallet);
    }

    function setWETH(address _newWETH) public onlyOwner {
        require(_newWETH != address(0), "Invalid token address");
        WETH = IERC20(_newWETH);
    }

    function emergencyWithdrawERC20(address tokenAddress, address to)
        external
        onlyOwner
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "No tokens to withdraw");

        token.transfer(to, tokenBalance);
    }

    function emergencyWithdrawEther(address payable to) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No Ether to withdraw");

        (bool success, ) = to.call{value: contractBalance}("");
        require(success, "Withdraw failed");
    }
}