pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function price() external view returns (uint);

}

contract BigNumba is Ownable, ReentrancyGuard {
    address public numbaAddress;
    uint public biggest;
    uint public bounty;
    uint public biggestAt;

    uint public fee;
    uint public requiredDuration;
    uint public nextRoundFee;
    uint public nextRoundRequiredDuration;

    constructor() {
        fee = 0.02 ether;
        requiredDuration = 15 minutes;
        nextRoundFee = fee;
        nextRoundRequiredDuration = requiredDuration;
    }

    function setNumba(address _numbaAddress) public onlyOwner {
        require(numbaAddress == address(0));
        numbaAddress = _numbaAddress;
    }

    function setNextRoundFee(uint _nextRoundFee) public onlyOwner {
        require(_nextRoundFee >= 0.01 ether, "That's too little.");
        require(_nextRoundFee < IERC721(numbaAddress).price(), "That's too much.");

        nextRoundFee = _nextRoundFee;
    }
    
    function setNextRoundRequiredDuration(uint _nextRoundRequiredDuration) public onlyOwner {
        require(_nextRoundRequiredDuration > 5 minutes, "That's too quick.");
        require(_nextRoundRequiredDuration < 36 hours, "That's too much.");

        nextRoundRequiredDuration = _nextRoundRequiredDuration;
    }

    function IAmBiggest(uint _numbaId) public payable nonReentrant{
        require(fee == msg.value, "Pay to play.");
        require(IERC721(numbaAddress).ownerOf(_numbaId) == msg.sender);
        require(_numbaId > biggest);
        require(!awaitingWinnerClaim());
        biggestAt = block.timestamp;
        biggest = _numbaId;
        bounty += fee / 3;
    }

    function awaitingWinnerClaim() internal returns(bool) {
        if (biggest == 0) return false;
        return block.timestamp > biggestAt + requiredDuration;
    }

    function claimBounty() public nonReentrant {
        require(block.timestamp > biggestAt + requiredDuration);
        fee = nextRoundFee;
        requiredDuration = nextRoundRequiredDuration;

        if (block.timestamp < biggestAt + requiredDuration * 2) {
            address ownerOfBiggest = IERC721(numbaAddress).ownerOf(biggest);
            (bool success, ) = payable(ownerOfBiggest).call{value: bounty}("");
            require(success, "Transfer failed.");
        }

        biggestAt = block.timestamp;

        uint desired = IERC721(numbaAddress).price() * 6;
        if (desired > address(this).balance) {
            bounty = address(this).balance;
        } else {
            bounty = desired;
        }
    }

    function donateToBounty(uint amount) public payable nonReentrant {
        require(!awaitingWinnerClaim());
        require(amount == msg.value, "Hmm.");
        if (amount > bounty / 10) {
            biggestAt = block.timestamp;
        }
        bounty += amount;
    }

    function increaseBountyFromReserve(uint amount) public onlyOwner {
        require(!awaitingWinnerClaim());
        require(amount + bounty <= address(this).balance, "Not enough in reserve");
        if (amount > bounty / 10) {
            biggestAt = block.timestamp;
        }
        bounty += amount;
    }

    function nextRoundBounty() public view returns (uint) {
        uint desired = IERC721(numbaAddress).price() * 6;
        if (desired > address(this).balance - bounty) {
            return address(this).balance - bounty;
        } else {
            return desired;
        }
    }

    function futureRoundsBountyReserve() public view returns(uint) {
        return address(this).balance - bounty;
    }

    event Received(address, uint256);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}
