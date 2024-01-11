pragma solidity ^0.8.7;

import "./IERC20.sol";

contract TokenCrowdsale {

    event Allocated(address buyer, uint256 amount);

    mapping(address => uint256) public buyerToAllocation;
    uint256 public from;
    uint256 public to;
    IERC20 public token;
    IERC20 public asset;
    uint256 public rate;
    bool public isPaused;
    address private owner;
    uint256 private toClaim;

    constructor (IERC20 _asset) {
        owner = msg.sender;
        asset = _asset;
        rate = 40000000000000; // TODO (MUST) 40000000000000 EVERYWHERE BESIDES BSC WHERE IS 40 !!!!!!!!!!!!!!! BECAUSE OF 18 DIGIT USDC ON BSC
        from = 1656914400;
        to = 1658124000;
    }

    function deposit(uint256 amount) external {
        require(isPaused == false && amount > 0);
        uint256 timestamp = block.timestamp;
        require((timestamp >= from && timestamp <= to) || msg.sender == owner); // For final (just before sale) test
        uint256 remaining = getRemaining();
        uint256 allocated = rate * amount;
        require(remaining >= allocated);
        require(asset.allowance(msg.sender, address(this)) >= amount);
        asset.transferFrom(msg.sender, address(this), amount);
        buyerToAllocation[msg.sender] += allocated;
        toClaim += allocated;
    }

    function setToken(IERC20 _token) external {
        require(msg.sender == owner && address(token) == address(0));
        token = _token;
    }

    function withdrawAllocation() external {
        uint256 allocation = buyerToAllocation[msg.sender];
        require(allocation > 0 && block.timestamp > to);
        token.transfer(msg.sender, allocation);
        toClaim -= allocation;
        buyerToAllocation[msg.sender] = 0;
    }

    function withdrawDeposited() external {
        require(msg.sender == owner && block.timestamp > to);
        uint256 deposited = asset.balanceOf(address(this));
        asset.transfer(owner, deposited);
    }

    function withdrawRemaining() external {
        require(msg.sender == owner && block.timestamp > to);
        uint256 remaining = getRemaining();
        token.transfer(owner, remaining);
    }

    function getRemaining() public view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        return balance - toClaim;
    }

    function togglePause() external {
        require(msg.sender == owner);
        isPaused = !isPaused;
    }

    receive() external payable {}
}