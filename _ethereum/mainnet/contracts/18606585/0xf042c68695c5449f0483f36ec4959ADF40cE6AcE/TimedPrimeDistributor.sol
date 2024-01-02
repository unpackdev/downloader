// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./SafeERC20.sol";
import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";


contract TimedPrimeDistributor is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Address of PRIME contract.
    IERC20 public PRIME = IERC20(0xb23d80f5FefcDDaa212212F028021B41DEd428CF);
    uint public maxClaimPerAddress = 10000 ether;
    uint public startTime = 1696046400;
    uint public endTime = 1759204800;
    uint public runTime = 63158400;

    uint256 public totalClaimableInContract = 0;
    uint256 public constant primeAmountPerSecondPrecision = 1e18; // primeAmountPerSecond is carried around with extra precision to reduce rounding errors
    uint public primeAmountPerSecond = (maxClaimPerAddress * primeAmountPerSecondPrecision) / (endTime - startTime);

    mapping(address => uint256) public remainingAmounts;  // all initialized to 10k
    event Claim(address indexed receiver, uint256 indexed amount);


    constructor() {}

     function addAddresses(address[] calldata addresses) external onlyOwner {
         require(addresses.length > 0, "can't update zero");
         for (uint256 i = 0; i < addresses.length; ++i) {
            remainingAmounts[addresses[i]] = maxClaimPerAddress;
            totalClaimableInContract += maxClaimPerAddress;
         }
     }

    function getAmountUnlockedPerAddress() public view returns (uint){
        uint secondsRunning = block.timestamp - startTime;
        uint amountUnlocked = secondsRunning * primeAmountPerSecond / primeAmountPerSecondPrecision;

        return amountUnlocked;
    }

    function getAmountClaimableForAddress(address _address) public view returns (uint){
        uint amountClaimedAlready = maxClaimPerAddress - remainingAmounts[_address];
        uint amountUnlocked = getAmountUnlockedPerAddress();
        require(amountUnlocked >= amountClaimedAlready, "nothing to claim");

        return amountUnlocked - amountClaimedAlready;
    }

    function getAmountClaimedForAddress(address _address) public view returns (uint){
        require(remainingAmounts[_address]>0, "nothing to claim");
        return maxClaimPerAddress - remainingAmounts[_address];
    }

    function claimAllAvailable() public nonReentrant {
        uint256 maxClaimableAmount = getAmountClaimableForAddress(msg.sender);

        remainingAmounts[msg.sender] = remainingAmounts[msg.sender] - maxClaimableAmount;

        totalClaimableInContract -= maxClaimableAmount;
        PRIME.safeTransfer(msg.sender, maxClaimableAmount);
        emit Claim(msg.sender, maxClaimableAmount);
    }

    function claimSpecificAmount(uint256 amount) public nonReentrant {
        require(amount >= 1, "requested amount too small");
        uint256 maxClaimableAmount = getAmountClaimableForAddress(msg.sender);
        require(amount <= maxClaimableAmount, "amount not available");

        remainingAmounts[msg.sender] = remainingAmounts[msg.sender] - amount;

        totalClaimableInContract -= amount;
        PRIME.safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    function sweep(uint256 amount) external onlyOwner {
        PRIME.safeTransfer(msg.sender, amount);
    }
}
