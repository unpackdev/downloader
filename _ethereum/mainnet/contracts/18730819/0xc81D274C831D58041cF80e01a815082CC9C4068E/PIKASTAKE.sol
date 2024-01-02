// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

interface IPIKA {
    function transfer(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
}

contract PIKASTAKE {

    address public constant PIKA = 0xa9D54F37EbB99f83B603Cc95fc1a5f3907AacCfd;

    uint256 public constant blockReward = 1600000 * (10 ** 18);

    uint256 public constant SCALE = 10 ** 18;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public accruedInitialPIKA;

    uint256 public accruedPIKA;
    uint256 public totalStaked;

    uint256 public blockLastUpdate;
    uint256 public blockLastReward;

    event Stake(address indexed staker, uint256 amount);
    event Unstake(address indexed staker, uint256 amount);
    event Restake(address indexed staker, uint256 reward);
    event Claim(address indexed staker, uint256 reward);

    event Accrue(uint256 accruedPIKA);

    constructor() {
        accruedPIKA = 10 ** 18;
        totalStaked = 10 ** 18;

        blockLastUpdate = block.number + 100800;
        blockLastReward = block.number + 7988736;
    }

    function stake(uint256 amount) public {
        restake();

        balances[msg.sender] += amount;

        totalStaked += amount;

        IPIKA(PIKA).transferFrom(msg.sender, address(this), amount);

        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        restake();

        balances[msg.sender] -= amount;

        totalStaked -= amount;

        IPIKA(PIKA).transfer(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    function unstakeAll() public {
        unstake(balances[msg.sender] + unclaimed(msg.sender));
    }

    function restake() public {
        accrue();

        uint256 accruedProfit = accruedPIKA - accruedInitialPIKA[msg.sender];

        uint256 reward = (accruedProfit * balances[msg.sender]) / SCALE;

        balances[msg.sender] += reward;

        totalStaked += reward;

        accruedInitialPIKA[msg.sender] = accruedPIKA;

        emit Restake(msg.sender, reward);
    }

    function claim() public {
        accrue();

        uint256 accruedProfit = accruedPIKA - accruedInitialPIKA[msg.sender];

        uint256 reward = (accruedProfit * balances[msg.sender]) / SCALE;

        accruedInitialPIKA[msg.sender] = accruedPIKA;

        IPIKA(PIKA).transfer(msg.sender, reward);

        emit Claim(msg.sender, reward);
    }

    function accrue() public {

        if (blockLastUpdate < block.number) {

            uint256 blockDistance;

            if (block.number < blockLastReward) {
                blockDistance = block.number - blockLastUpdate;
                blockLastUpdate = block.number;
            } else {
                blockDistance = blockLastReward - blockLastUpdate;
                blockLastUpdate = type(uint256).max;
            }

            accruedPIKA += (blockReward * blockDistance * SCALE) / totalStaked;

            emit Accrue(accruedPIKA);
        }
    }

    function unclaimed(address staker) public view returns(uint256 reward) {

        uint256 accruedHypotheticalPIKA = accruedPIKA;

        if (blockLastUpdate < block.number) {

            uint256 blockDistance;

            if (block.number < blockLastReward) {
                blockDistance = block.number - blockLastUpdate;
            } else {
                blockDistance = blockLastReward - blockLastUpdate;
            }

            accruedHypotheticalPIKA += (blockReward * blockDistance * SCALE) / totalStaked;
        }

        uint256 accruedProfit = accruedHypotheticalPIKA - accruedInitialPIKA[staker];

        reward = (accruedProfit * balances[staker]) / SCALE;

        return reward;
    }

    function apr() public view returns(uint256 rate) {
        return (420690000000000 * (10 ** 18)) / totalStaked;
    }
}