// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract ZKTRWhiteList is Ownable, Pausable, Initializable {
    using SafeERC20 for IERC20;

    event Deposit(uint round, address indexed user, uint256 amount);
    event Burn(uint round, address indexed user, uint256 amount);

    IERC20 public zktrToken;
    IERC20 public srcToken;
    uint public round = 1;
    uint rate = 100;

    // The sum of all users for round
    mapping(uint => uint) public totalDeposits;
    mapping(uint => uint) public totalWhites;

    // A single user
    mapping(uint => mapping(address => uint)) public deposits;
    mapping(uint => mapping(address => uint)) public whites;
    mapping(uint => address[]) public accounts;

    uint private locked;
    modifier lock() {
        require(locked == 0, 'ZKTRWhiteList: LOCKED');
        locked = 1;
        _;
        locked = 0;
    }

    constructor (address zktrToken_, address srcToken_) {
        zktrToken = IERC20(zktrToken_);
        srcToken = IERC20(srcToken_);
    }

    function initialize(address zktrToken_, address srcToken_, address owner_) external initializer {
        zktrToken = IERC20(zktrToken_);
        srcToken = IERC20(srcToken_);
        _initOwner(owner_);
        round = 1;
        rate = 100;
    }

    function deposit(uint amount) external whenNotPaused lock {
        require(amount > 0, "ZKTRWhiteList: amount is zero");
        srcToken.safeTransferFrom(msg.sender, address(this), amount);
        deposits[round][msg.sender] = deposits[round][msg.sender] + amount;
        totalDeposits[round] = totalDeposits[round] + amount;
        if (whites[round][msg.sender] == 0) {
            accounts[round].push(msg.sender); 
        }
        whites[round][msg.sender] = whites[round][msg.sender] + amount / rate;
        totalWhites[round] = totalWhites[round] + amount / rate;
        
        emit Deposit(round, msg.sender, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
        round += 1;
    }

    function whiteList() public view returns(address[] memory addrs, uint256[] memory amounts) {
        amounts = new uint[](accounts[round].length);
        addrs = accounts[round];
        for (uint i = 0; i < accounts[round].length; i++) {
            amounts[i] = whites[round][accounts[round][i]];
        }
    }

    function burn() external onlyOwner {
        for (uint i = 0; i < accounts[round].length; i++) {
            uint value = whites[round][accounts[round][i]];
            whites[round][accounts[round][i]] = 0;
            emit Burn(round, accounts[round][i], value);
        }
    }
}