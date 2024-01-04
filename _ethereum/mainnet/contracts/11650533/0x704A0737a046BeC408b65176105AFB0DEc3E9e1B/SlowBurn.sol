// SPDX-License-Identifier: UNLICENSED
// SlowBurn contract
//
// Insert cool ASCII art here.
//
pragma solidity ^0.7.5;

// OpenZeppelin SafeMath.
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

  
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

// OpenZeppelin implementation of ERC20 plus some additional logic:
// * During presale period, ether is collected in exchange for tokens.
// * Once presale ends, the collected ether is used to supply liquidity to a uniswap pool
//   with the initial token price set to the presale price.
// * From this point on anyone can call maybeReprice() once per day to adjust uniswap's
//   token balance so that the price is 20% higher than the previous day's.
// * Note that while the price is guaranteed to rise day after day, at some point sellers will
//   drain the pool of eth, making the high price meaningless since significant ether can no
//   longer be extracted. Choose your exit wisely!
contract SlowBurn {
    using SafeMath for uint256;
    
    address public developer;
    uint32 public presaleStartTime;
    uint32 public epoch;
    uint32 public lastRepriceTime;
    address public uniswapPair;
    
    // Presale period of 1 week.
    uint32 constant private kPresalePeriod = 604800;
    // Allow token reprices once per day.
    uint32 constant private kRepriceInterval = 86400;
    // Window during which maybeReprice can fail.
    uint32 constant private kRepriceWindow = 3600;
    // The token lister and successful maybeReprice callers will be rewarded with freshly minted tokens with
    // value 0.1 eth to offset any gas costs incurred.
    uint constant private kRewardWei = 10 ** 17;
    // Upon listing, developer receives 5% of uniswap's initial token balance.  
    uint constant private kDeveloperTokenCut = 5;
    // Initial token price of ~ $0.01
    uint constant private kPresaleTokensPerEth = 90000;
    // Don't allow individual users to mint more than 1 eth's worth of tokens during presale.
    uint constant private kMaxPresaleTokensPerAccount = kPresaleTokensPerEth * (10 ** 18);
    // Don't allow presale to raise more than 200 Eth
    uint constant private kPresaleHardCap = 200 * (10 ** 18);
    // Token price increases by 20% each day.
    uint constant private kTokenPriceBump = 20;

    address constant private kWeth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Factory constant private kUniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 constant private kUniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    // ********* Start of boring old ERC20 stuff **********************

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor () {
        _name = "SlowBurn";
        _symbol = "SB";
        _decimals = 18;
        developer = msg.sender;
        presaleStartTime = uint32(block.timestamp);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    // ********* And now for the good stuff! **********************
    
    // Contract accepts ether during the presale period, minting the corresponding amount
    // of tokens for the sender.
    // The first caller after the presale period ends (or if the hard cap has been hit)
    // will have their ether returned and will receive a small token reward in exchange
    // for creating the uniswap pair for this token.
    // Subsequent calls will fail.
    receive() external payable {
        if (msg.sender == address(kUniswapRouter)) {
            // Failsafe. Just in case we screwed something up in listToken() and don't manage to
            // supply our full balance, let the router return the excess funds (otherwise pool creation
            // fails and we're all screwed!) Since any funds left in this contract will be unrecoverable,
            // we send to the developer who will fix the mistake and deposit in the uniswap pool.
            // Don't worry though, we didn't screw up the math!
            payable(developer).transfer(msg.value);
            return;
        }
        uint presaleEndTime = presaleStartTime + kPresalePeriod;
        if (block.timestamp < presaleEndTime && address(this).balance - msg.value < kPresaleHardCap) {
            uint tokens = msg.value.mul(kPresaleTokensPerEth);
            require(_balances[msg.sender].add(tokens) <= kMaxPresaleTokensPerAccount, "Exceeded the presale limit");
            _mint(msg.sender, tokens);
            return;
        }
        require(uniswapPair == address(0), "Presale has ended");
        msg.sender.transfer(msg.value);
        listToken();
        payReward();
    }
    
    // To make everyone's lives just a little more interesting, reprices will be separated
    // by roughly one day, but the exact timing is subject to the vicissitudes of fate.
    // If the token has not yet been listed, or if the last reprice took place less than
    // 23.5 hours ago, this function will fail.
    // If the last reprice was between 23.5 and 24.5 hours ago, this function will succeed
    // probabilistically, with the chance increasing from 0 to 1 linearly over the range.
    // If the last reprice was more than 24.5 hours ago, this function will succeed.
    // Upon success, the token is repriced and the caller is issued a small token reward.
    function maybeReprice() public {
        require(uniswapPair != address(0), "Token hasn't been listed yet");
        require(block.timestamp >= lastRepriceTime + kRepriceInterval - kRepriceWindow / 2, "Too soon since last reprice");
        if (block.timestamp < lastRepriceTime + kRepriceInterval + kRepriceWindow / 2) {
            uint hash = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp))).mod(kRepriceWindow);
            uint mods = block.timestamp.sub(lastRepriceTime + kRepriceInterval - kRepriceWindow / 2);
            require(hash < mods, "The gods frown upon you");
        }
        epoch++;
        lastRepriceTime = uint32(block.timestamp);
        adjustPrice();
        payReward();
    }
    
    // Create uniswap pair for this token, add liquidity, and mint the developer's token cut.
    function listToken() internal {
        require(uniswapPair == address(0), "Token already listed.");
        _approve(address(this), address(kUniswapRouter), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint tokens = kPresaleTokensPerEth.mul(address(this).balance);
        _mint(developer, tokens.mul(kDeveloperTokenCut).div(100));
        uniswapPair = kUniswapFactory.getPair(address(this), kWeth);
        if (uniswapPair == address(0)) {
            _mint(address(this), tokens);
            kUniswapRouter.addLiquidityETH{value:address(this).balance}(address(this), tokens, 0, 0, address(this), block.timestamp);
            uniswapPair = kUniswapFactory.getPair(address(this), kWeth);
        } else {
            // Sigh, someone has already pointlessly created the pair. Now we have to do some math :(
            (uint reserveA, uint reserveB,) = IUniswapV2Pair(uniswapPair).getReserves();
            if (address(this) < kWeth) {
                // Round up tokens to ensure that all of the eth will be taken by the router.
                tokens = reserveA.mul(address(this).balance).add(reserveB).sub(1).div(reserveB);
            } else {
                // Round up tokens to ensure that all of the eth will be taken by the router.
                tokens = reserveB.mul(address(this).balance).add(reserveA).sub(1).div(reserveA);
            }
            _mint(address(this), tokens);
            kUniswapRouter.addLiquidityETH{value:address(this).balance}(address(this), tokens, 0, 0, address(this), block.timestamp);
            // Adjust price to match presale.
            adjustPrice();
            // Might have a very small amount of tokens left in our contract. Tidy up.
            uint leftoverTokens = balanceOf(address(this));
            if (leftoverTokens > 0) {
                _burn(address(this), leftoverTokens);
            }
        }
        // Don't think these can fail, but just in case ...
        require(uniswapPair != address(0));
        // Set lastRepriceTime to nearest day since presaleStartTime to avoid reprices
        // occurring at some horrible time in the middle of the night.
        lastRepriceTime = presaleStartTime + ((uint32(block.timestamp) - presaleStartTime + 43200) / 86400) * 86400;
    }
    
    // Adjust token balance of uniswapPair so that token price = 1.2^epoch * presale token price.
    function adjustPrice() internal {
        require(uniswapPair != address(0), "Token hasn't been listed.");
        (uint reserveTokens, uint reserveEth,) = IUniswapV2Pair(uniswapPair).getReserves();
        if (address(this) > kWeth) {
            uint temp = reserveTokens;
            reserveTokens = reserveEth;
            reserveEth = temp;
        }
        uint tokens = reserveEth.mul(kPresaleTokensPerEth);
        for (uint e = 0; e < epoch; e++) {
            tokens = tokens.mul(100).div(100+kTokenPriceBump);
        }
        if (tokens > reserveTokens) {
            _mint(uniswapPair, tokens.sub(reserveTokens));
            IUniswapV2Pair(uniswapPair).sync();
        } else if (tokens < reserveTokens) {
            _burn(uniswapPair, reserveTokens.sub(tokens));
            IUniswapV2Pair(uniswapPair).sync();
        }
    }
    
    // Mint tokens for msg.sender with value equal to kRewardWei.
    function payReward() internal {
    	uint currentTokensPerEth = kPresaleTokensPerEth;
    	for (uint e = 0; e < epoch; e++) {
    	    currentTokensPerEth = currentTokensPerEth.mul(100).div(100+kTokenPriceBump);
    	}
    	_mint(msg.sender, kRewardWei.mul(currentTokensPerEth));
    }
    
    // Just in case people do something stupid like send WETH instead of ETH to presale,
    // allow for recovery by devs.
    function transferERC(address token, address recipient, uint amount) public {
        require(msg.sender == developer, "Nice try non-dev");
        require(token != uniswapPair && token != address(this), "Nice try dev, no rug pulls allowed");
        IERC20(token).transfer(recipient, amount);
    }
}