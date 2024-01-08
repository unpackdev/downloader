//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./SnoToken.sol";
import "./Ownable.sol";

contract Auction is Ownable {
    
    uint256 public constant DAILY_SNOW = 10000 * 1e18; // Daily snow distrubition
    uint256 public constant START = 1637596800; // Nov 23, 2021 @ 00:00 GMT +8
    uint256 public constant MIN_ETH = 25 * 1e15;
    uint256 public bidID = 0;
    uint256 public totalEthAllocated = 0;
    address public constant OWNER_SAFE = 0xfF51ad7430d623df4daa02EFF0295cf217D597e3;

    mapping(uint => uint) public roundETH;
    // Address -> Round ID -> Contributions
    mapping(address => mapping(uint => uint)) public bidders;
    // Address -> Round ID -> Claimed
    mapping(address => mapping(uint => uint)) public claimed;
    // Address -> Array of round ID unclaimed
    mapping(address => uint[]) public unClaimed;

    SnoToken public token;

    event Allocate(uint256 indexed bidID, uint256 roundID, address bidder, uint256 amount);

    constructor(SnoToken _token) {
        token = _token;
    }

    modifier saleIsOpen {
        require(START <= block.timestamp, "Auction not started");
        _;
    }

    function allocate() public payable saleIsOpen {
        require(msg.value >= MIN_ETH, "ETH must be more than 0.025.");
        uint256 roundID = getRoundID();
        roundETH[roundID] += msg.value;
        totalEthAllocated += msg.value;
        if(bidders[msg.sender][roundID] == 0){
            unClaimed[msg.sender].push(roundID);
        }
        bidders[msg.sender][roundID] += msg.value;
        bidID += 1;
        emit Allocate(bidID, roundID, msg.sender, msg.value);
    }

    function claim() public saleIsOpen {
        uint256 totalRewards = 0;
        bool current = false;
        for (uint i = 0 ; i < unClaimed[msg.sender].length; i++) {
            uint256 roundID = unClaimed[msg.sender][i];
            if(roundID != getRoundID()){
                totalRewards += rewards(msg.sender, roundID);
                claimed[msg.sender][roundID] = bidders[msg.sender][roundID];
            } else {
                current = true;
            }
        }

        delete unClaimed[msg.sender];
        if(current){
            unClaimed[msg.sender].push(getRoundID());
        }

        require(totalRewards > 0, 'Rewards must be more than 0.');
        if(token.balanceOf(address(this)) < totalRewards){
            token.mint(address(this), DAILY_SNOW + totalRewards); 
        }
        token.transfer(msg.sender, totalRewards);
    }

    function unclaimedTotal(address _address) public view returns (uint256) {
        uint256 totalRewards = 0;
        for (uint i = 0 ; i < unClaimed[_address].length; i++) {
            uint256 roundID = unClaimed[_address][i];
            // Don't add current round
            if(roundID != getRoundID()){
                totalRewards += rewards(_address, roundID);
            }
        }
        return totalRewards;
    }

    function rewards(address _address, uint256 _roundID) public view returns (uint256) {
        if(roundETH[_roundID] == 0){
            return 0;
        }
        return ( bidders[_address][_roundID] - claimed[_address][_roundID] ) * DAILY_SNOW / roundETH[_roundID];
    }

    function rewardsCredited(address _address, uint256 _roundID) public view returns (uint256) {
        if(roundETH[_roundID] == 0){
            return 0;
        }
        return bidders[_address][_roundID] * DAILY_SNOW / roundETH[_roundID];
    }

    function getRoundID() public view returns (uint256){
        if(block.timestamp < START){
            return 0;
        }
        return ((block.timestamp - START) / 1 days) + 1;
    }

    function getRoundEndTime() public view returns (uint256){
        uint256 roundID = getRoundID();
        return START + (1 days * (roundID));
    }

    function withdrawAll() public payable onlyOwner {
        require(address(this).balance > 0);
        _withdraw(OWNER_SAFE, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
