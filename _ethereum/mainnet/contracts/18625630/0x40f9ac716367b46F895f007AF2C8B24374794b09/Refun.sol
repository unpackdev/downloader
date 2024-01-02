/*
REFUN's Rhapsody: NFT Redemption

Crafting NFTs for Joy, Not Just Wealth. 
Yet, amid the euphoria, many projects falter post-minting, 
abandoning the essence of creation and draining the joy from us.
But behold, REFUN emerges as a haven for NFTs, even when their value dwindles due to RUG PULL. 
It's a tale of second chances. 
Send your NFTs to the FUN POOL and watch them transform into $REFUN tokens, 
a resurrection of their original essence.


website:   https://refun.vip/
telegram:  https://t.me/Refun_Portal1
twitter/X: https://twitter.com/Refun_erc20

Tokenomics
- Total Supply 21,000,000
- LP: 80%
- Reward Pool: 15%
- Marketing: 5%
- Tax: 2%/2%
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
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
    ) internal virtual {}

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
}

contract Refun is ERC20, Ownable {
    event e_Deposite(address erc721, uint256[] ids, address from);
    event e_Reward(uint256 value, address from);
    event e_Withdraw(address erc721, uint256 id, address from);
    event e_openTrading();
    event e_removeLimit();

    IUniswapV2Factory public uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    uint256 public constant mintValue = 21000000 * 1e18;    
    uint256 public constant addLiquidityPercent = 80;
    uint256 public constant Fee = 2;
    uint256 public maxAmountPerWallet = 420000 * 1e18;
    uint256 public maxFee = 21000 * 1e18;
    mapping (address => bool) private _isExcludedFromFee;
    uint256 public Treasury;

    uint256 public totalMember;
    mapping(address => bool) public Deposited;
    mapping(address => uint256) public Deposites;
    mapping(address => address) public Higher;
    mapping(address => address) public Lower;

    uint256 public baseTime;
    mapping(address => bool) public Rewarded;

    bool public Trading;
    bool private swapLocked;
    modifier swapLocker {
        swapLocked = true;
        _;
        swapLocked = false;
    }

    constructor() ERC20('Refun', 'REFUN') {
        Deposites[address(1)] = ~uint256(0);
        _mint(address(this), mintValue * 95 / 100);
        _mint(msg.sender, mintValue * 5 / 100);
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(uniswapV2Router)] = true;
    }

    function fetchTopK(uint256 k) external view returns (address[] memory, uint256[] memory) {
        address[] memory topKAddress = new address[](k);
        uint256[] memory topKValue = new uint256[](k);
        address Current = Lower[address(1)];
        for(uint256 i; i<k ; i++) {
            topKAddress[i] = Current;
            topKValue[i] = Deposites[Current];
            Current = Lower[Current];
        }
        return (topKAddress, topKValue);
    }

    function Deposite(address erc721, uint256[] calldata ids) external returns (bool) {
        require(ids.length > 0, 'No length');

        for(uint256 i=0; i<ids.length ; i++) {
            IERC721(erc721).transferFrom(msg.sender, address(this), ids[i]);
        }
        
        if(baseTime != 0 && block.timestamp > baseTime + 12 hours) {
            return true;
        }

        Deposites[msg.sender] += ids.length;

        if(!Deposited[msg.sender]) {
            totalMember ++;
            Deposited[msg.sender] = true;
        }

        address Prev = Higher[msg.sender];
        if(Prev == address(0)) {
            address Current = address(1);
            while(true) {
                if(Deposites[msg.sender] > Deposites[Current]) {
                    Higher[msg.sender] = Higher[Current];
                    Lower[msg.sender] = Current;
                    Lower[Higher[Current]] = msg.sender;
                    Higher[Current] = msg.sender;
                    break;
                }
                address Next = Lower[Current];
                if(Next == address(0)) {
                    Lower[Current] = msg.sender;
                    Higher[msg.sender] = Current;
                    break;
                }
                Current = Next;
            }
        } else {
            Lower[Higher[msg.sender]] = Lower[msg.sender];
            Higher[Lower[msg.sender]] = Higher[msg.sender];
            address Current = address(1);
            while(true) {
                if(Deposites[msg.sender] > Deposites[Current]) {
                    Higher[msg.sender] = Higher[Current];
                    Lower[msg.sender] = Current;
                    Lower[Higher[Current]] = msg.sender;
                    Higher[Current] = msg.sender;
                    break;
                }
                address Next = Lower[Current];
                if(Next == address(0)) {
                    Lower[Current] = msg.sender;
                    Higher[msg.sender] = Current;
                    break;
                }
                Current = Next;
            }
        }

        emit e_Deposite(erc721, ids, msg.sender);

        return true;
    }

    function Reward() external returns (bool) {
        require(baseTime != 0 && block.timestamp > baseTime + 72 hours, 'Time error');
        require(totalMember >= 50, 'members < 50');
        require(Deposited[msg.sender], 'Not deposited');
        require(!Rewarded[msg.sender], 'Rewarded');

        uint256 baseRewardPercent = totalMember >= 300 ? 15 : 10;
        uint256 baseRewardValue = mintValue * baseRewardPercent / 100 / (105 + totalMember);

        uint256 Rank;
        uint256 x = 1;
        address Current = Lower[address(1)];
        for(uint256 i; i<30 ; i++) {
            if(Current == msg.sender) {
                Rank = i+1;
                break;
            }
            Current = Lower[Current];
        }
        if(Rank == 1) x = 30;
        if(Rank == 2) x = 20;
        if(Rank == 3) x = 10;
        if(Rank > 3 && Rank <= 10) x = 5;
        if(Rank > 10 && Rank <= 30) x = 2;
        
        _transfer(address(this), msg.sender, baseRewardValue * x);
        Rewarded[msg.sender] = true;

        emit e_Reward(baseRewardValue * x, msg.sender);

        return true;
    }

    function Withdraw(address erc721, uint256 id) external onlyOwner() returns (bool) {
        IERC721(erc721).transferFrom(address(this), msg.sender, id);

        emit e_Withdraw(erc721, id, owner());

        return true;
    }

    function openTrading() external onlyOwner() returns (bool) {
        require(!Trading, 'Already Trading');

        uniswapV2Pair = uniswapV2Factory.createPair(address(this), uniswapV2Router.WETH());
        uint256 Liquidity = mintValue * addLiquidityPercent / 100;
        _approve(address(this), address(uniswapV2Router), Liquidity);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), Liquidity, 0, 0, owner(), block.timestamp);
        baseTime = block.timestamp;

        Trading = true;

        emit e_openTrading();
        
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && Trading) {
            taxAmount = amount * 2 / 100;
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= maxAmountPerWallet, "Exceeds the maxAmountPerWallet.");
                require(balanceOf(to) + amount <= maxAmountPerWallet, "Exceeds the maxAmountPerWallet.");
            }

            if (to != uniswapV2Pair && ! _isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= maxAmountPerWallet, "Exceeds the maxAmountPerWallet.");
            }

            if(from != uniswapV2Pair && to != uniswapV2Pair) {
                taxAmount = 0;
            }

            if (!swapLocked && to == uniswapV2Pair && Trading && Treasury > 0) {
                uint256 temTreasury = Treasury > maxFee ? maxFee : Treasury;
                Treasury -= temTreasury;
                swapExactTokensForETHSupportingFeeOnTransferTokens(temTreasury);
            }
        }

        if(taxAmount > 0) {
            Treasury += taxAmount;
            _balances[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] -= amount;
        _balances[to] += (amount - taxAmount);

        emit Transfer(from, to, (amount - taxAmount));
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 tax) internal swapLocker() {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tax);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tax, 0, path, owner(), block.timestamp);
    }

    function removeLimit() external onlyOwner() returns (bool) {
        maxAmountPerWallet = mintValue;

        emit e_removeLimit();

        return true;
    }

    receive() external payable {}
}