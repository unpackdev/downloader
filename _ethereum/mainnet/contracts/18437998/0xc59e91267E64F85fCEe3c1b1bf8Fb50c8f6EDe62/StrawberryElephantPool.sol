pragma solidity 0.8.19;
import "./IERC20.sol";

contract StrawberryElephantPool {
    address public owner;
    IERC20 public token;
    uint public totalStake;
    uint public totalReward;
    mapping(address => uint) public balance;
    mapping(address => uint) public timestamp;

    constructor(address _address) {
        owner = msg.sender;
        token = IERC20(_address);
    }

    function stake(address staker, uint amount) external {
        require(totalReward == 0);
        require(msg.sender == address(token));
        balance[staker] += amount;
        timestamp[staker] = block.timestamp;
        totalStake += amount;
    }

    function unstake() external {
        require(block.timestamp > timestamp[msg.sender] + 86400);
        token.transfer(msg.sender, balance[msg.sender]);
        balance[msg.sender] = 0;
    }

    function claimReward() external {
        require(msg.sender == owner);
        msg.sender.call{
            value: (balance[msg.sender] / totalStake) * totalReward
        }("");
        timestamp[msg.sender] = block.timestamp;
    }

    function setReward() external payable {
        require(msg.sender == owner);
        totalReward = msg.value;
    }

    function recover() external {
        require(msg.sender == owner);
        owner.call{value: address(this).balance}("");
    }

    receive() external payable {}
}
