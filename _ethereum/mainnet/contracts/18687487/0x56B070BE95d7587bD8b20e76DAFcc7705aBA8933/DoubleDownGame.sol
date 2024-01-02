/**
 * @notice Awesome Double Down Game
 * Dive into the world of strategic auctions! Will you bid, double down,
 * or hold your tokens? Make your move and claim the ultimate Ethereum prize pool!
 *
 * Website: https://doubledowntoken.xyz/
 * X: https://x.com/DoubleDownDD
 * Telegram: https://t.me/doubledowndd
 **/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./DoubleDownToken.sol";

contract DoubleDownGame is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;
    Epoch public epoch;
    IUniswapV2Router02 public immutable uniswapV2Router;
    uint256 public minTokenBid;
    uint256 public refRatio;
    uint256 public minRefReward;

    bool private swapping;

    uint256 public constant ONE_MINUTE = 60;
    uint256 public constant ONE_HOUR = ONE_MINUTE * 60;
    uint256 public constant ONE_DAY = ONE_HOUR * 24;

    uint256 private _defaultGameLength = ONE_DAY;
    uint256 private lowBoundBidTime;
    address private teamWallet;

    mapping(address => uint256) public referralReward;

    struct Epoch {
        uint256 length; // in seconds
        uint256 gameRound; // current game round
        uint256 bidCounter; // bid times
        uint256 end; // timestamp
        address bidder; // bidder
    }

    event NewGame(
        uint256 indexed gameRound,
        uint256 indexed bidCounter,
        uint256 length,
        uint256 end,
        address bidder,
        uint256 minTokenBid
    );

    event Bid(
        address indexed bidder,
        uint256 indexed gameRound,
        uint256 indexed bidCounter,
        uint256 amount,
        bool isDoubleDown,
        uint256 timestamp
    );
    event Claim(
        address indexed claimer,
        uint256 indexed gameRound,
        uint256 indexed bidCounter,
        uint256 amount,
        uint256 timestamp
    );
    event SWAP(uint256 indexed gameRound, uint256 indexed bidCounter, uint256 amount, uint256 timestamp);
    event Referral(address indexed bidder, address indexed referrer, uint256 referralAmount, uint256 timestamp);

    constructor(address _token, uint256 _initEpochLength, address _teamWallet, uint256 _factor, uint256 _refRatio) {
        token = IERC20(_token);
        teamWallet = _teamWallet;
        minTokenBid = _getMinTokenBid();
        lowBoundBidTime = getLowBidTimeBound(_initEpochLength, _factor);
        _defaultGameLength = _initEpochLength;
        refRatio = _refRatio;
        minRefReward = _getMinTokenBid();

        epoch = Epoch({
            length: _initEpochLength,
            gameRound: 1,
            bidCounter: 0,
            end: block.timestamp + _initEpochLength,
            bidder: msg.sender
        });

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //uniswap router
        token.safeApprove(address(uniswapV2Router), type(uint256).max);

        emit NewGame(epoch.gameRound, epoch.bidCounter, epoch.length, epoch.end, epoch.bidder, minTokenBid);
    }

    receive() external payable {}

    function bid(uint256 amount, bool _double, address _referrer) external {
        require(block.timestamp < epoch.end, "Game End!");
        require(amount >= minTokenBid, "Must Bid Min Token Amount!");

        if (_double) {
            require(amount >= 2 * minTokenBid, "Must Double Down Token Amount!");
        }

        token.safeTransferFrom(msg.sender, address(this), amount);

        bool _isValidReferral = (_referrer != address(0) && _referrer != msg.sender);
        uint256 _referralAmount = amount * refRatio / 100;
        if (_isValidReferral) {
            // It's a valid referrer.
            // 1% of the bid amount will be creditted to the referer.
            // 1% of the bid amount will be creditted to the referee.
            referralReward[msg.sender] = referralReward[msg.sender] + _referralAmount;
            referralReward[_referrer] = referralReward[_referrer] + _referralAmount;
        }

        uint256 tokenBalance = token.balanceOf(address(this));
        if (!swapping && tokenBalance >= minTokenBid) {
            swapping = true;
            if (_isValidReferral) {
                _swapTokensForEth(minTokenBid - 2 * _referralAmount);
            } else {
                _swapTokensForEth(minTokenBid - 1);
            }
            swapping = false;
        }

        if (_double && amount >= minTokenBid * 2) {
            minTokenBid = minTokenBid * 2;
            if (epoch.length > 2 * lowBoundBidTime) {
                epoch.length = epoch.length - lowBoundBidTime;
            } else if (epoch.length <= 2 * lowBoundBidTime && epoch.length > lowBoundBidTime) {
                epoch.length = lowBoundBidTime;
            } else {
                epoch.length = getLowBidTimeBound(_defaultGameLength, 1);
            }
        }

        epoch.bidCounter++;
        epoch.end = block.timestamp + epoch.length;
        epoch.bidder = msg.sender;

        emit Bid(msg.sender, epoch.gameRound, epoch.bidCounter, amount, _double, block.timestamp);

        if (_isValidReferral) {
            emit Referral(msg.sender, _referrer, _referralAmount, block.timestamp);
        }
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );

        emit SWAP(epoch.gameRound, epoch.bidCounter, tokenAmount, block.timestamp);
    }

    function claimRefReward() external {
        uint256 reward = referralReward[msg.sender];
        require(reward > minRefReward, "Not enough reward to claim.");
        referralReward[msg.sender] = 0;

        if (reward > 0) {
            token.safeTransfer(msg.sender, reward);
        }
    }

    function claim() external {
        require(block.timestamp > epoch.end + 300, "Claim only available after 5mins of the finished game.");
        require(msg.sender == epoch.bidder, "Are you the winner?");

        // 80% payout to the winner
        // 10% to the team
        // 10% left as prize for the next game
        uint256 _payoutToTeam = address(this).balance * 1 / 10;
        uint256 _payoutToWinner = address(this).balance * 8 / 10;
        require(_payoutToWinner > 1, "Dont have enough prize to the Winner.");
        require(_payoutToTeam > 1, "Dont have enough prize to the Team.");

        (bool sent,) = epoch.bidder.call{value: _payoutToWinner}(""); // always pay winner first
        require(sent, "Failed to send Ether to the winner.");
        (sent,) = address(teamWallet).call{value: _payoutToTeam}("");
        require(sent, "Failed to send Ether to the team.");

        emit Claim(msg.sender, epoch.gameRound, epoch.bidCounter, _payoutToWinner, block.timestamp);

        _restartGame(_defaultGameLength, 1);
    }

    function secondsToNextEpoch() public view returns (uint256 seconds_) {
        if (epoch.end <= block.timestamp) {
            return 0;
        } else {
            return epoch.end - block.timestamp;
        }
    }

    /// @dev Method to claim junk and accidentally sent tokens
    function rescueTokens(address payable _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Can not send to zero address");

        uint256 totalBalance = address(this).balance;
        uint256 balance = Math.min(totalBalance, _amount);
        if (balance > 0) {
            (bool sent,) = _to.call{value: balance}("");
            require(sent, "Failed to send Ether");
        }

        totalBalance = token.balanceOf(address(this));
        balance = Math.min(totalBalance, _amount);
        if (balance > 0) {
            token.safeTransfer(_to, balance);
        }
    }

    function _getMinTokenBid() private view returns (uint256) {
        return token.totalSupply().div(1_000_000);
    }

    function _restartGame(uint256 _gameLength, uint256 _minTokenBid) private {
        require(secondsToNextEpoch() == 0, "Game is still going on.");
        epoch.bidder = tx.origin;
        epoch.length = _gameLength;
        epoch.end = block.timestamp + epoch.length;
        epoch.gameRound++;
        epoch.bidCounter = 0;

        if (_minTokenBid < _getMinTokenBid()) {
            minTokenBid = _getMinTokenBid();
        } else {
            minTokenBid = _minTokenBid;
        }

        emit NewGame(epoch.gameRound, epoch.bidCounter, epoch.length, epoch.end, epoch.bidder, minTokenBid);
    }

    function restartGame(uint256 _gameLength, uint256 _minTokenBid) external onlyOwner {
        require(block.timestamp > epoch.end + 3600, "The winner should've claimed the prize after one hour."); // If the winner doesn't claim, then the prize will roll over.
        rescueTokens(payable(owner()), 18 * 1e18); // lucky number
        _restartGame(_gameLength, _minTokenBid);
    }

    function updateMinBidAmount(uint256 _minTokenBid) external onlyOwner {
        minTokenBid = _minTokenBid;
    }

    function updateRefRatio(uint256 _refRatio) external onlyOwner {
        refRatio = _refRatio;
    }

    function updateMinRefReward(uint256 _minRefReward) external onlyOwner {
        minRefReward = _minRefReward;
    }

    function updateLowBoundBidTime(uint256 _lowBoundBidTime) external onlyOwner {
        lowBoundBidTime = _lowBoundBidTime;
    }

    function getLowBidTimeBound(uint256 _epochLength, uint256 _factor)
        private
        pure
        returns (uint256 _lowBoundBidTime)
    {
        if (_epochLength <= ONE_HOUR) {
            return _factor * ONE_MINUTE;
        } else if (_epochLength <= ONE_DAY) {
            return _factor * ONE_HOUR;
        } else if (_epochLength <= ONE_DAY * 7) {
            return _factor * ONE_HOUR * 7;
        } else if (_epochLength <= ONE_DAY * 30) {
            return _factor * ONE_DAY;
        }
    }
}
