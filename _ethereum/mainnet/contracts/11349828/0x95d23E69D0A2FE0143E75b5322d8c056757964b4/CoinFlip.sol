pragma solidity 0.7.5;

contract CoinFlip {
    event Deposit (address indexed from, uint256 value);
    
    address public constant owner = 0xc50E2f552C17F1b3348f882f43942006e77BFf66;
    
    function depositBalance() public payable {
        require(msg.sender == owner);
    }
    
    function withdrawBalance(uint256 amount) public {
        require(msg.sender == owner, "Only owner can withdraw balance");
        msg.sender.transfer(amount);
    }
    
    function flip() public payable {
        require(msg.value == 0.001 * 1e18, "You have to send exactly 0.001 ETH");
        require(msg.sender != owner, "Owner can't flip");
        
        if (rand() < 4750) {
            msg.sender.transfer(0.002 * 1e18);
        } else {
            msg.sender.transfer(0.00001337 * 1e18);
        }
    }
    
    
    int private randNonce = 0;
    function rand() private returns (int) {
        randNonce++;
        return int(uint(keccak256(abi.encodePacked(block.difficulty, msg.sender, block.timestamp, randNonce))) % 10000);
    }
}