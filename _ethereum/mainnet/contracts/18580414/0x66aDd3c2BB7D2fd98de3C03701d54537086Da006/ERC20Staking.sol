/**
 *Submitted for verification at Etherscan.io on 2023-10-22
*/

pragma solidity ^0.8.0;

interface ERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract ERC20Staking {
    ERC20 public tokenA;
    ERC20 public tokenB;

    address owner;
    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint256) public stakedA;
    mapping(address => uint256) public stakedB;

    mapping(address => bool) public staked;
    uint256 public totalStaked;

    event Staked(address indexed staker, uint256 amount);
    event Withdrawn(address indexed staker, uint256 amount);

    constructor(address _tokenAddressA, address _tokenAddressB) {
        tokenA = ERC20(_tokenAddressA);
        tokenB = ERC20(_tokenAddressB);
        owner = msg.sender;
    }

    function stake(uint256 _amount, uint256 _amountB) external {
        require(stakes[msg.sender].amount == 0, "Already staked");
        require(
            tokenA.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        require(
            tokenB.transferFrom(msg.sender, owner, _amountB),
            "Transfer failed"
        );

        stakes[msg.sender] = Stake({
            amount: _amount,
            startTime: block.timestamp
        });

        totalStaked += _amount;
        stakedA[msg.sender] = _amount;
        stakedB[msg.sender] = _amountB;

        emit Staked(msg.sender, _amount);
    }

    function unStake() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");

        uint256 stakedAmount = userStake.amount;
        delete stakes[msg.sender];
        totalStaked -= stakedAmount;

        require(tokenA.transfer(msg.sender, stakedAmount), "Transfer failed");

        emit Withdrawn(msg.sender, stakedAmount);
    }
}