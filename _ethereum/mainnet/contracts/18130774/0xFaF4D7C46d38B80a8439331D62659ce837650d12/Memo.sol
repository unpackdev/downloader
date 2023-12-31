// SPDX-License-Identifier: UNLICENSED

// $$\      $$\ $$$$$$$$\ $$\      $$\  $$$$$$\  
// $$$\    $$$ |$$  _____|$$$\    $$$ |$$  __$$\ 
// $$$$\  $$$$ |$$ |      $$$$\  $$$$ |$$ /  $$ |
// $$\$$\$$ $$ |$$$$$\    $$\$$\$$ $$ |$$ |  $$ |
// $$ \$$$  $$ |$$  __|   $$ \$$$  $$ |$$ |  $$ |
// $$ |\$  /$$ |$$ |      $$ |\$  /$$ |$$ |  $$ |
// $$ | \_/ $$ |$$$$$$$$\ $$ | \_/ $$ | $$$$$$  |
// \__|     \__|\________|\__|     \__| \______/ 
                                              
// https://getthememo.xyz
// https://twitter.com/0xFectious



pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
contract Memo is ERC20, Ownable {
    //Memo board variables
    struct MemoStruct {
        uint256 value;
        address sender;
        uint64 timestamp;
        uint8 index;
        string text;
    }
    uint256 public constant maxMemos = 10;
    uint256 public constant maxChars = 140;
    uint256 public memoLeaderValue;
    address public memoLeaderAddress;
    MemoStruct[maxMemos] public memos;

    // Token variables
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public teamWallet;

    uint256 public totalSupplyValue = 1_000_000 * 1e18;
    uint256 public maxTransactionAmount = 5_000 * 1e18; // 0.5%
    uint256 public maxWallet = 5_000 * 1e18; // 0.5% 
    uint256 public swapTokensAtAmount = (totalSupplyValue * 5) / 10000; // 0.05% 

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public constant totalFees = 4;
    uint256 public constant leaderFee = 3;
    uint256 public constant teamFee = 1;

    uint256 public tokensForLeader;
    uint256 public tokensForTeam;

    /******************/

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;


    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SetAutomatedMarketMakerPair(
        address indexed pair,
        bool indexed value
    );

    event newLeaderHasEmerged(
        address indexed newWallet,
        address indexed oldWallet
    );

    error IncorrectBoostTimeStamp();
    error MessageTooLong();
    error NoValue();

    constructor() ERC20("Memo", "MEMO") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D //mainnet
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        teamWallet = owner(); 

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[deadAddress] = true;

        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[deadAddress] = true;

        uint256 totalSupply = totalSupplyValue;
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to]) {
                fees = (amount * totalFees) / 100;
                tokensForTeam += (fees * teamFee) / totalFees;
                tokensForLeader += (fees * leaderFee) / totalFees;
            }
            else if (automatedMarketMakerPairs[from]) {
                fees = (amount * totalFees) / 100;
                tokensForTeam += (fees * teamFee) / totalFees;
                tokensForLeader += (fees * leaderFee) / totalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = 
            tokensForLeader +
            tokensForTeam;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 amountToSwapForETH = contractBalance;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance - initialETHBalance;
        uint256 ethForTeam = (ethBalance * tokensForTeam) / totalTokensToSwap ;

        tokensForLeader = 0;
        tokensForTeam = 0;

        (success, ) = address(teamWallet).call{value: ethForTeam}("");


        (success, ) = address(memoLeaderAddress).call{value: address(this).balance}("");
    }

    function withdrawStuckToken(address _token, address _to) external onlyOwner {
        require(_token != address(0));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function withdrawStuckEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{
            value: address(this).balance
        } ("");
        require(success);
    }



    //
    // memoboard functions
    //
    
    function sendMemo( string calldata _message, uint256 tokenValue) public {
        if (bytes(_message).length > maxChars) { revert MessageTooLong();}
        if (tokenValue == 0) { revert NoValue();}

        (bool qualifies, uint256 indexToRemove) = _getIndexToReplace(tokenValue);
        if (qualifies) {
            _insertMemo(
                msg.sender,
                _message,
                tokenValue,
                indexToRemove
            );
            if (tokenValue > memoLeaderValue) {
                memoLeaderValue = tokenValue;
                memoLeaderAddress = msg.sender;
            }
        } else {
            revert("message value too low");
        }
        _burn(msg.sender, tokenValue);
    }

    function boostMemo( uint8 memoIndex, uint64 memoTimestamp, uint256 boostValue) public  {
        MemoStruct memory memoToBoost = memos[memoIndex];
        if (memoToBoost.timestamp != memoTimestamp) { revert IncorrectBoostTimeStamp();}

        memoToBoost.value += boostValue;
        if (memoToBoost.value > memoLeaderValue) {
            memoLeaderValue = memoToBoost.value;
            memoLeaderAddress = msg.sender;
        }
        _burn(msg.sender, boostValue);
        memos[memoIndex] = memoToBoost;

    }

    function _getIndexToReplace(
        uint256 _value
    ) private view returns (bool qualifies, uint256 indexToRemove) {
        uint256 lowIndex;
        uint256 lowValue = memos[0].value;
        uint256 dripedValue;
        for (uint256 i = 0; i < maxMemos; i++) {
            dripedValue = memos[i].value;
            if (dripedValue < lowValue) {
                lowIndex = i;
                lowValue = dripedValue;
            }
            if (qualifies == false && _value > dripedValue) {
                qualifies = true;
            }
        }
        return (qualifies, lowIndex);
    }

    function _insertMemo(
        address _from,
        string calldata _message,
        uint256 _value,
        uint256 _index
    ) private {
        MemoStruct memory newMemo;
        newMemo.sender = _from;
        newMemo.timestamp = uint64(block.timestamp);
        newMemo.index = uint8(_index);
        newMemo.text = _message;
        newMemo.value = _value;
        memos[_index] = newMemo;
    }

    // should only be used offchain. 
    function getOrderedMemos()
        public
        pure
        returns (MemoStruct[maxMemos] memory)
    {
        MemoStruct[maxMemos] memory _memos;
        for (uint256 i = 1; i < maxMemos; i++) {
            for (uint256 j = 0; j < i; j++) {
                if (_memos[i].value > _memos[j].value) {
                    MemoStruct memory x = _memos[i];
                    _memos[i] = _memos[j];
                    _memos[j] = x;
                }
            }
        }
        return _memos;
    }
}