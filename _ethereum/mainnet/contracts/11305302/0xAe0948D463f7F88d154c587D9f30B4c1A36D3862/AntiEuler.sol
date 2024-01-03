pragma solidity >=0.6.2;


///////////////////////////////////////////////////////////////////////
///							   Libraries							///
///////////////////////////////////////////////////////////////////////
library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}
}


///////////////////////////////////////////////////////////////////////
///							  Interfaces							///
///////////////////////////////////////////////////////////////////////
interface IUniswapV2Router02 {
	function WETH() external pure returns (address);
	
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


interface IUniswapV2Factory {
	function createPair(
		address tokenA,
		address tokenB
	) external returns (address pair);
}


interface ILogVault {
    function addRewards() external;
}


interface IERC20 {
	event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


///////////////////////////////////////////////////////////////////////
///							Token Contract							///
///////////////////////////////////////////////////////////////////////
contract AntiEuler is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    mapping(address => uint256) public lastTxTime;
    uint256 public lastAdjTime;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

	uint256 public constant INIT_MAX_SUPPLY     = 27182000000000000000000;  //27182 LOG;
	uint256 public constant INIT_MIN_SUPPLY     = 2718200000000000000000;   //2718.2 LOG

	uint256 public turnMaxSupply                = 27182000000000000000000;  //27182 LOG
	uint256 public turnMinSupply                = 2718200000000000000000;   //2718.2 LOG

	uint256 private constant MAX_PCT            = 100000;   //maximum 10% burn/mint in 1e6
	uint256 private constant MIN_PCT            = 10000;    //minimum 1% burn/mint
	uint256 public burnPct;
    uint256 public mintPct;

	uint256 public constant FEE_ON_TRANSFER     = 27182;    //2.7182%

    uint256 public constant BURN_INACTIVE_TIME  = 1 weeks;

    uint256 public  turn        = 1;
    bool    public  doBurn      = true;     //true = burn is active; false = mint is active


	address internal immutable FACTORY;
	address internal immutable UNIROUTER;
	address internal WETHxLOG;
	address internal immutable ADMIN_ADDRESS;
	address private VAULT_ADDRESS;

    constructor (address _FACTORY, address _UNIROUTER) public {
        _name = "AntiEuler";
        _symbol = "LOG";
        _decimals = 18;
		ADMIN_ADDRESS = msg.sender;
		FACTORY = _FACTORY;
		UNIROUTER = _UNIROUTER;
    }

	bool private liquidityAdded = false;
	bool private vaultAddressGiven = false;
	bool private uniswapCreated = false;

	event UpdateTxTime(address indexed owner, uint256 time);
	event BurnInactive(address indexed owner);
	event AdjustRates(uint256 newRate, uint256 m, uint256 n);



///////////////////////////////////////////////////////////////////////
///							Admin functions							///
///////////////////////////////////////////////////////////////////////

    //ADMIN-function: Create the Uniswap pair without adding liquidity
	function createUniswap() public {
	    require(msg.sender == ADMIN_ADDRESS, "Caller is not admin.");
        require(!uniswapCreated, "Uniswap pool already created.");
        uniswapCreated = true;
        WETHxLOG = IUniswapV2Factory(FACTORY).createPair(address(IUniswapV2Router02(UNIROUTER).WETH()), address(this));
    }


	//ADMIN-function: define address of staking contract
    //Can only be called once to set vault address
    function setVaultAddress(address _VAULT_ADDRESS) public {
		require(msg.sender == ADMIN_ADDRESS, "Caller is not admin.");
        require(!vaultAddressGiven, "Vault Address already defined.");
        vaultAddressGiven = true;
        VAULT_ADDRESS = _VAULT_ADDRESS;
    }


	//Create uniswap pair, invoked by admin calling staking contract
    function addInitialLiquidity() public payable {
        require(!liquidityAdded, "Uniswap pair has already been created.");
		require(msg.sender == VAULT_ADDRESS, "Caller is not Vault.");
		_approve(address(this), UNIROUTER, INIT_MAX_SUPPLY);
        liquidityAdded = true;

		//mint initial supply
        _mint(address(this), INIT_MAX_SUPPLY);

		//add liquidity
        IUniswapV2Router02(UNIROUTER).addLiquidityETH{ value: msg.value }(address(this), INIT_MAX_SUPPLY, 1, 1, msg.sender, block.timestamp + 15 minutes);
    }



///////////////////////////////////////////////////////////////////////
///							Miscellaneous							///
///////////////////////////////////////////////////////////////////////

    //Calculate fee, burn and mint amounts
	function calculateAmounts(address sender, address recipient, uint256 amount) internal view returns (uint256 vaultAmount, uint256 burnAmount, uint256 mintAmount) {

		//No fees when vault is sending; no fees when adding/removing liquidity
		if(sender == VAULT_ADDRESS || recipient == VAULT_ADDRESS || sender == address(this)) {
			burnAmount = 0;
			mintAmount = 0;
			vaultAmount = 0;
		}
        //No burn/mint when buying from Uniswap
        else if (sender == WETHxLOG) {
            burnAmount = 0;
			mintAmount = 0;
			vaultAmount = amount.mul(FEE_ON_TRANSFER).div(1e6);
        }
        //Full fees on normal transfer
        else {
            //calc burn and mint amounts
            burnAmount = doBurn ? amount.mul(burnPct).div(1e6) : 0;
            mintAmount = doBurn ? 0 : amount.mul(mintPct).div(1e6);
			//calc staking reward fee
			vaultAmount = amount.mul(FEE_ON_TRANSFER).div(1e6);
		}
    }


    //calc burn and mint rates as 1e6
    function adjustRates() internal {

        uint256 nominator = MAX_PCT.sub(MIN_PCT);
        uint256 denominator = turnMaxSupply.sub(turnMinSupply);

        uint256 m = nominator.mul(1e24).div(denominator);
        uint256 n = (MAX_PCT.mul(1e24)).add(m.mul(turnMinSupply));

        burnPct = (n.sub(m.mul(_totalSupply))).div(1e24);
        mintPct = (n.sub(m.mul(_totalSupply))).div(1e24);

        emit AdjustRates(burnPct, m, n);

        lastAdjTime = block.timestamp;
    }


///////////////////////////////////////////////////////////////////////
///						   Protocol Logic							///
///////////////////////////////////////////////////////////////////////

    //low-level transfer function
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount != 0, "ERC20: transfer amount was 0");

        //tx amount large enough to reset burn timer?
        bool senderValid = false;
        bool recipientValid = true;

        //avoid division by zero
        if (_balances[sender] > 0) {
            senderValid = amount.mul(1e3).div(_balances[sender]) >= 99 ? true : false;
        }

        if (_balances[recipient] > 0) {
            recipientValid = amount.mul(1e3).div(_balances[recipient]) >= 99 ? true : false;
        }


        //adjust percentage rates if last adjustment was at least 1 minute ago
        if (block.timestamp >= (lastAdjTime + 1 minutes)) {
            adjustRates();
        }


        //calc amounts
        (uint256 vaultAmount, uint256 burnAmount, uint256 mintAmount) = calculateAmounts(sender, recipient, amount);

        //assign fee to vault
		if (vaultAmount > 0) {
            _balances[VAULT_ADDRESS] = _balances[VAULT_ADDRESS].add(vaultAmount);
            emit Transfer(sender, VAULT_ADDRESS, vaultAmount);

			ILogVault(VAULT_ADDRESS).addRewards();
        }

        //burn turn
        if (burnAmount > 0) {

            //check if min supply for current turn is reached
            uint256 newTotalSupply = _totalSupply.sub(burnAmount);
            if (newTotalSupply <= turnMinSupply) {
                //reduce burn amount to match min supply
                burnAmount = _totalSupply.sub(turnMinSupply);
                //switch from burn to mint
                doBurn = false;
                processTurn();
            }

            //adjust total supply
            _totalSupply = _totalSupply.sub(burnAmount);
			emit Transfer(sender, address(0), burnAmount);
        }

        //mint turn
        else if (mintAmount > 0) {
            //check if max supply for current turn is reached
            uint256 newTotalSupply = _totalSupply.add(mintAmount);
            if (newTotalSupply >= turnMaxSupply) {
                //reduce mint amount to match max supply
                mintAmount = turnMaxSupply.sub(_totalSupply);
                //switch from mint to burn
                doBurn = true;
                processTurn();
            }

            //adjust total supply
            _totalSupply = _totalSupply.add(mintAmount);
			emit Transfer(address(0), sender, mintAmount);
        }

        //calc amount to be deducted from sender
        uint256 dedAmount = amount.sub(mintAmount);
        //deduct amount
        _balances[sender] = _balances[sender].sub(dedAmount, "ERC20: transfer amount exceeds balance");

        //calc amount to be sent to recipient
        uint256 recAmount = amount.sub(burnAmount).sub(vaultAmount);
        //assign transfer amount to recipient
        _balances[recipient] = _balances[recipient].add(recAmount);
        emit Transfer(sender, recipient, recAmount);

        //remember timestamp of transaction if transaction amount is at least 10% of balance
        //sender
        if (senderValid) {
            lastTxTime[sender] = block.timestamp;
            emit UpdateTxTime(sender, block.timestamp);
        }
        //recipient
        if (recipientValid) {
            lastTxTime[recipient] = block.timestamp;
            emit UpdateTxTime(recipient, block.timestamp);
        }
    }


    //adjust min and max supply for current turn
    function processTurn() internal {
        turn = turn.add(1);

        //macro contraction
        if (turn >= 1 && turn <= 17) {
            if (doBurn) {
                turnMinSupply = turnMinSupply.div(2);
            } else {
                turnMaxSupply = turnMaxSupply.div(2);
            }
        }

        //macro expansion
        else if (turn > 18 && turn <= 34) {
            if (doBurn) {
                turnMinSupply = turnMinSupply.mul(2);
            } else {
                turnMaxSupply = turnMaxSupply.mul(2);
            }
        }

        else if (turn == 35) {
            turnMaxSupply = INIT_MAX_SUPPLY;
            turnMinSupply = INIT_MIN_SUPPLY;
            turn = 0;
        }

        //update burn and mint rates
        adjustRates();
    }


    //burn LOG balance of address that has been inactive for more than 7 days
    function burnInactive(address user) public {
        require(user != address(0), "Cannot burn zero address balance.");
        require(user != VAULT_ADDRESS, "Cannot burn LOG Vault balance.");
        require(user != WETHxLOG, "Cannot burn Uniswap pair balance.");
        require(block.timestamp >= lastTxTime[user] + BURN_INACTIVE_TIME, "Cannot burn balance yet.");

        uint256 userBalance = balanceOf(user);
        uint256 bounty = userBalance.div(10);

        //burn balance of user
        _burn(user, balanceOf(user));
        emit BurnInactive(user);

        //if burn decreases total amount below current supply floor, mint difference to LogVault
        if (_totalSupply < turnMinSupply) {
            uint256 diff = turnMinSupply.sub(_totalSupply);
            _mint(VAULT_ADDRESS, diff);
        }

        //mint bounty to msg.sender
        _mint(msg.sender, bounty);
        lastTxTime[msg.sender] = block.timestamp;
    }


///////////////////////////////////////////////////////////////////////
///							 ERC20 Logic							///
///////////////////////////////////////////////////////////////////////
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}