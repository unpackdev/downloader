// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

  
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
pragma solidity ^0.8.0;


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

pragma solidity ^0.8.0;


interface IERC20Metadata is IERC20 {
  
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 _totalSupply;

    string private _name;
    string private _symbol;

 
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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



pragma solidity ^0.8.0;


interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    function mint(MintParams calldata params) external payable returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

contract TEST is Ownable, ERC20 {
    INonfungiblePositionManager posMan = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88); //MAINNET / TESTNET
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
    //address constant weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //goerli
    uint immutable uniswapSupply = 900_000_000 * 10 ** decimals();

    uint24 constant fee = 100;
    uint160 sqrtPriceX96;
    int24 minTick;
    int24 maxTick;
    address public pool;
    address token0;
    address token1;
    uint amount0Desired;
    uint amount1Desired;

    bool private launched;
    event TEST_EVENT(string TEXT);

    bool private limits = true;
    uint256 public maxTx;
    uint256 public maxWallet;

   
    constructor(uint256 totalSupply, address[] memory w) ERC20("TEST", "TEST") {
        _totalSupply = totalSupply * 10 ** decimals();
        _balances[address(this)] = uniswapSupply;
        emit Transfer(address(0), address(this), uniswapSupply);
        _balances[w[0]] = 50_000_000 * 10 ** decimals();
        emit Transfer(address(0), w[0], 50_000_000 * 10 ** decimals());
        _balances[w[1]] = 50_000_000 * 10 ** decimals();
        emit Transfer(address(0), w[1], 50_000_000 * 10 ** decimals());
        _balances[w[2]] = 50_000_000 * 10 ** decimals();
        fixOrdering();
        pool = posMan.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96);
        maxTx = super.totalSupply()/100;
        maxWallet = maxTx*2;
    }

  
    function fixOrdering() private {
        if (address(this) < weth) {
            token0 = address(this);
            token1 = weth;
            sqrtPriceX96 = 6818606433396674619660337;
            amount0Desired = uniswapSupply;
            amount1Desired = 0;
            minTick = -187143;
            maxTick = 0;
            emit TEST_EVENT("<");
        } else {
            token0 = weth;
            token1 = address(this);
            sqrtPriceX96 = 920040883463736372645278684184779;
            amount0Desired = 0;
            amount1Desired = uniswapSupply;
            minTick = 0;
            maxTick = 187143;
        }
    }


    function addLiquidity() public onlyOwner {
        IERC20(address(this)).approve(address(posMan), uniswapSupply);
        posMan.mint(INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: minTick,
            tickUpper: maxTick,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: owner(),
            deadline: block.timestamp + 1200
        }));
    }

    function enableTrading() external onlyOwner{
        launched = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override view  {
        if(from != owner() && from != address(this) && to != owner() && to != address(this)){
            require(launched, "Not launched");
            if(limits) {
                require(amount <= maxTx && (balanceOf(to) + amount) < maxWallet, "Over limits");
            }
        }
    }

    function removeLimits() external onlyOwner {
        limits = false;
    }
    

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}