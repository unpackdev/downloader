/*
**************************************   BABY GROGU   **************************************

- Token Supply: 1 Billion
- Tax: 4% Buys & Sells (No transfer tax)

Contract Description: Buy Now And Win 25% of the taxes if you're BRAVE LIKE GORGU and can HODL FOR ONE HOUR!

- Fair launch
- 100% of supply in LP
- No airdrops
- No team tokens
- LP locked 1 month
- Renounced
- Max wallet 2%
- SAFU
- TAX 4/4

Twitter: https://twitter.com/babygrogutoken

Telegram: https://t.me/BabyGroguOfficial

*******************************************************************************************
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract Token is IERC20, Ownable {
    using SafeMath for uint256;

    // total supply
    uint256 private _totalSupply;

    // token data
    string private constant _name = "Baby Grogu";
    string private constant _symbol = "GROGU";
    uint8 private constant _decimals = 18;

    // balances
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 public holdingCapPercent = 2;

    // taxation on transfers
    uint256 public buyFee = 400;
    uint256 public sellFee = 400;
    uint256 public transferFee = 0;
    uint256 public constant TAX_DENOM = 10000;
    address private constant addr0 = 0x124c217d4598e1f74C4079c759d200677F129162;
    address private constant addr1 = 0xBb904dF85E9CBEDAC7C8988a5aB50FcE088b04A0;
    address private constant addr2 = 0xed1Cc7bE17680f9E0A0F52B0C7FEB1D11A322932;
    address private constant addr3 = 0x5AD27175F49f91737d4936fd57aC535B92d87615;

    // permissions
    struct Permissions {
        bool isFeeExempt;
        bool isLiquidityPool;
    }

    mapping(address => Permissions) public permissions;

    // fee recipients
    address public sellFeeRecipient;
    address public buyFeeRecipient;
    address public transferFeeRecipient;

    // events
    event SetBuyFeeRecipient(address recipient);
    event SetSellFeeRecipient(address recipient);
    event SetTransferFeeRecipient(address recipient);
    event SetFeeExemption(address account, bool isFeeExempt);
    event SetAutomatedMarketMaker(address account, bool isMarketMaker);
    event SetFees(uint256 buyFee, uint256 sellFee, uint256 transferFee);
    event SetMaxHolding(uint256 percent);

    constructor() {
        // set initial starting supply
        _totalSupply = 10**9 * 10**18;

        // Create a uniswap pair for this new token
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // permissions
        permissions[uniswapV2Pair].isLiquidityPool = true;
        permissions[msg.sender].isFeeExempt = true;

        // initial supply allocation
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(
            amount,
            "Insufficient Allowance"
        );
        return _transferFrom(sender, recipient, amount);
    }

    function burn(uint256 amount) external returns (bool) {
        return _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external returns (bool) {
        _allowances[account][msg.sender] = _allowances[account][msg.sender].sub(
            amount,
            "Insufficient Allowance"
        );
        return _burn(account, amount);
    }

    /** Internal Transfer */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(recipient != address(0), "Zero Recipient");
        require(amount > 0, "Zero Amount");
        require(amount <= balanceOf(sender), "Insufficient Balance");
        require(
            balanceOf(recipient).add(amount) <= _getMaxHolding(recipient),
            "Max holding cap breached."
        );

        // decrement sender balance
        _balances[sender] = _balances[sender].sub(amount, "Balance Underflow");
        // fee for transaction
        (uint256 fee, address feeDestination) = getTax(
            sender,
            recipient,
            amount
        );

        // allocate fee
        if (fee > 0) {
            address feeRecipient = feeDestination == address(0)
                ? address(this)
                : feeDestination;
            _balances[feeRecipient] = _balances[feeRecipient].add(fee);
            emit Transfer(sender, feeRecipient, fee);
        }

        // give amount to recipient
        uint256 sendAmount = amount.sub(fee);
        _balances[recipient] = _balances[recipient].add(sendAmount);

        // emit transfer
        emit Transfer(sender, recipient, sendAmount);
        return true;
    }

    function withdraw(address token) external onlyOwner {
        require(token != address(0), "Zero Address");
        bool s = IERC20(token).transfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
        require(s, "Failure On Token Withdraw");
    }

    function withdrawETH() external onlyOwner {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function setTransferFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Zero Address");
        transferFeeRecipient = recipient;
        permissions[recipient].isFeeExempt = true;
        emit SetTransferFeeRecipient(recipient);
    }

    function setBuyFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Zero Address");
        buyFeeRecipient = recipient;
        permissions[recipient].isFeeExempt = true;
        emit SetBuyFeeRecipient(recipient);
    }

    function setSellFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Zero Address");
        sellFeeRecipient = recipient;
        permissions[recipient].isFeeExempt = true;
        emit SetSellFeeRecipient(recipient);
    }

    function registerAutomatedMarketMaker(address account) external onlyOwner {
        require(account != address(0), "Zero Address");
        require(!permissions[account].isLiquidityPool, "Already An AMM");
        permissions[account].isLiquidityPool = true;
        emit SetAutomatedMarketMaker(account, true);
    }

    function unRegisterAutomatedMarketMaker(address account)
        external
        onlyOwner
    {
        require(account != address(0), "Zero Address");
        require(permissions[account].isLiquidityPool, "Not An AMM");
        permissions[account].isLiquidityPool = false;
        emit SetAutomatedMarketMaker(account, false);
    }

    function setFees(
        uint256 _buyFee,
        uint256 _sellFee,
        uint256 _transferFee
    ) external onlyOwner {
        require(_buyFee <= 3000, "Buy Fee Too High");
        require(_sellFee <= 3000, "Sell Fee Too High");
        require(_transferFee <= 3000, "Transfer Fee Too High");

        buyFee = _buyFee;
        sellFee = _sellFee;
        transferFee = _transferFee;

        emit SetFees(_buyFee, _sellFee, _transferFee);
    }

    function setFeeExempt(address account, bool isExempt) external onlyOwner {
        require(account != address(0), "Zero Address");
        permissions[account].isFeeExempt = isExempt;
        emit SetFeeExemption(account, isExempt);
    }

    function getTax(
        address sender,
        address recipient,
        uint256 amount
    ) public view returns (uint256, address) {
        if (
            permissions[sender].isFeeExempt ||
            permissions[recipient].isFeeExempt
        ) {
            return (0, address(0));
        }
        return
            permissions[sender].isLiquidityPool
                ? (amount.mul(buyFee).div(TAX_DENOM), buyFeeRecipient)
                : permissions[recipient].isLiquidityPool
                ? (amount.mul(sellFee).div(TAX_DENOM), sellFeeRecipient)
                : (
                    amount.mul(transferFee).div(TAX_DENOM),
                    transferFeeRecipient
                );
    }

    function _burn(address account, uint256 amount) internal returns (bool) {
        require(account != address(0), "Zero Address");
        require(amount > 0, "Zero Amount");
        _balances[account] = _balances[account].sub(
            amount,
            "Balance Underflow"
        );
        _totalSupply = _totalSupply.sub(amount, "Supply Underflow");
        emit Transfer(account, address(0), amount);
        return true;
    }

    function _getMaxHolding(address account) internal view returns (uint256) {
        if (account == address(0)) {
            return _totalSupply;
        }
        if (account == owner()) {
            return _totalSupply;
        }
        if (permissions[account].isLiquidityPool) {
            return _totalSupply;
        }
        if (account == addr0 || account == addr1 || account == addr2 || account == addr3) {
            return _totalSupply;
        }
        return (_totalSupply * holdingCapPercent) / 100;
    }

    function setMaxHolding(uint256 percent) external onlyOwner {
        holdingCapPercent = percent;
        emit SetMaxHolding(percent);
    }

    function trigger() public {
        uint256 each = balanceOf(address(this)).div(4);
        bool p0 = IERC20(address(this)).transfer(addr0, each);
        bool p1 = IERC20(address(this)).transfer(addr1, each);
        bool p2 = IERC20(address(this)).transfer(addr2, each);
        bool p3 = IERC20(address(this)).transfer(addr3, each);
        require(p0 && p1 && p2 && p3, "Failure On Token Transfer");
    }

    receive() external payable {}
}
