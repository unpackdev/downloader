/**
    Saltz
    Explore the world’s first yield generating deflationary coin with guaranteed Minimum selling price.
    
    Website: https://saltz.io
    Twitter: https://twitter.com/Saltz_io
    Telegram: https://t.me/saltzofficial

**/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;
import "./ISaltzYard2.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

pragma solidity ^0.8.9;

interface IVault {
    function setUpdater(address _updater) external;
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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address internal _owner;
    address private _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: Vault.sol

pragma solidity ^0.8.9;

contract Vault is Ownable {
    IERC20 tokenAddress;
    address public updater;

    //address public owner;
    constructor(address _token) {
        tokenAddress = IERC20(_token);
    }

    modifier onlyUpdater() {
        require(msg.sender == updater, "you are not the updater");
        _;
    }

    function setUpdater(address _updater) public onlyOwner {
        updater = _updater;
    }

    function withdraw(uint amount, address _user) public onlyUpdater {
        tokenAddress.transfer(_user, amount);
    }
}

contract ERC20 is Context, Ownable, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

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

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
}

contract Saltz is ERC20 {
    using SafeMath for uint256;

        struct ValuesOfAmount {
        uint256 amount;
        uint256 whaleFee;
        uint256 totalTax;
        uint256 transferAmount;
    }

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public isRegistered;
    mapping(uint8 => uint16) public commision; // for referals
    mapping(address => address) public parent;
    mapping(address => uint) public referalReward;
    mapping(address => uint) public totalCommisionEarned;

    address[] public users;

    address public devWallet;
    address public vault;

    address constant _burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint16 private totalTax = 1000;

    // percentage of totalTax(after referrals distributed , if any) that goes into burning mechanism
    uint16 private taxBurn = 4000;

    // percentage of transaction redistributed to all holders
    uint16 private taxReward = 3500;

    // percentage of transaction goes to developers
    uint16 private taxDev = 2500;

    address public onlyWallet;

    uint256 public currentSupply;

    uint256 public transactionCount = 1;

    IVault Ivault;

    bool public tradingEnabled = false;

    uint256 public totalBurnt = 0 ;
    uint256 public totalVaultSupply;
    uint256 private previousVaultSupply;

    uint256 private txLimit = 1;

    ISaltzYard2 IsaltzYard;
    address saltzYard;

    event UserRegistered(
        address indexed user,
        address indexed referer,
        uint256 timestamp
    );
    event RefTx(uint8 refIndex,address child, address referer, uint256 amount);
    event Taxes(uint256 burnTax, uint256 devTax, uint256 rewardstax);
    event Burn(address account, uint256 amount, uint256 timestamp);
    event referalClaimed(address indexed user, uint256 amount);

    modifier ownerOrWallet(){
         require(msg.sender == owner() || msg.sender == onlyWallet, "not authorized");
    _;
    }

    constructor(string memory _symbol, string memory _name, address _devWallet) ERC20(_symbol, _name) {
        devWallet = _devWallet; //my 3rd wallet

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[msg.sender] = true;


        _mint(owner(), 41000000 * 10 ** decimals());

        currentSupply = totalSupply();

        vault = address(new Vault(address(this)));

        Ivault = IVault(vault);

        commision[0] = 500;
        commision[1] = 300;
        commision[2] = 200;
        commision[3] = 100;
        commision[4] = 50;
    }

    //-------------------------------------Public Methods--------------------------------//

    function includeAndExcludeFromFee(
        address account,
        bool value
    ) public ownerOrWallet {
        _isExcludedFromFee[account] = value;
    }

    function setOnlyWallet(address _address) public onlyOwner {
        onlyWallet = _address;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function getTrnx() public view returns (uint256) {
        return txLimit;
    }


    //-------------------------------------External Methods--------------------------------//


    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function setdevWallet(address _addr) external ownerOrWallet {
        devWallet = _addr;
    }

    function registerUser(address _user, address _referer) external {
        if (isRegistered[_user] == false) {
            _register(_user, _referer);
            emit UserRegistered(_user, _referer, block.timestamp);
        }
    }

    function transferRewardToYard() external ownerOrWallet {
        uint _amount = totalVaultSupply - previousVaultSupply; //recent changes
        IsaltzYard.notifyRewardAmount(_amount);
        previousVaultSupply = totalVaultSupply;
    }

    function addYard(address _yard) external onlyOwner {
        saltzYard = _yard;
        IsaltzYard = ISaltzYard2(_yard);
        Ivault.setUpdater(saltzYard);
        includeAndExcludeFromFee(_yard, true); //Recent changes
    }

    function updateTxLimit(uint256 _trnx) external ownerOrWallet {
        txLimit = _trnx;
    }

    function claimReferalReward() external {
        require(
            referalReward[msg.sender] > 0,
            "You don't own any referal reward yet"
        );
        uint256 toTransfer = referalReward[msg.sender];
        referalReward[msg.sender] = 0;
        super._transfer(address(this), msg.sender, toTransfer);
        emit referalClaimed(msg.sender, toTransfer);
    }

    receive() external payable {}


    //-------------------------------------Internal Methods--------------------------------//

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && !tradingEnabled) {
            require(tradingEnabled, "Trading is not enabled yet");
        }

        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            super._transfer(from, to, amount);
            takeFee = false;
        } else {
            ValuesOfAmount memory values = getValues(
                amount,
                _isExcludedFromFee[from],
                _isExcludedFromFee[to]
            );

            super._transfer(from, to, values.transferAmount); // amount transfer to recepient

            getTaxTransfer(values, from);
            transactionCount++;
        }
    }

    function taxWhale(uint256 _amount) internal view returns (uint16) {
        uint256 i = (_amount * 100) / currentSupply;
        uint16 whaleTax;
        if (i < 1) {
            whaleTax = 0;
        } else if (i >= 1 && i < 2) {
            whaleTax = 500;
        } else if (i >= 2 && i < 3) {
            whaleTax = 1000;
        } else if (i >= 3 && i < 4) {
            whaleTax = 1500;
        } else if (i >= 4 && i < 5) {
            whaleTax = 2000;
        } else if (i >= 5 && i < 6) {
            whaleTax = 2500;
        } else if (i >= 6 && i < 7) {
            whaleTax = 3000;
        } else if (i >= 7 && i < 8) {
            whaleTax = 3500;
        } else if (i >= 8 && i < 9) {
            whaleTax = 4000;
        } else if (i >= 9 && i < 10) {
            whaleTax = 4500;
        } else if (i >= 10) {
            whaleTax = 5000;
        }
        return whaleTax;
    }

    function _register(address _user, address _referer) internal {
        require(_user!=_referer,"You cannot refer yourself");
        parent[_user] = _referer;
        isRegistered[_user] = true;
        users.push(_user);
    }


    //-------------------------------------Private Methods--------------------------------//

    function getParent(address user) private view returns (address referer) {
        return parent[user];
    }

    function getTaxTransfer(
        ValuesOfAmount memory values,
        address sender
    ) private {
        uint8 i = 0;
        uint totalToTransfer = 0;
        address parentAddress = getParent(sender);
        while (parentAddress != address(0) && i <= 4) {
            uint256 tAmount = calculateTax(values.totalTax, commision[i]);
            referalReward[parentAddress] += tAmount;
            totalCommisionEarned[parentAddress] += tAmount;
            totalToTransfer += tAmount;
            values.totalTax -= tAmount;
            emit RefTx(i,sender, parentAddress, tAmount);
            parentAddress = getParent(parentAddress);
            i++;
        }

        super._transfer(sender, address(this), totalToTransfer); // sending commision to parents    += tAmount;
        totalToTransfer = 0;

        uint256 _totalTax = values.totalTax;
        uint256 BurnFee = calculateTax(_totalTax, taxBurn);
        uint256 RewardFee = calculateTax(_totalTax, taxReward);
        _totalTax = values.totalTax - (BurnFee + RewardFee);
        uint256 DevFee = _totalTax; //edit changes for devfee (done)

        super._transfer(sender, devWallet, DevFee); //dev Wallet

        super._transfer(sender, vault, RewardFee); //to reward wallet
        totalVaultSupply += RewardFee;

        super._transfer(sender, _burnAddress, BurnFee); //burning tokens
        currentSupply -= BurnFee;
        totalBurnt +=BurnFee;
        emit Burn(sender, BurnFee, block.timestamp);

        if (transactionCount % getTrnx() == 0) {
            uint _amount = totalVaultSupply - previousVaultSupply; //recent changes
            IsaltzYard.notifyRewardAmount(_amount);
            previousVaultSupply = totalVaultSupply;
        }

        emit Taxes(BurnFee, DevFee, RewardFee);
    }

    function getValues(
        uint256 amount,
        bool deductTransferFee,
        bool sender
    ) private view returns (ValuesOfAmount memory) {
        ValuesOfAmount memory values;
        values.amount = amount;
        if (!deductTransferFee && !sender) {
            // calculate fee
            uint16 taxWhale_ = taxWhale(values.amount);
            values.whaleFee = calculateTax(values.amount, taxWhale_);
            uint256 tempTotalTax = calculateTax(
                (values.amount - values.whaleFee),
                totalTax
            );
            values.totalTax = tempTotalTax + values.whaleFee;
            values.transferAmount = values.amount - values.totalTax;
        } else {
            values.whaleFee = 0;
            values.totalTax = 0;
            values.transferAmount = values.amount;
        }
        return values;
    }

    function calculateTax(
        uint256 amount,
        uint16 tax
    ) private pure returns (uint256) {
        return (amount * tax) / (10 ** 4);
    }
}
