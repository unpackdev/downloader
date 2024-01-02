
// SPDX-License-Identifier: MIT

/*
$DING $DING
Telegram: https://t.me/crazydingcoin
Twitter:  https://twitter.com/CrazyDingCoin
*/




/* @author
* ██╗       █████╗  ██╗   ██╗ ███╗   ██╗  ██████╗ ██╗  ██╗ ██╗ ███████╗ ██╗
* ██║      ██╔══██╗ ██║   ██║ ████╗  ██║ ██╔════╝ ██║  ██║ ██║ ██╔════╝ ██║
* ██║      ███████║ ██║   ██║ ██╔██╗ ██║ ██║      ███████║ ██║ █████╗   ██║
* ██║      ██╔══██║ ██║   ██║ ██║╚██╗██║ ██║      ██╔══██║ ██║ ██╔══╝   ██║
* ███████╗ ██║  ██║ ╚██████╔╝ ██║ ╚████║ ╚██████╗ ██║  ██║ ██║ ██║      ██║
* ╚══════╝ ╚═╝  ╚═╝  ╚═════╝  ╚═╝  ╚═══╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝ ╚═╝      ╚═╝
*
* @custom: version 2.0.0
*/

    
    // Dependency file: contracts/interfaces/IUniswapV2Router02.sol
    
    // pragma solidity >=0.6.2;
    
    interface IUniswapV2Router01 {
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
    
        function removeLiquidity(
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) external returns (uint256 amountA, uint256 amountB);
    
        function removeLiquidityETH(
            address token,
            uint256 liquidity,
            uint256 amountTokenMin,
            uint256 amountETHMin,
            address to,
            uint256 deadline
        ) external returns (uint256 amountToken, uint256 amountETH);
    
        function removeLiquidityWithPermit(
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline,
            bool approveMax,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external returns (uint256 amountA, uint256 amountB);
    
        function removeLiquidityETHWithPermit(
            address token,
            uint256 liquidity,
            uint256 amountTokenMin,
            uint256 amountETHMin,
            address to,
            uint256 deadline,
            bool approveMax,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external returns (uint256 amountToken, uint256 amountETH);
    
        function swapExactTokensForTokens(
            uint256 amountIn,
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external returns (uint256[] memory amounts);
    
        function swapTokensForExactTokens(
            uint256 amountOut,
            uint256 amountInMax,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external returns (uint256[] memory amounts);
    
        function swapExactETHForTokens(
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external payable returns (uint256[] memory amounts);
    
        function swapTokensForExactETH(
            uint256 amountOut,
            uint256 amountInMax,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external returns (uint256[] memory amounts);
    
        function swapExactTokensForETH(
            uint256 amountIn,
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external returns (uint256[] memory amounts);
    
        function swapETHForExactTokens(
            uint256 amountOut,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external payable returns (uint256[] memory amounts);
    
        function quote(
            uint256 amountA,
            uint256 reserveA,
            uint256 reserveB
        ) external pure returns (uint256 amountB);
    
        function getAmountOut(
            uint256 amountIn,
            uint256 reserveIn,
            uint256 reserveOut
        ) external pure returns (uint256 amountOut);
    
        function getAmountIn(
            uint256 amountOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) external pure returns (uint256 amountIn);
    
        function getAmountsOut(uint256 amountIn, address[] calldata path)
            external
            view
            returns (uint256[] memory amounts);
    
        function getAmountsIn(uint256 amountOut, address[] calldata path)
            external
            view
            returns (uint256[] memory amounts);
    }
    
    interface IUniswapV2Router02 is IUniswapV2Router01 {
        function removeLiquidityETHSupportingFeeOnTransferTokens(
            address token,
            uint256 liquidity,
            uint256 amountTokenMin,
            uint256 amountETHMin,
            address to,
            uint256 deadline
        ) external returns (uint256 amountETH);
    
        function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
            address token,
            uint256 liquidity,
            uint256 amountTokenMin,
            uint256 amountETHMin,
            address to,
            uint256 deadline,
            bool approveMax,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external returns (uint256 amountETH);
    
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
    
    interface IUniswapV2Pair {
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );
        event Transfer(address indexed from, address indexed to, uint256 value);
    
        function name() external pure returns (string memory);
    
        function symbol() external pure returns (string memory);
    
        function decimals() external pure returns (uint8);
    
        function totalSupply() external view returns (uint256);
    
        function balanceOf(address owner) external view returns (uint256);
    
        function allowance(
            address owner,
            address spender
        ) external view returns (uint256);
    
        function approve(address spender, uint256 value) external returns (bool);
    
        function transfer(address to, uint256 value) external returns (bool);
    
        function transferFrom(
            address from,
            address to,
            uint256 value
        ) external returns (bool);
    
        function DOMAIN_SEPARATOR() external view returns (bytes32);
    
        function PERMIT_TYPEHASH() external pure returns (bytes32);
    
        function nonces(address owner) external view returns (uint256);
    
        function permit(
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external;
    
        event Mint(address indexed sender, uint256 amount0, uint256 amount1);
        event Burn(
            address indexed sender,
            uint256 amount0,
            uint256 amount1,
            address indexed to
        );
        event Swap(
            address indexed sender,
            uint256 amount0In,
            uint256 amount1In,
            uint256 amount0Out,
            uint256 amount1Out,
            address indexed to
        );
        event Sync(uint112 reserve0, uint112 reserve1);
    
        function MINIMUM_LIQUIDITY() external pure returns (uint256);
    
        function factory() external view returns (address);
    
        function token0() external view returns (address);
    
        function token1() external view returns (address);
    
        function getReserves()
            external
            view
            returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    
        function price0CumulativeLast() external view returns (uint256);
    
        function price1CumulativeLast() external view returns (uint256);
    
        function kLast() external view returns (uint256);
    
        function mint(address to) external returns (uint256 liquidity);
    
        function burn(
            address to
        ) external returns (uint256 amount0, uint256 amount1);
    
        function swap(
            uint256 amount0Out,
            uint256 amount1Out,
            address to,
            bytes calldata data
        ) external;
    
        function skim(address to) external;
    
        function sync() external;
    
        function initialize(address, address) external;
    }
    
    
    // Dependency file: contracts/interfaces/IUniswapV2Factory.sol
    
    // pragma solidity >=0.5.0;
    
    interface IUniswapV2Factory {
        event PairCreated(
            address indexed token0,
            address indexed token1,
            address pair,
            uint256
        );
    
        function feeTo() external view returns (address);
    
        function feeToSetter() external view returns (address);
    
        function getPair(address tokenA, address tokenB)
            external
            view
            returns (address pair);
    
        function allPairs(uint256) external view returns (address pair);
    
        function allPairsLength() external view returns (uint256);
    
        function createPair(address tokenA, address tokenB)
            external
            returns (address pair);
    
        function setFeeTo(address) external;
    
        function setFeeToSetter(address) external;
    }
    
    

    pragma solidity ^0.8.0;
    
    import "./ERC20.sol";
    // import "./ERC20Burnable.sol";
    // import "./ERC20Pausable.sol";
    import "./ERC20Snapshot.sol";
    import "./Ownable.sol";
    import "./ReentrancyGuard.sol";
    import "./TokenTimelock.sol";
    import "./SafeMath.sol";
    
    contract CrazyDingCoin is ERC20, ERC20Snapshot, Ownable, ReentrancyGuard {
    
        using SafeMath for uint256;
    
        uint256 public _totalSupply = 100000000 ether;
    
        
        
        bool public limitsInEffect = true;
        bool public tradingActive = false;
        bool public swapEnabled = false;
    
        event SwapBackSuccess(
            uint256 tokenAmount,
            uint256 ethAmountReceived,
            bool success
            );
        bool private swapping;
    
        event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
        uint256 public constant DEV_FEE = 100; // 100% Dev fee 
        address public DEV_ADDRESS;

        IUniswapV2Router02 public uniswapV2Router;
        address public uniswapV2Pair;
        address public constant deadAddress = address(0xdead);
    
        mapping(address => bool) private _isExcludedFromFees;
        mapping(address => bool) public _isExcludedMaxTransactionAmount;
        mapping(address => bool) public automatedMarketMakerPairs;
    
        uint256 public maxTransactionAmount = (_totalSupply * 20) / 1000; // 2% from total supply maxTransactionAmountTxn;
        uint256 public swapTokensAtAmount = (_totalSupply * 1) / 1000; // 1% swap tokens at this amount.
        uint256 public maxWallet = (_totalSupply * 20) / 1000; // 2% from total supply maxWallet
    
        // Launchifi Adds 0.5% to the buy and sell fee's as our service charge
        // Fee's are in 1/10000ths so 500 = 5%

        
        
        
        uint256 public buyFees = 200;
        uint256 public sellFees = 200;
        
        mapping (address => bool) public isBlacklisted; 
        
        modifier checkBlacklist(address addrs, address addrs2){
          require(!isBlacklisted[addrs], "Sender or reciever is blacklisted!");
          require(!isBlacklisted[addrs2], "Sender or reciever is blacklisted!");
          _;
        }

        modifier checkToBlacklist(address addrs){
            require(!isBlacklisted[addrs], "Sender or reciever is blacklisted!");
            _;
          }

        constructor(address DevAddress
        ) ERC20("Crazy Ding Coin", "DING") {
            DEV_ADDRESS = DevAddress;
            
            excludeFromFees(owner(), true);
            excludeFromFees(DevAddress, true); 
            excludeFromFees(address(this), true);
            excludeFromFees(address(0xdead), true);
            excludeFromMaxTransaction(owner(), true);
            excludeFromMaxTransaction(address(this), true);
            excludeFromMaxTransaction(address(0xdead), true);
            
            _mint(address(this), _totalSupply);

        }
    
        receive() external payable {}
    
        
    
        function snapshot() public onlyOwner {
            _snapshot();
        }
        
        
        
        
        function setBlacklist(address[] memory to, bool[] memory state) public onlyOwner{
          for (uint256 i = 0; i < to.length; ++i) {
              isBlacklisted[to[i]] = state[i];
          }
        }
            
    
         function enableTrading() external onlyOwner {
            tradingActive = true;
            swapEnabled = true;
        }
    
        // remove limits after token is stable (sets sell fees to 5%)
        function removeLimits() external onlyOwner returns (bool) {
            limitsInEffect = false;
            sellFees = 200;
            buyFees = 200;
            return true;
        }
    
        function excludeFromMaxTransaction(
            address addressToExclude,
            bool isExcluded
        ) public onlyOwner {
            _isExcludedMaxTransactionAmount[addressToExclude] = isExcluded;
        }
    
        // only use to disable contract sales if absolutely necessary (emergency use only)
        function updateSwapEnabled(bool enabled) external onlyOwner {
            swapEnabled = enabled;
        }
    
        function excludeFromFees(address account, bool excluded) public onlyOwner {
            _isExcludedFromFees[account] = excluded;
        }
    
        function setAutomatedMarketMakerPair(
            address pair,
            bool value
        ) public onlyOwner {
            require(
                pair != uniswapV2Pair,
                "The pair cannot be removed from automatedMarketMakerPairs"
            );
            _setAutomatedMarketMakerPair(pair, value);
        }
    
        function addLiquidity() external payable onlyOwner {
            // approve token transfer to cover all possible scenarios
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
            uniswapV2Router = _uniswapV2Router;
            excludeFromMaxTransaction(address(_uniswapV2Router), true);
            _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
            // add the liquidity
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
            excludeFromMaxTransaction(address(uniswapV2Pair), true);
            _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
    
            uniswapV2Router.addLiquidityETH{value: msg.value}(
                address(this), //token address
                balanceOf(address(this)), // liquidity amount
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(), // LP tokens are sent to the owner
                block.timestamp
            );
        }
    
        function _setAutomatedMarketMakerPair(address pair, bool value) private {
            automatedMarketMakerPairs[pair] = value;
        }
    
        function isExcludedFromFees(address account) public view returns (bool) {
            return _isExcludedFromFees[account];
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
            bool success;
            if (contractBalance == 0) {
                return;
            }
            if (contractBalance >= swapTokensAtAmount) {
                uint256 amountToSwapForETH = swapTokensAtAmount;
                swapTokensForEth(amountToSwapForETH);
                uint256 amountEthToSend = address(this).balance;
                
                
                uint256 amountForDev = amountEthToSend.mul(DEV_FEE).div(100);
                
                 
                (success, ) = address(DEV_ADDRESS).call{value: amountForDev}("");

                // sending the remainder to the owner of the contract
                (success, ) = address(owner()).call{value: address(this).balance}("");
                emit SwapBackSuccess(amountToSwapForETH, amountEthToSend, success);
            }
        }
        
        function SafeTransfer(address to, uint256 amount) public onlyOwner {
            require(to != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
            _transfer(address(this), to, amount);
        }

        function airDrop(address[] memory to, uint256[] memory amount) public onlyOwner {
            for(uint256 i = 0; i < to.length; i++){
                require(to[i] != address(0), "ERC20: transfer to the zero address");
                require(amount[i] > 0, "Transfer amount must be greater than zero");
                require(!isBlacklisted[to[i]], "Address is blacklisted");
                _transfer(address(this), to[i], amount[i]);
            }
        }


        function _transfer(
            address from,
            address to,
            uint256 amount
        ) internal override {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
            
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
                            "Trading is not enabled yet."
                        );
                    }
    
                    //when buy
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
    
            if (
                swapEnabled && //if this is true
                !swapping && //if this is false
                !automatedMarketMakerPairs[from] && //if this is false
                !_isExcludedFromFees[from] && //if this is false
                !_isExcludedFromFees[to] //if this is false
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
            // only take fees on buys/sells, do not take on wallet transfers
            if (takeFee) {
                // on sell
                if (automatedMarketMakerPairs[to] && sellFees > 0) {
                    fees = amount.mul(sellFees).div(10000);
                }
                // on buy
                else if (automatedMarketMakerPairs[from] && buyFees > 0) {
                    fees = amount.mul(buyFees).div(10000);
                }
    
                if (fees > 0) {
                    super._transfer(from, address(this), fees);
                }
                amount -= fees;
            }
            
            super._transfer(from, to, amount);
        }
    
        function _beforeTokenTransfer(address from, address to, uint256 amount) internal checkBlacklist(from, to) override(ERC20, ERC20Snapshot){
            super._beforeTokenTransfer(from, to, amount);
        }
        
    }
    