// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract Boopsy is IERC20 {

    using ZeppelinSafeMath for uint256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    string public constant name = "Boopsy";
    string public constant symbol = "BOOP";
    uint256 public constant decimals = 9;

    uint256 private constant MIN_INCREASE_RATE = 1;
    uint256 private constant MAX_INCREASE_RATE = 5;
    uint256 private constant TOKENS = 10**decimals;
    uint256 private constant MILLION = 10**6;
    uint256 private constant INITIAL_TOKEN_SUPPLY = 5 * MILLION * TOKENS;
    uint256 private constant MAX_TOKEN_SUPPLY = 100 * MILLION * TOKENS;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant TOTAL_GRAINS = MAX_UINT256 - (MAX_UINT256 % MAX_TOKEN_SUPPLY);
    uint256 private constant ONE_DAY_SECONDS = 1 days;

    uint256 public _epoch;
    uint256 public _rate;
    uint256 public _totalTokenSupply;
    uint256 public _uniqueHolderCount;
    uint256 public _uniqueHolderCountAtLastRebase;
    uint256 public _nextRebaseTimestamp;
    uint256 public _grainsPerToken;
    uint256 public _startingTimestamp;
    bool public _distributionEraComplete;

    IUniswapV2Pair public _wethPair;

    mapping(address => uint256) private _grainBalances;
    mapping(address => mapping (address => uint256)) private _allowedTokens;

    constructor(address uniswapFactoryAddress, address wethAddress, uint256 startingTimestamp) public override {
        require(uniswapFactoryAddress != address(0), "Uniswap factory address should be set");
        require(wethAddress != address(0), "Uniswap factory address should be set");

        // No need to check if pair exists since it cannot exist before this token is created
        IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(uniswapFactoryAddress);
        _wethPair = IUniswapV2Pair(uniswapV2Factory.createPair(address(this), wethAddress));

        _grainBalances[msg.sender] = TOTAL_GRAINS;
        _totalTokenSupply = INITIAL_TOKEN_SUPPLY;
        _grainsPerToken = TOTAL_GRAINS.div(_totalTokenSupply);

        _epoch = 0;
        _uniqueHolderCount = 1;
        _uniqueHolderCountAtLastRebase = 1;
        _startingTimestamp = startingTimestamp;
        _nextRebaseTimestamp = startingTimestamp.add(ONE_DAY_SECONDS);
        _rate = MAX_INCREASE_RATE;
        _distributionEraComplete = false;

        emit Transfer(address(0), msg.sender, _totalTokenSupply);
    }


    function rebase() public returns (uint256) {
        if (_distributionEraComplete) return _totalTokenSupply;
        if (block.timestamp < _nextRebaseTimestamp) return _totalTokenSupply;


        if (_uniqueHolderCount > _uniqueHolderCountAtLastRebase) {
            _increaseHolderBalances();
            _reduceRate();
        } else {
            _increaseRate();
        }

        _uniqueHolderCountAtLastRebase = _uniqueHolderCount;
        _nextRebaseTimestamp = block.timestamp.add(ONE_DAY_SECONDS);
        emit LogRebase(_epoch++, _totalTokenSupply);

        _sync();

        return _totalTokenSupply;
    }

    function _sync() internal {
        // UniswapV2 will allow anybody to call skim(address to) on any pair for sending
        // any excess (newly rewarded) tokens to the "to" address.
        // To prevent this, we need to call sync() while performing the rebase
        // to have the pair balances reset properly and prevent any skimming.
        // Only the WETH/BOOP pair is supported, any other Uniswap BOOP pairs
        // can have the excess balances skimmed so should not be used.
        // Centralized exchanges should monitor the LogRebase event and adjust
        // balances accordingly.
        _wethPair.sync();
    }

    function _increaseHolderBalances() internal returns (uint256) {
        uint256 amountToIncrease = _totalTokenSupply.mul(_rate).div(100);
        _totalTokenSupply = _totalTokenSupply.add(amountToIncrease);
        if (_totalTokenSupply >= MAX_TOKEN_SUPPLY) {
            _totalTokenSupply = MAX_TOKEN_SUPPLY;
            _distributionEraComplete = true;
        }
        _grainsPerToken = TOTAL_GRAINS.div(_totalTokenSupply);
    }

    function _reduceRate() internal {
        if (_rate > MIN_INCREASE_RATE) {
            _rate = _rate.sub(1);
        }
        if (_rate < MIN_INCREASE_RATE) {
            _rate = MIN_INCREASE_RATE;
        }
    }

    function _increaseRate() internal {
        if (_rate < MAX_INCREASE_RATE) {
            _rate = _rate.add(1);
        }
        if (_rate > MAX_INCREASE_RATE) {
            _rate = MAX_INCREASE_RATE;
        }
    }

    function totalSupply() public override view returns (uint256) {
        return _totalTokenSupply;
    }

    function balanceOf(address who) public override view returns (uint256) {
        return _grainBalances[who].div(_grainsPerToken);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(value > 0, "Cannot send 0");
        uint256 grainValue = _getGrainValue(msg.sender, value);
        _grainBalances[msg.sender] = _grainBalances[msg.sender].sub(grainValue);
        _grainBalances[to] = _grainBalances[to].add(grainValue);
        _onTransfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(value > 0, "Cannot send 0");
        _allowedTokens[from][msg.sender] = _allowedTokens[from][msg.sender].sub(value);

        uint256 grainValue = _getGrainValue(from, value);
        _grainBalances[from] = _grainBalances[from].sub(grainValue);
        _grainBalances[to] = _grainBalances[to].add(grainValue);
        // This is not required for the ERC20 spec, but will help clients
        // monitor current approvals by just monitoring Approval events.
        emit Approval(from, msg.sender, _allowedTokens[from][msg.sender]);
        _onTransfer(from, to, value);
        return true;
    }

    function _getGrainValue(address from, uint256 value) internal returns (uint256) {
        if (balanceOf(from) == value) {
            // Sometimes there is a slight rounding error which doesn't normally make a big difference
            // However when trying to send all coins from one account to another, we need to
            // make sure we sweep all the grains
            return _grainBalances[from];
        }
        return value.mul(_grainsPerToken);
    }

    function _onTransfer(address from, address to, uint256 value) internal {
        if (balanceOf(from) == 0) {
            _uniqueHolderCount = _uniqueHolderCount.sub(1);
        }
        if (balanceOf(to) == value) {
            _uniqueHolderCount = _uniqueHolderCount.add(1);
        }
        emit Transfer(from, to, value);
    }

    function allowance(address owner_, address spender) public override view returns (uint256) {
        return _allowedTokens[owner_][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _allowedTokens[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowedTokens[msg.sender][spender] = _allowedTokens[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedTokens[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = _allowedTokens[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedTokens[msg.sender][spender] = 0;
        } else {
            _allowedTokens[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedTokens[msg.sender][spender]);
        return true;
    }
}
