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

    address dmccTokenRecipient;

    event TokensReceived(address from, uint256 amount);

    struct TimeLockedAmount {
		uint256 releaseTime;
		uint256 amount; 
	}

    TimeLockedAmount[] private timeLockedAmounts;

    constructor(address _dmccTokenAddress, address _dmccTokenRecipient)
        Ownable(msg.sender)
    {
        require(_dmccTokenAddress != address(0), "Invalid token address");

        dmccToken = IERC777(_dmccTokenAddress);
        dmccTokenRecipient = _dmccTokenRecipient;    

        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    function tokenName() external view returns (string memory) {
        return dmccToken.name();
    }

    function tokenSymbol() external view returns (string memory) {
        return dmccToken.symbol();
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

	function remainingClaims() public view returns (uint256) {
		return timeLockedAmounts.length;
	}

    function nextClaimSchedule() public view returns (uint256) {
        if(timeLockedAmounts.length < 1){
            return 0;
        } 

        return timeLockedAmounts[0].releaseTime;
    }

    modifier onlyRecipient() {
        require(msg.sender == dmccTokenRecipient, "You are not allowed to claim tokens");
        _;
    }

    modifier contractBalanceShouldBeMoreThanZero() {
        require(dmccToken.balanceOf(address(this)) > 0, "No tokens to claim");
        _;
    }    

    function contractBalance() public  view  returns (uint256) {
        return dmccToken.balanceOf(address(this));
    }

    function claimTokens() external onlyRecipient contractBalanceShouldBeMoreThanZero {
        
        uint256 totalClaimableAmount;

        TimeLockedAmount[] storage temp = timeLockedAmounts;

        for(uint256 i = 0; i < temp.length; i++) {
            TimeLockedAmount storage lockedAmount = temp[i];
            if(lockedAmount.releaseTime < block.timestamp){
                totalClaimableAmount += lockedAmount.amount;
                removeLockedAmount(i);
            }
        }

        require(totalClaimableAmount > 0, "Tokens are still locked");

        dmccToken.send(dmccTokenRecipient, totalClaimableAmount, "");

    }

    function removeLockedAmount(uint256 index) internal {

        for (uint256 i = index; i < timeLockedAmounts.length - 1; i++) {
            timeLockedAmounts[i] = timeLockedAmounts[i + 1];
        }

        timeLockedAmounts.pop();

    }

}