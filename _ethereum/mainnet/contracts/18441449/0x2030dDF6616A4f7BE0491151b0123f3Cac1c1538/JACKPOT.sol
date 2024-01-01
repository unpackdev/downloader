/*
    Jackpot (777) Starts at 11pm today

    https://jackpot.yt

    https://x.com/Jackpot777_ETH/
    
    https://t.me/Jackpot_ETH
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.20;

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }

    mapping(address => bool) internal authorizations;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
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

interface InterfaceLP {
    function sync() external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.
pragma solidity ^0.8.0;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;
        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }
        return result;
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;
        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }
        return result;
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;
        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }
        return result;
    }
}

contract JACKPOT is Ownable, ERC20 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    struct Player {
        address user;
        uint256 amount;
    }
    struct Winner {
        uint256 tickId;
        address winner;
        uint256 bonus;
    }
    event NewTick(
        uint256 tickId,
        address user,
        uint256 probability,
        uint256 amount,
        uint256 amountUSD,
        uint256 timestamp
    );
    Player[] public players;
    Player[] public playerHolders;
    Winner[] public winners;
    uint256 public totalBonus;
    uint256 public minBonus;
    uint256 public maxBonus;
    uint256 public winnerId = 0;

    EnumerableSet.AddressSet private _callers;
    address WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    string constant _name = "Jackpot";
    string constant _symbol = "777";
    uint8 constant _decimals = 9;

    event AutoLiquify(uint256 amountETH, uint256 amountTokens);
    event EditTax(uint8 Buy, uint8 Sell, uint8 Transfer);
    event user_exemptfromfees(address Wallet, bool Exempt);
    event user_TxExempt(address Wallet, bool Exempt);
    event ClearStuck(uint256 amount);
    event ClearToken(address TokenAddressCleared, uint256 Amount);
    event set_Receivers(address marketingFeeReceiver, address burnFeeReceiver);
    event set_MaxWallet(uint256 maxWallet);
    event set_SwapBack(uint256 Amount, bool Enabled);

    uint256 _totalSupply = 7777777777 * 10**_decimals;
    uint256 public _maxTxAmount = _totalSupply.mul(100).div(100);
    uint256 public _maxWalletToken = _totalSupply.mul(1).div(100);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isexemptfromfees;
    mapping(address => bool) isexemptfrommaxTX;
    
    uint256 private liquidityFee = 1;
    uint256 private marketingFee = 1;
    uint256 private jackpotFee = 1;
    uint256 private burnFee = 0;
    uint256 public totalFee =
        jackpotFee + marketingFee + liquidityFee + burnFee;
    uint256 private feeDenominator = 100;
    uint256 sellpercent = 100;
    uint256 buypercent = 100;
    uint256 transferpercent = 0;
    
    address private autoLiquidityReceiver;
    address private marketingFeeReceiver;
    address private burnFeeReceiver;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    IDEXRouter public router;
    InterfaceLP private pairContract;
    address public pair;
    bool public TradingOpen = true;
    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply * 50) / 10000;
    uint256 public requireLottery = (_totalSupply * 10) / 10000;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        pairContract = InterfaceLP(pair);
        _allowances[address(this)][address(router)] = type(uint256).max;
        isexemptfromfees[msg.sender] = true;
        isexemptfrommaxTX[msg.sender] = true;
        isexemptfrommaxTX[pair] = true;
        isexemptfrommaxTX[marketingFeeReceiver] = true;
        isexemptfrommaxTX[address(this)] = true;
        authorizations[marketingFeeReceiver] = true;
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = 0x1929c227Aa777700471e6Cfd59a28C21050eEE45;
        burnFeeReceiver = DEAD;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner();
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

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWallet(uint256 maxWallPercent) external onlyOwner {
        require(maxWallPercent >= 1);
        _maxWalletToken = (_totalSupply * maxWallPercent) / 1000;
        emit set_MaxWallet(_maxWalletToken);
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function setWhitelistAddresss(address holder, bool exempt)
        external
        onlyOwner
    {
        isFeeExempt[holder] = exempt;
        isTxLimitExempt[holder] = exempt;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (
            !authorizations[sender] &&
            !authorizations[recipient] &&
            recipient != marketingFeeReceiver &&
            sender != marketingFeeReceiver
        ) {
            require(TradingOpen, "Trading not open yet");
        }
        if (
            !authorizations[sender] &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair &&
            recipient != burnFeeReceiver &&
            recipient != marketingFeeReceiver &&
            !isexemptfrommaxTX[recipient]
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _maxWalletToken,
                "Total Holding is currently limited, you can not buy that much."
            );
        }
        checkTxLimit(sender, amount);
        if (shouldSwapBack()) {
            swapBack();
        }
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        uint256 amountReceived = (isexemptfromfees[sender] ||
            isexemptfromfees[recipient])
            ? amount
            : takeFee(sender, amount, recipient);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if (
            sender == pair &&
            recipient != address(router) &&
            amount >= requireLottery
        ) {
            _addPlayer(amount);
        }
        emit Transfer(sender, recipient, amountReceived);
        return true;
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

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isexemptfrommaxTX[sender],
            "TX Limit Exceeded"
        );
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isexemptfromfees[sender];
    }

    function takeFee(
        address sender,
        uint256 amount,
        address recipient
    ) internal returns (uint256) {
        uint256 percent = transferpercent;
        if (recipient == pair) {
            percent = sellpercent;
        } else if (sender == pair) {
            percent = buypercent;
        }
        uint256 feeAmount = amount.mul(totalFee).mul(percent).div(
            feeDenominator * 100
        );
        uint256 burnTokens = feeAmount.mul(burnFee).div(totalFee);
        uint256 contractTokens = feeAmount.sub(burnTokens);
        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(burnTokens);
        emit Transfer(sender, address(this), contractTokens);
        if (burnTokens > 0) {
            _totalSupply = _totalSupply.sub(burnTokens);
            emit Transfer(sender, ZERO, burnTokens);
        }
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function clearStuckETH() external {
        payable(marketingFeeReceiver).transfer(address(this).balance);
    }

    function clearStuckToken(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool)
    {
        require(
            tokenAddress != address(this),
            "Owner cannot claim native tokens"
        );
        if (tokens == 0) {
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }
        return ERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function setFeeMultipliers(
        uint256 _buy,
        uint256 _sell,
        uint256 _trans
    ) public onlyOwner {
        sellpercent = _sell;
        buypercent = _buy;
        transferpercent = _trans;
        require(
            totalFee.mul(buypercent).div(100) < 25,
            "Buy Tax cannot be more than 10%"
        );
        require(
            totalFee.mul(sellpercent).div(100) < 25,
            "Sell Tax cannot be more than 10%"
        );
        require(
            totalFee.mul(transferpercent).div(100) < 15,
            "Transfer Tax cannot be more than 10%"
        );
    }

    function swapBack() internal swapping {
        uint256 totalETHFee = totalFee;
        uint256 amountToLiquify = (swapThreshold * liquidityFee) /
            (totalETHFee * 2);
        uint256 amountToSwap = swapThreshold - amountToLiquify;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance;
        totalETHFee = totalETHFee - (liquidityFee / 2);
        uint256 amountETHLiquidity = (amountETH * liquidityFee) /
            (totalETHFee * 2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(
            totalETHFee
        );
        uint256 amountETHjackpot = amountETH.mul(jackpotFee).div(totalETHFee);
        address[] memory jackpotPath = new address[](2);
        jackpotPath[0] = WETH;
        jackpotPath[1] = USDT;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens(
            amountETHjackpot,
            jackpotPath,
            address(this),
            block.timestamp
        );
        (bool tmpSuccess, ) = payable(marketingFeeReceiver).call{
            value: amountETHMarketing
        }("");
        tmpSuccess = false;
        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function set_fees() internal {
        emit EditTax(
            uint8(totalFee.mul(buypercent).div(100)),
            uint8(totalFee.mul(sellpercent).div(100)),
            uint8(totalFee.mul(transferpercent).div(100))
        );
    }

    function setTax(
        uint256 _liquidityFee,
        uint256 _jackpotFee,
        uint256 _marketingFee,
        uint256 _burnFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        jackpotFee = _jackpotFee;
        marketingFee = _marketingFee;
        burnFee = _burnFee;
        totalFee = _liquidityFee.add(_jackpotFee).add(_marketingFee).add(
            _burnFee
        );
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4, "Fees can not be more than 20%");
        set_fees();
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver,
        address _burnFeeReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        burnFeeReceiver = _burnFeeReceiver;
        emit set_Receivers(marketingFeeReceiver, burnFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit set_SwapBack(swapThreshold, swapEnabled);
    }

    function circulatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function addCaller(address val) public onlyOwner {
        require(val != address(0), "Jackpot: val is the zero address");
        _callers.add(val);
    }

    function getCallers() public view returns (address[] memory ret) {
        return _callers.values();
    }

    modifier onlyCaller() {
        require(_callers.contains(_msgSender()), "onlyCaller");
        _;
    }

    function _addPlayer(uint256 amount) private {
        players.push(Player(msg.sender, amount));
    }

    function getPlayers() public view returns (Player[] memory) {
        return players;
    }

    function lottery() public onlyCaller {
        uint256 countEligibleHolders = 0;
        for (uint256 i = 0; i < players.length; i++) {
            uint256 balanceOfHolder = balanceOf(players[i].user);
            if (balanceOfHolder >= requireLottery) {
                countEligibleHolders++;
                playerHolders.push(Player(players[i].user, balanceOfHolder));
            }
        }
        IERC20 bonusToken = IERC20(USDT);

        uint256 bal = bonusToken.balanceOf(address(this));
        if (bal < minBonus) {
            return;
        }
        uint256 randomValue = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.number))
        ) % countEligibleHolders;

        for (uint256 i = 0; i < playerHolders.length; i++) {
            if (randomValue == i) {
                uint256 bonus = bal > maxBonus ? maxBonus : bal;
                bonusToken.transfer(playerHolders[i].user, bonus);
                totalBonus += bonus;
                winnerId++;
                winners.push(
                    Winner(
                        winnerId,
                        playerHolders[i].user,
                        bonus
                    )
                );
                break;
            }
        }
        delete playerHolders;
        delete players;
    }

    function setMinBouns(uint256 val) public onlyCaller {
        require(val < maxBonus, "bad val");
        minBonus = val;
    }

    function setMaxBouns(uint256 val) public onlyCaller {
        require(val > minBonus, "bad val");
        maxBonus = val;
    }

    function setRequireLottery(uint256 val) public onlyCaller {
        requireLottery = val;
    }
    

    function getWinners() public view returns (Winner[] memory) {
        return winners;
    }
}