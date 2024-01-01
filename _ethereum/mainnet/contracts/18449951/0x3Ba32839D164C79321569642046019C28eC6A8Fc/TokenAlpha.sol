pragma solidity ^0.8.17;
//SPDX-License-Identifier: MIT

import "IERC20.sol";
import "Auth.sol";
import "SafeMath.sol";
import "IDEXRouter.sol";
import "IDEXFactory.sol";

contract TokenAlpha is IERC20, Auth {
    using SafeMath for uint256;

    string _name;
    string _symbol;

    uint8 constant _decimals = 9;

    uint256 public _totalSupply;

    uint256 public _maxWalletToken;
    uint256 public _swapThreshold;

    uint256 public _marketingBuyTax;
    uint256 public _marketingSellTax;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    address public pair;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public _marketingAddress;
    address public WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IDEXRouter public router;

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountCoin);

    constructor(
        string[] memory _stringData,
        address _addressData,
        uint256[] memory _intData
    ) payable Auth(msg.sender) {
        require(_stringData.length == 2, "String List needs 4 string inputs");
        require(_intData.length == 5, "Int List needs 5 int inputs");
        router = IDEXRouter(routerAddress);

        authorizations[routerAddress] = true;
        authorizations[address(this)] = true;

        _name = _stringData[0];
        _symbol = _stringData[1];

        require(_intData[0] > 0, "Total Supply must be greater than 0.");
        _totalSupply = _intData[0] * 10 ** _decimals;
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);

        _marketingAddress = _addressData;

        _maxWalletToken = (_totalSupply * _intData[1]) / 1000;
        _swapThreshold = (_totalSupply * _intData[2]) / 1000;

        _marketingBuyTax = _intData[3];
        _marketingSellTax = _intData[4];

        _allowances[address(this)][routerAddress] = _totalSupply;
        isTxLimitExempt[address(this)] = true;

        require(
            _marketingAddress != address(0),
            "Reciever wallets can't be Zero address."
        );

        require(_swapThreshold > 0, "Swap Threshold must be greater than 0%.");
        require(_maxWalletToken > 0, "Max Wallet must be greater than 0%.");
    }

    receive() external payable {}

    function initializeLP() external payable onlyOwner {
        require(address(this).balance > 0);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        router.addLiquidityETH{value: msg.value}(
            address(this),
            _totalSupply,
            0,
            0,
            msg.sender,
            block.timestamp + 1
        );
    }

    function getAddressBalance(address _address) public view returns (uint256) {
        return _address.balance;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (owner == msg.sender) {
            return _basicTransfer(msg.sender, recipient, amount);
        } else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (authorizations[sender] || authorizations[recipient]) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkLimits(sender, recipient, amount);
        if (shouldTokenSwap(recipient)) {
            tokenSwap();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        uint256 amountReceived = (recipient == pair || sender == pair)
            ? takeFee(sender, recipient, amount)
            : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            return amount;
        }
        uint256 _totalFee;

        _totalFee = (recipient == pair) ? getSellTax() : getBuyTax();

        uint256 feeAmount = amount.mul(_totalFee).div(1000);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);

        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function getBuyTax() public view returns (uint) {
        return _marketingBuyTax;
    }

    function getSellTax() public view returns (uint) {
        return _marketingSellTax;
    }

    function getTotalTax() public view returns (uint) {
        return getSellTax() + getBuyTax();
    }

    function setTaxes(
        uint256 _marketingBuyPercent,
        uint256 _marketingSellPercent
    ) external onlyOwner {
        _marketingBuyTax = _marketingBuyPercent;
        _marketingSellTax = _marketingSellPercent;
    }

    function tokenSwap() internal swapping {
        uint256 amountToSwap = _swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETHAddress;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        bool tmpSuccess;

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = getTotalTax();

        if (_marketingBuyTax + _marketingSellTax > 0) {
            uint256 amountETHMarketing = amountETH
                .mul(_marketingBuyTax + _marketingSellTax)
                .div(totalETHFee);
            (tmpSuccess, ) = payable(_marketingAddress).call{
                value: amountETHMarketing,
                gas: 100000
            }("");
            tmpSuccess = false;
        }
    }

    function shouldTokenSwap(address recipient) internal view returns (bool) {
        return ((recipient == pair) &&
            !inSwap &&
            _balances[address(this)] >= _swapThreshold);
    }

    function checkLimits(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        if (
            !authorizations[sender] &&
            !authorizations[recipient] &&
            recipient != address(this) &&
            sender != address(this) &&
            recipient != 0x000000000000000000000000000000000000dEaD &&
            recipient != pair &&
            recipient != _marketingAddress
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _maxWalletToken,
                "Total Holding is currently limited, you can not buy that much."
            );
        }
    }

    function setMaxWallet(uint256 percent) external onlyOwner {
        _maxWalletToken = (_totalSupply * percent) / 1000;
        require(_maxWalletToken > 0, "Max Wallet must be greater than 0%.");
    }

    function setTokenSwapSettings(uint256 percent) external onlyOwner {
        _swapThreshold = (_totalSupply * percent) / 1000;
        require(percent > 0, "Swap Threshold must be greater than 0%.");
    }

    function liftLimits() external onlyOwner {
        _maxWalletToken = _totalSupply;
    }

    function setAddresses(address marketingAddress) external onlyOwner {
        if (marketingAddress != address(0)) {
            _marketingAddress = marketingAddress;
        }
    }

    function setTXExemption(address user, bool status) external onlyOwner {
        isTxLimitExempt[user] = status;
    }

    function setFeeExemption(address user, bool status) external onlyOwner {
        isFeeExempt[user] = status;
    }

    function clearStuckBalance() external {
        payable(_marketingAddress).transfer(address(this).balance);
    }
}
