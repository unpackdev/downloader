pragma solidity 0.7.6;

import "./IERC20.sol";
import "./ERC20.sol";

contract StakingContract is ERC20 {
    IERC20 public token;
    address public slasher;

    struct StakeWD {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => uint256) public totalStake;
    mapping(address => mapping(address => uint256)) public userStake;
    mapping(address => mapping(address => StakeWD)) public stakeWithdraw;
    mapping(address => mapping(string => string)) public data;

    uint public totalSlashed;
    mapping(address => uint256) public slash;

    event Staked(address indexed oracle, address indexed user, uint256 amount);
    event Unstaked(
        address indexed oracle,
        address indexed user,
        uint256 amount
    );
    event Slashed(address indexed oracle, uint256 amount);

    constructor(
        IERC20 _token,
        address _slasher,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        token = _token;
        slasher = _slasher;
    }

    function updateSlasher(address newSlasher) public {
        require(msg.sender == slasher, "Only current slasher can update");
        slasher = newSlasher;
    }

    function withdrawSlashedTokens(address receiver, uint amount) public {
        require(
            msg.sender == slasher,
            "Only slasher can withdraw slashed tokens"
        );
        require(totalSlashed >= amount, "Amount exceeds total slashed tokens");
        totalSlashed -= amount;
        token.transfer(receiver, amount);
    }

    function stakeTokens(address oracle, uint256 amount) public {
        require(amount > 0, "Staking amount should be greater than 0");
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Failed to transfer tokens"
        );

        userStake[oracle][msg.sender] += amount;
        totalStake[oracle] += amount;

        emit Staked(oracle, msg.sender, amount);
        _mint(msg.sender, amount);
    }

    function getstake(address oracle) public view returns (uint) {
        return (totalStake[oracle] - slash[oracle]);
    }

    function unstakeTokens(address oracle, uint amount) public {
        require(
            stakeWithdraw[oracle][msg.sender].unlockTime > 0,
            "No tokens to unstake"
        );
        require(
            stakeWithdraw[oracle][msg.sender].unlockTime <= block.timestamp,
            "Unlock time has not been reached"
        );
        require(
            stakeWithdraw[oracle][msg.sender].amount >= amount,
            "Insufficient tokens to unstake"
        );

        _applyPenaltiesAndTransfer(oracle, amount);
        _updateStakeBalances(oracle, amount);
    }

    function withdrawStake(address oracle, uint amount) public {
        require(
            userStake[oracle][msg.sender] >= amount,
            "Insufficient tokens to withdraw"
        );
        require(
            balanceOf(msg.sender) >= amount,
            "Insufficient tokens to withdraw"
        );

        _burn(msg.sender, amount);
        stakeWithdraw[oracle][msg.sender].amount += amount;
        stakeWithdraw[oracle][msg.sender].unlockTime = block.timestamp + 7 days;

        emit Unstaked(oracle, msg.sender, amount);
    }

    function slashOracle(address oracle, uint256 amount) public {
        require(msg.sender == slasher, "Only slasher can slash");
        require(
            totalStake[oracle] >= amount,
            "Not enough tokens staked to slash"
        );

        slash[oracle] += amount;
        emit Slashed(oracle, amount);
    }

    function setKeyValue(string memory key, string memory value) public {
        data[msg.sender][key] = value;
    }

    // Internal Functions
    function _applyPenaltiesAndTransfer(address oracle, uint amount) internal {
        uint slashedAmount = (amount * slash[oracle]) / totalStake[oracle];
        uint transferableAmount = amount - slashedAmount;

        slash[oracle] -= slashedAmount;
        totalSlashed += slashedAmount;

        token.transfer(msg.sender, transferableAmount);
    }

    function _updateStakeBalances(address oracle, uint amount) internal {
        userStake[oracle][msg.sender] -= amount;
        totalStake[oracle] -= amount;

        stakeWithdraw[oracle][msg.sender].amount -= amount;
        stakeWithdraw[oracle][msg.sender].unlockTime = 0;
    }
}
