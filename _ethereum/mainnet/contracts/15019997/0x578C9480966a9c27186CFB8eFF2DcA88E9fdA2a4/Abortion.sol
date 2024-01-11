pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";


                                                                                                                                                                                                                                                           
//                                 bbbbbbbb                                                                                                                                                                                                                   
//                AAA              b::::::b                                                          tttt            iiii                                          TTTTTTTTTTTTTTTTTTTTTTT              kkkkkkkk                                              
//               A:::A             b::::::b                                                       ttt:::t           i::::i                                         T:::::::::::::::::::::T              k::::::k                                              
//              A:::::A            b::::::b                                                       t:::::t            iiii                                          T:::::::::::::::::::::T              k::::::k                                              
//             A:::::::A            b:::::b                                                       t:::::t                                                          T:::::TT:::::::TT:::::T              k::::::k                                              
//            A:::::::::A           b:::::bbbbbbbbb       ooooooooooo   rrrrr   rrrrrrrrr   ttttttt:::::ttttttt    iiiiiii    ooooooooooo   nnnn  nnnnnnnn         TTTTTT  T:::::T  TTTTTTooooooooooo    k:::::k    kkkkkkk eeeeeeeeeeee    nnnn  nnnnnnnn    
//           A:::::A:::::A          b::::::::::::::bb   oo:::::::::::oo r::::rrr:::::::::r  t:::::::::::::::::t    i:::::i  oo:::::::::::oo n:::nn::::::::nn               T:::::T      oo:::::::::::oo  k:::::k   k:::::kee::::::::::::ee  n:::nn::::::::nn  
//          A:::::A A:::::A         b::::::::::::::::b o:::::::::::::::or:::::::::::::::::r t:::::::::::::::::t     i::::i o:::::::::::::::on::::::::::::::nn              T:::::T     o:::::::::::::::o k:::::k  k:::::ke::::::eeeee:::::een::::::::::::::nn 
//         A:::::A   A:::::A        b:::::bbbbb:::::::bo:::::ooooo:::::orr::::::rrrrr::::::rtttttt:::::::tttttt     i::::i o:::::ooooo:::::onn:::::::::::::::n             T:::::T     o:::::ooooo:::::o k:::::k k:::::ke::::::e     e:::::enn:::::::::::::::n
//        A:::::A     A:::::A       b:::::b    b::::::bo::::o     o::::o r:::::r     r:::::r      t:::::t           i::::i o::::o     o::::o  n:::::nnnn:::::n             T:::::T     o::::o     o::::o k::::::k:::::k e:::::::eeeee::::::e  n:::::nnnn:::::n
//       A:::::AAAAAAAAA:::::A      b:::::b     b:::::bo::::o     o::::o r:::::r     rrrrrrr      t:::::t           i::::i o::::o     o::::o  n::::n    n::::n             T:::::T     o::::o     o::::o k:::::::::::k  e:::::::::::::::::e   n::::n    n::::n
//      A:::::::::::::::::::::A     b:::::b     b:::::bo::::o     o::::o r:::::r                  t:::::t           i::::i o::::o     o::::o  n::::n    n::::n             T:::::T     o::::o     o::::o k:::::::::::k  e::::::eeeeeeeeeee    n::::n    n::::n
//     A:::::AAAAAAAAAAAAA:::::A    b:::::b     b:::::bo::::o     o::::o r:::::r                  t:::::t    tttttt i::::i o::::o     o::::o  n::::n    n::::n             T:::::T     o::::o     o::::o k::::::k:::::k e:::::::e             n::::n    n::::n
//    A:::::A             A:::::A   b:::::bbbbbb::::::bo:::::ooooo:::::o r:::::r                  t::::::tttt:::::ti::::::io:::::ooooo:::::o  n::::n    n::::n           TT:::::::TT   o:::::ooooo:::::ok::::::k k:::::ke::::::::e            n::::n    n::::n
//   A:::::A               A:::::A  b::::::::::::::::b o:::::::::::::::o r:::::r                  tt::::::::::::::ti::::::io:::::::::::::::o  n::::n    n::::n           T:::::::::T   o:::::::::::::::ok::::::k  k:::::ke::::::::eeeeeeee    n::::n    n::::n
//  A:::::A                 A:::::A b:::::::::::::::b   oo:::::::::::oo  r:::::r                    tt:::::::::::tti::::::i oo:::::::::::oo   n::::n    n::::n           T:::::::::T    oo:::::::::::oo k::::::k   k:::::kee:::::::::::::e    n::::n    n::::n
// AAAAAAA                   AAAAAAAbbbbbbbbbbbbbbbb      ooooooooooo    rrrrrrr                      ttttttttttt  iiiiiiii   ooooooooooo     nnnnnn    nnnnnn           TTTTTTTTTTT      ooooooooooo   kkkkkkkk    kkkkkkk eeeeeeeeeeeeee    nnnnnn    nnnnnn

// Take the Pledge No matter where you live, you can join the fight and support our partners fighting for abortion rights. A good place to start? Take the pledge to show your support.
//Do Not ever give up the fight for womens rights!!

contract AbortionToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    IERC20 rocketToken;

    address public HelpWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyFee;
    uint256 public sellFee;

    uint256 public forBurn;
    uint256 public forHelp;
    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event AutoNukeLP();

    event ManualNukeLP();

    constructor(address _HelpWallet) ERC20("Abortion Token", "ABTN") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyFee = 6;
        uint256 _sellFee = 10;

        buyFee = _buyFee;
        sellFee = _sellFee;

        uint256 totalSupply = 69_000_000_000 * 1e18;

        maxWallet = 2_100_000_000 * 1e18; // 3% from total supply maxWallet
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% swap wallet

        HelpWallet = _HelpWallet; // set as Donation Wallet
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
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

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
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

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }


    function updateBuyFees(
        uint256 _buyFee
    ) external onlyOwner {
        buyFee = _buyFee;
        require(buyFee <= 6, "Must keep fees at 6% or less");
    }

    function updateSellFees(
        uint256 _sellFee
    ) external onlyOwner {
        sellFee = _sellFee;
        require(sellFee <= 15, "Must keep fees at 15% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "pair cannot be removed from automatedMarketMakerPairs"
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

    event BoughtEarly(address indexed sniper);

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

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
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

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 splitFee = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellFee > 0) {
                fees = amount.mul(sellFee).div(100);
                splitFee = sellFee / 2;
                forBurn += (fees * splitFee) / sellFee;
                forHelp += (fees * splitFee) / sellFee;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyFee > 0) {
                fees = amount.mul(buyFee).div(100);
                forBurn += fees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    //Convert fees into ETH
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
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = forHelp;
        bool success;

        if (contractTokenBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        //tokens to swap is too large set the amount lower 
        if (totalTokensToSwap > swapTokensAtAmount * 20) {
            totalTokensToSwap = swapTokensAtAmount * 20;
        }

        swapTokensForEth(totalTokensToSwap);

        uint256 ethBalance = address(this).balance;

        (success, ) = address(HelpWallet).call{value: ethBalance}("");

        super._transfer(address(this), address(0xdead), forBurn);

        forBurn = 0;
        forHelp = 0;
    }
}