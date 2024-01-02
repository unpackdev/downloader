/**
*/

//  SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: BetPool.sol

pragma solidity ^0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RevShare is Ownable {
    event RewardAdded(uint256 _amount);
    event CalculateDividends();

    uint256 public totalEarnings;
    uint256 public totalBalance;
    mapping (address => uint256) public userBalances;
    mapping (address => uint256) public userDividends;
    mapping (address => uint256) public lastDepositTime;
    mapping (address => bool) public whitelist;
    address[] public userAddresses;
    IERC20 public tokenPlay;
    IERC20 public tokenCheck;
    uint256 public MINIMUM_TIME_FRAME = 7 days;
    uint public maxAmountInToken;
    uint public minAmountInToken;
    uint public cantPlayers;
    uint public maxPlayers;
    uint public qtyOfBBUD;

    constructor(address _tokenPlay, address _tokenCheck) {
        tokenPlay = IERC20(_tokenPlay);
        tokenCheck = IERC20(_tokenCheck);
        minAmountInToken = 100000000;
        maxAmountInToken = 500000000;
        maxPlayers = 500;
        cantPlayers = 0;
        qtyOfBBUD = 1000000000000000;
        whitelist[msg.sender] = true;
    }

    function deposit(uint256 _amount) public {
        require(_amount > 0, "Deposit amount must be greater than 0");
        require(_amount <= maxAmountInToken, "Deposit amount must be less than max");
        require(_amount >= minAmountInToken, "Deposit amount must be more than min");
        require(cantPlayers < maxPlayers, "Max Players");
        require(tokenPlay.balanceOf(msg.sender) >= _amount, "You dont have enough tokens");
        require(whitelist[msg.sender] || tokenCheck.balanceOf(msg.sender) >= qtyOfBBUD, "You dont have enough BBUD");

        userBalances[msg.sender] += _amount;
        tokenPlay.transferFrom(msg.sender, address(this), _amount);
        totalBalance += _amount;
        lastDepositTime[msg.sender] = block.timestamp;
        userAddresses.push(msg.sender);
        cantPlayers++;
    }

    function depositOwner(uint256 _amount, address _addy) onlyOwner public  {
        require(_amount > 0, "Deposit amount must be greater than 0");
        require(_amount <= maxAmountInToken, "Deposit amount must be less than max");
        require(_amount >= minAmountInToken, "Deposit amount must be more than min");
        require(cantPlayers < maxPlayers, "Max Players");

        userBalances[_addy] += _amount;
        tokenPlay.transferFrom(msg.sender, address(this), _amount);
        totalBalance += _amount;
        lastDepositTime[_addy] = block.timestamp;
        userAddresses.push(_addy);
        cantPlayers++;
    }

    function addRewards(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Rewards amount must be greater than 0");
        totalEarnings += _amount;
        emit RewardAdded(_amount);
    }

    function calculateDividends() public onlyOwner {
        require(totalEarnings > 0, "No earnings to distribute");
        uint256 walletCount = userAddresses.length;

        for (uint256 i = 0; i < walletCount; i++) {
            address user = userAddresses[i];
            uint256 userBalance = userBalances[user];
            uint userDividensDivident = userBalance * totalEarnings;
            userDividends[user] = userDividensDivident / totalBalance ;
        }
        totalEarnings = 0;
        emit CalculateDividends();
    }

    function claimDividends() public {
        uint256 claimedAmount = userDividends[msg.sender];
        require(claimedAmount > 0, "No dividends to claim");
        bool approve_done = tokenPlay.approve(address(this), claimedAmount);
        require(approve_done, "CA cannot approve tokens");
        tokenPlay.transferFrom(address(this), msg.sender, claimedAmount);
        userDividends[msg.sender] = 0;
    }

    function withdraw() public {
        uint amount = userBalances[msg.sender];
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(block.timestamp >= lastDepositTime[msg.sender] + MINIMUM_TIME_FRAME, "Withdrawal must wait 7 days from your last deposit");
        bool approve_done = tokenPlay.approve(address(this), amount);
        require(approve_done, "CA cannot approve tokens");

        tokenPlay.transferFrom(address(this), msg.sender, amount);

        totalBalance -= amount;
        userBalances[msg.sender] = 0;
        cantPlayers--;
    }

    function setOptions(uint _maxAmountInToken, uint _minAmountInToken, uint _maxPlayers, uint _cantPlayers, uint _qtyOfBBUD) onlyOwner public {
        maxAmountInToken = _maxAmountInToken;
        minAmountInToken = _minAmountInToken;
        maxPlayers = _maxPlayers;
        cantPlayers = _cantPlayers;
        qtyOfBBUD = _qtyOfBBUD;
    }

    function setWhitelist(address _addy, bool _option) onlyOwner public {
        whitelist[_addy] = _option;
    }

    function setFrameDays(uint _days) onlyOwner public {
        MINIMUM_TIME_FRAME = _days * 24 * 60 * 60;
    }

    function unstuck(uint256 _amount, address _addy) onlyOwner public {
        if (_addy == address(0)) {
            (bool sent,) = address(msg.sender).call{value: _amount}("");
            require(sent, "funds has to be sent");
        } else {
            bool approve_done = IERC20(_addy).approve(address(this), IERC20(_addy).balanceOf(address(this)));
            require(approve_done, "CA cannot approve tokens");
            require(IERC20(_addy).balanceOf(address(this)) > 0, "No tokens");
            IERC20(_addy).transfer(msg.sender, _amount);
        }
    }
}