// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Updated SafeMath library for Solidity 0.8 and above.
 * The SafeMath library is no longer necessary from Solidity 0.8, as the compiler
 * now has built-in overflow checking.
 */

/**
 * @dev Ownable contract to set owner and modifiers
 */
contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

/**
 * @dev Implementation of the {IERC20} interface.
 * This implementation is a simplified version of OpenZeppelin's ERC20 contract,
 * with added fee functionality.
 */
contract TetherToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isBlackListed;

    uint256 private _totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint public basisPointsRate = 0;
    uint public maximumFee = 0;

    bool public paused = false;
    bool public deprecated = false;
    address public upgradedAddress;

    event Pause();
    event Unpause();
    event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    event Deprecate(address newAddress);
    event Params(uint feeBasisPoints, uint maxFee);
    event Issue(uint amount);
    event Redeem(uint amount);

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) {
        _totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        _balances[msg.sender] = initialSupply;
        deprecated = false;
    }

    function totalSupply() public view override returns (uint256) {
        if (deprecated) {
            return IERC20(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (deprecated) {
            return IERC20(upgradedAddress).balanceOf(account);
        } else {
            return _balances[account];
        }
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        require(!isBlackListed[msg.sender], "Account is blacklisted");
        if (deprecated) {
            return IERC20(upgradedAddress).transfer(recipient, amount);
        } else {
            _transfer(msg.sender, recipient, amount);
            return true;
        }
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        if (deprecated) {
            return IERC20(upgradedAddress).allowance(owner, spender);
        } else {
            return _allowances[owner][spender];
        }
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        if (deprecated) {
            return IERC20(upgradedAddress).approve(spender, amount);
        } else {
            _approve(msg.sender, spender, amount);
            return true;
        }
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        require(!isBlackListed[sender], "Account is blacklisted");
        if (deprecated) {
            return
                IERC20(upgradedAddress).transferFrom(sender, recipient, amount);
        } else {
            _transfer(sender, recipient, amount);
            _approve(
                sender,
                msg.sender,
                _allowances[sender][msg.sender] - amount
            );
            return true;
        }
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - subtractedValue
        );
        return true;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }

    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        require(newBasisPoints < 20, "Basis points rate too high");
        require(newMaxFee < 50, "Max fee too high");

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee * 10 ** decimals;

        emit Params(basisPointsRate, maximumFee);
    }

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds(address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser], "Address is not blacklisted");
        uint dirtyFunds = _balances[_blackListedUser];
        _balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply, "Overflows");
        require(_balances[owner] + amount > _balances[owner], "Overflows");

        _balances[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }

    function redeem(uint amount) public onlyOwner {
        require(_totalSupply >= amount, "Insufficient total supply");
        require(_balances[owner] >= amount, "Insufficient balance");

        _totalSupply -= amount;
        _balances[owner] -= amount;
        emit Redeem(amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        uint256 fee = (amount * basisPointsRate) / 10000;
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint256 sendAmount = amount - fee;

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + sendAmount;
        if (fee > 0) {
            _balances[owner] = _balances[owner] + fee;
            emit Transfer(sender, owner, fee);
        }
        emit Transfer(sender, recipient, sendAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
