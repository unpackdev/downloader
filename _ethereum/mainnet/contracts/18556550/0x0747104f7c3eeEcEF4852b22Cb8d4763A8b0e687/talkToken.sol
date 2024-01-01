// SPDX-License-Identifier: MIT

/*

This contract is part of a system designed to offer a new way to form communities, collaborate on projects, and combine forces to defeat evil. 

talkOnlineToken deploys TALK, an ERC20 token implementing a 24 hr time lock owners can choose to place onto their tokens.

*/

pragma solidity ^0.8.0;
import "./ERC20.sol";

/**
 * @title Talk Online Token
 * @dev This contract deploys the TALK ERC20 token with an added 24hr time lock feature for participants.
 */
contract talkOnlineToken is ERC20 {

    // Mapping of addresses to their last voting timestamps
    mapping(address => uint256) public lastVoteTime;

    /**
     * @dev Constructor that gives the msg.sender all of the initial supply.
     */
    constructor() ERC20("Talk.Online", "TALK") {
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }
    /**
     * @dev Locks the token transferability of the caller for 24 hours after participating in a vote.
     */
    function voteLock() public {
        lastVoteTime[tx.origin] = block.timestamp;
    }

    /**
     * @notice Checks whether an address can transfer their tokens based on the voting time lock.
     * @param _from Address to check.
     * @return bool True if the address can transfer, false otherwise.
     */
    function canTransfer(address _from) public view returns (bool) {
        // Check if user has ever voted
        if (lastVoteTime[_from] == 0) {
            return true;
        }
        return (block.timestamp >= lastVoteTime[_from] + 1 days);
    }

    /**
     * @dev Overrides the default transfer function to include a time-lock check.
     * Token locking enables forums built with the token to lock funds, preventing re-use of tokens to vote repeatedly.
     * @param sender Address sending the tokens.
     * @param recipient Address receiving the tokens.
     * @param amount Amount of tokens to transfer.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(canTransfer(sender), "Too soon since last participation");
        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev Makes display better
     * @param addy Address being queried
     * @return amount Amount of tokens owner has
     */
    function getLastVoteTime(address addy) public view returns(uint){
        return lastVoteTime[addy];
    }
}