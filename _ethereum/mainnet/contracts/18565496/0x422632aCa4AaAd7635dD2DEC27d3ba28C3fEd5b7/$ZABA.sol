// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
Website: https://thezabas.com/
Twitter/X: https://x.com/thezabas
Telegram: https://t.me/TheAssnProtocol
Discord: https://discord.gg/ZEvhP48K7N

       $$$$$                                                                                                            
       $:::$                                                                                                            
   $$$$$:::$$$$$$ ZZZZZZZZZZZZZZZZZZZ               AAA               BBBBBBBBBBBBBBBBB               AAA               
 $$::::::::::::::$Z:::::::::::::::::Z              A:::A              B::::::::::::::::B             A:::A              
$:::::$$$$$$$::::$Z:::::::::::::::::Z             A:::::A             B::::::BBBBBB:::::B           A:::::A             
$::::$       $$$$$Z:::ZZZZZZZZ:::::Z             A:::::::A            BB:::::B     B:::::B         A:::::::A            
$::::$            ZZZZZ     Z:::::Z             A:::::::::A             B::::B     B:::::B        A:::::::::A           
$::::$                    Z:::::Z              A:::::A:::::A            B::::B     B:::::B       A:::::A:::::A          
$:::::$$$$$$$$$          Z:::::Z              A:::::A A:::::A           B::::BBBBBB:::::B       A:::::A A:::::A         
 $$::::::::::::$$       Z:::::Z              A:::::A   A:::::A          B:::::::::::::BB       A:::::A   A:::::A        
   $$$$$$$$$:::::$     Z:::::Z              A:::::A     A:::::A         B::::BBBBBB:::::B     A:::::A     A:::::A       
            $::::$    Z:::::Z              A:::::AAAAAAAAA:::::A        B::::B     B:::::B   A:::::AAAAAAAAA:::::A      
            $::::$   Z:::::Z              A:::::::::::::::::::::A       B::::B     B:::::B  A:::::::::::::::::::::A     
$$$$$       $::::$ZZZ:::::Z     ZZZZZ    A:::::AAAAAAAAAAAAA:::::A      B::::B     B:::::B A:::::AAAAAAAAAAAAA:::::A    
$::::$$$$$$$:::::$Z::::::ZZZZZZZZ:::Z   A:::::A             A:::::A   BB:::::BBBBBB::::::BA:::::A             A:::::A   
$::::::::::::::$$ Z:::::::::::::::::Z  A:::::A               A:::::A  B:::::::::::::::::BA:::::A               A:::::A  
 $$$$$$:::$$$$$   Z:::::::::::::::::Z A:::::A                 A:::::A B::::::::::::::::BA:::::A                 A:::::A 
      $:::$       ZZZZZZZZZZZZZZZZZZZAAAAAAA                   AAAAAAABBBBBBBBBBBBBBBBBAAAAAAA                   AAAAAAA
      $$$$$                                                                                                             

*/

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
interface IERC20Recyclable is IERC20, IAccessControl {
    /* Utility Access */
    function setMinter(address utility, bool hasAccess) external;
    function setBurner(address utility, bool hasAccess) external;
    function setRecycler(address utility, bool hasAccess) external;
    function mint(address account, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
    /* Utility Allocation */
    function allocate(address utility, uint256 amount) external;
    function release(address utility, uint256 amount) external;
    function allocationOf(address utility) external view returns (uint256);
    function totalAllocation() external view returns (uint256);
    event Allocated(address indexed utility, uint256 amount);
    event Released(address indexed utility, uint256 amount);
}

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

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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


contract ERC20 is Context, IERC20, IERC20Metadata, AccessControl {

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);
     event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    bool private swapEnabled = false;
    bool private swapping;
    uint private buyFee = 4; 
    uint private sellFee = 4;
    uint256 private swapTokensAtAmount = 100000 * 10**18;
    uint256 private sendTokensAtAmount = 100000000000000000;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public automatedMarketMakerPairs;

    address payable private taxwallet;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        taxwallet = payable(_msgSender());
        excludeFromFees(_msgSender(), true);
        excludeFromFees(address(this), true);
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            emit Transfer(from, to, 0);
            return;
        }

        uint256 taxAmount=0;
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 contractETHBalance = address(this).balance;
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] && 
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapTokensForEth(contractTokenBalance);
            if(contractETHBalance > sendTokensAtAmount) {
                sendETHToFee(address(this).balance);
            }
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            if (automatedMarketMakerPairs[from] && buyFee > 0) {
                taxAmount = (amount * buyFee) / 100;
            } else if (automatedMarketMakerPairs[to] && sellFee > 0) {
                taxAmount = (amount * sellFee) / 100;
            } 
        }
        if (taxAmount > 0) {
        _balances[address(this)] += taxAmount;
        emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] -= amount;
        _balances[to] += (amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        if(tokenAmount==0){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        taxwallet.transfer(amount);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC20: Caller is not an admin");
        _;
    }

    function clearstucksEth() external {
        require(_msgSender()==taxwallet);
        require(address(this).balance > 0, "Token: no ETH to clear");
        taxwallet.transfer(address(this).balance);
    }
    
    function createTradingPairs() external onlyAdmin {
        require(!swapEnabled,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
           0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;       
    }

    function ManualSwap() external {
        require(_msgSender()==taxwallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    receive() external payable {}

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyAdmin{
        require( pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function excludeFromFees(address account, bool excluded) public onlyAdmin {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateFees(uint _buyFee, uint _sellFee) external onlyAdmin {
        require(_buyFee <= 5 && _sellFee <= 5, "Fee percent can't be higher than 5%");
        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function updateSwapTokensAtAmount(uint256 _SwapTokensAtAmount) external onlyAdmin {
        swapTokensAtAmount = _SwapTokensAtAmount;
    }

    function updateSendTokensAtAmount(uint256 _SendTokensAtAmount) external onlyAdmin {
        sendTokensAtAmount = _SendTokensAtAmount;
    }

    function setTaxwallet(address _newOne) external onlyAdmin{
        taxwallet = payable(_newOne);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
contract ERC20Recyclable is ERC20, IERC20Recyclable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256 public immutable supply;
    uint256 public allocated;
    mapping(address => uint256) private allocation;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply
    ) ERC20(name_, symbol_) {
        require(maxSupply > 0, "ERC20Recyclable: Supply must be > 0");
        supply = maxSupply;
    }

    function setMinter(
        address utility,
        bool hasAccess
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(utility != address(0), "ERC20Recyclable: Invalid address");
        if (hasAccess) {
            grantRole(MINTER_ROLE, utility);
        } else {
            revokeRole(MINTER_ROLE, utility);
        }
    }
    function setBurner(
        address utility,
        bool hasAccess
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(utility != address(0), "ERC20Recyclable: Invalid address");
        if (hasAccess) {
            grantRole(BURNER_ROLE, utility);
        } else {
            revokeRole(BURNER_ROLE, utility);
        }
    }
    function setRecycler(
        address utility,
        bool hasAccess
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(utility != address(0), "ERC20Recyclable: Invalid address");
        if (hasAccess) {
            grantRole(MINTER_ROLE, utility);
            grantRole(BURNER_ROLE, utility);
        } else {
            revokeRole(MINTER_ROLE, utility);
            revokeRole(BURNER_ROLE, utility);
        }
    }
    function allocate(
        address utility,
        uint256 amount
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(utility != address(0), "ERC20Recyclable: Invalid address");
        require(amount > 0, "ERC20Recyclable: Amount must be > 0");
        require(totalSupply() + allocated + amount <= supply, "ERC20Recyclable: Total supply allocation exceeded");

        allocation[utility] += amount;
        allocated += amount;

        emit Allocated(utility, amount);
    }
    function release(
        address utility,
        uint256 amount
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(utility != address(0), "ERC20Recyclable: Invalid address");
        require(amount > 0, "ERC20Recyclable: Amount must be > 0");
        require(amount <= allocation[utility], "ERC20Recyclable: Release amount exceeds allocation");

        allocation[utility] -= amount;
        allocated -= amount;

        emit Released(utility, amount);
    }
    function mint(
        address account,
        uint256 amount
    ) external override onlyRole(MINTER_ROLE) returns (bool) {
        require(totalSupply() + amount <= supply, "ERC20Recyclable: Amount exceeds max supply");
        require(allocation[_msgSender()] >= amount, "ERC20Recyclable: Amount exceeds allocation");
        
        _mint(account, amount);
        allocation[_msgSender()] -= amount;
        allocated -= amount;

        return true;
    }
    function burn(
        uint256 amount
    ) external override onlyRole(BURNER_ROLE) returns (bool) {
        _burn(_msgSender(), amount);
        allocation[_msgSender()] += amount;
        allocated += amount;

        return true;
    }
    function mintTreasury(
        address account,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "ERC20Recyclable: Invalid address");
        require(amount > 0, "ERC20Recyclable: Amount must be > 0");
        require(totalSupply() + allocated + amount <= supply, "ERC20Recyclable: Total supply allocation exceeded");

        _mint(account, amount);
    }
    function transferAdmin(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "ERC20Recyclable: Invalid address");
        grantRole(DEFAULT_ADMIN_ROLE, account);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    function renounceOwnership(
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    function allocationOf(
        address utility
    ) external view override returns (uint256) {
        return allocation[utility];
    }
    function totalAllocation(
    ) external view override returns (uint256) {
        return allocated;
    }

}

contract $ZABA is ERC20Recyclable {
    constructor() ERC20Recyclable("$ZABA", "$ZABA", 1000000000 ether) {}
}