// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC777.sol";
import "./IERC777Recipient.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC1820Registry.sol";

contract TimeLock is Ownable, IERC777Recipient {

    using SafeMath for uint256;

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
	bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    
    IERC777 dmccToken;

    address dmccTokenClaimRecipient;

    address dmccTokenRefundRecipient;

    event TokensReceived(address from, uint256 amount);

    struct TimeLockedAmount {
		uint256 releaseTime;
		uint256 amount; 
	}

    TimeLockedAmount[] private timeLockedAmounts;

    constructor(address _dmccTokenAddress, address _dmccTokenClaimRecipient, address _dmccTokenRefundRecipient)
        Ownable(msg.sender)
    {
        require(_dmccTokenAddress != address(0), "Invalid token address");

        dmccToken = IERC777(_dmccTokenAddress);
        dmccTokenClaimRecipient = _dmccTokenClaimRecipient;    
        dmccTokenRefundRecipient = _dmccTokenRefundRecipient;

        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    function tokenName() external view returns (string memory) {
        return dmccToken.name();
    }

    function tokenSymbol() external view returns (string memory) {
        return dmccToken.symbol();
    }

    function claimRecipient() public view virtual returns (address) {
		return dmccTokenClaimRecipient;
	}

    function refundRecipient() public view virtual returns (address) {
		return dmccTokenRefundRecipient;
	}

    function tokensReceived(
        address,
        address from,
        address,
        uint256 amount,
        bytes calldata,
        bytes calldata
    ) external {
        require(msg.sender == address(dmccToken), "Tokens received from invalid token");

        TimeLockedAmount storage lockedAmount = timeLockedAmounts.push();
        lockedAmount.releaseTime = block.timestamp + (24 hours);
		lockedAmount.amount = amount;

        emit TokensReceived(from, amount);

    }

    function nextClaimSchedule() public view returns (uint256) {
        if(timeLockedAmounts.length < 1){
            return 0;
        } 

        return timeLockedAmounts[0].releaseTime;
    }

    modifier onlyClaimRecipient() {
        require(msg.sender == dmccTokenClaimRecipient, "You are not allowed to claim tokens");
        _;
    }

    modifier contractBalanceShouldBeMoreThanZero() {
        require(dmccToken.balanceOf(address(this)) > 0, "No tokens to claim");
        _;
    }    

    function claimTokens() external onlyClaimRecipient contractBalanceShouldBeMoreThanZero {
        
        uint256 totalClaimableAmount;

        TimeLockedAmount[] storage temp = timeLockedAmounts;

        for(uint256 i = 0; i < temp.length; i++) {
            TimeLockedAmount storage lockedAmount = temp[i];
            if(lockedAmount.releaseTime < block.timestamp){
                totalClaimableAmount += lockedAmount.amount;
                removeLockedAmount(i);
                break;
            }
        }

        require(totalClaimableAmount > 0, "Tokens are still locked");

        dmccToken.send(dmccTokenClaimRecipient, totalClaimableAmount, "");

    }

    function refundUnclaimedTokens() external onlyOwner {

        uint256 totalUnclaimedAmount;

        for(uint256 i = 0; i < timeLockedAmounts.length; i++) {
            TimeLockedAmount storage lockedAmount = timeLockedAmounts[i];
            if(lockedAmount.releaseTime < block.timestamp){
                totalUnclaimedAmount += lockedAmount.amount;
                removeLockedAmount(i);
                break;
            }
        }

        require(totalUnclaimedAmount > 0, "No available unclaimed tokens to be refunded");

        dmccToken.send(dmccTokenRefundRecipient, totalUnclaimedAmount, "");
        
    }

    function removeLockedAmount(uint256 index) internal {

        for (uint256 i = index; i < timeLockedAmounts.length - 1; i++) {
            timeLockedAmounts[i] = timeLockedAmounts[i + 1];
        }

        timeLockedAmounts.pop();

    }

}