pragma solidity 0.6.12;


interface StakingContract {
    function liquidityRewards(address recipient, uint amount) external;
}

contract Minter {
    
    mapping(address => bool) public minters;
    
    StakingContract public stakingContract;
    
    address public owner;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }
    
    constructor() public {
        stakingContract = StakingContract(0x738d3CEC4E685A2546Ab6C3B055fd6B8C1198093);
        owner = msg.sender;
    }
    
    function addMinter(address _minter) external onlyOwner {
        minters[_minter] = true;
    }
    
    function removeMinter(address _minter) external onlyOwner {
        delete minters[_minter];
    }
    
    function liquidityRewards(address recipient, uint amount) external {
        require(minters[msg.sender] == true);
        stakingContract.liquidityRewards(recipient, amount);
    }
    
    function updateStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = StakingContract(_stakingContract);
    }
}