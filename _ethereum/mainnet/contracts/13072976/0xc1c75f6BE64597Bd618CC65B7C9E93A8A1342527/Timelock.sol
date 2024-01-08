// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

/**
  Timelock contract.
  Fixed token payout and timing.
  Can add recipients and multiple grants per recipient.

  @author iain
  github.com/iainnash/simple-timelock
 */
contract Timelock {
    // From IERC20
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    /**
        Error codes lookup:
        1: Recover and recieve grant days need to be greater than 0
        2: Grant not valid.
        3: Only owner can add grants.
        4: Only owner can recover
        5: Cannot set the recovery grant before the unlock time
        6: Too early to recover
        7: Too early to claim
        8: Recover timestamp needs to be after receive timestamp
        9: Already granted
        10: Cannot grant after unlock
        11: Token not approved or not enough
        12: Invalid ownership
    */

    // Timestamp for when the recovery begins
    uint256 private immutable timeRecoverGrant;
    // Timestamp for when the receive begins
    uint256 private immutable timeReceiveGrant;
    // Owner that can recover grant and add new grant addresses
    address private immutable owner;
    // Token to lock
    IERC20 private immutable token;

    // Mapping of address to grant
    mapping(address => uint256) private grants;

    // Emitted when a claim is recovered
    event Recovered(address recipient, uint256 amount);

    // Emitted when a claim is claimed
    event Claimed(address actor, uint256 amount);

    // Emitted when a grant is added
    event GrantsAdded(address actor, address[] newRecipients);

    modifier onlyOwner() {
        require(msg.sender == owner, "3");
        _;
    }

    /**
        Sets up grant created by TimelockCreator Contract
     */
    constructor(
        address _owner,
        IERC20 _token,
        uint256 unlockTimestamp,
        uint256 recoverTimestamp
    ) {
        token = _token;
        owner = _owner;
        require(
            unlockTimestamp > block.timestamp &&
                recoverTimestamp > block.timestamp,
            "1"
        );
        require(recoverTimestamp > unlockTimestamp, "8");
        timeReceiveGrant = unlockTimestamp;
        timeRecoverGrant = recoverTimestamp;
    }

    /**
        Returns token for timelock and amount per recipient
     */
    function getToken() public view returns (IERC20) {
        return token;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    /** 
        Returns the time users can recieve the grant / when the timelock expires
     */
    function getTimeUnlock() public view returns (uint256) {
        return timeReceiveGrant;
    }

    /** 
        Returns the admin can recover unclaimed grants
     */
    function getTimeRecover() public view returns (uint256) {
        return timeRecoverGrant;
    }

    /**
        Proxied token information for bookkeeping / discoverability
        Not implemented:
            1. approvals
            2. transfers
            etc.
    */
    function balanceOf(address user) public view returns (uint256) {
        return grants[user];
    }

    function totalSupply() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function decimals() public view returns (uint8) {
        return IERC20Metadata(address(token)).decimals();
    }

    function name() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Timelocked ",
                    IERC20Metadata(address(token)).name()
                )
            );
    }

    function symbol() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "LOCK_",
                    IERC20Metadata(address(token)).symbol()
                )
            );
    }

    /** 
        @dev Adds a grant to the timelock
        Grants can be added at any time before claim period.
    */
    function addGrants(address[] memory newRecipients, uint256 grantSize)
        external
        onlyOwner
    {
        require(grantSize > 0, "2");
        require(getTimeUnlock() > block.timestamp, "10");
        require(
            token.allowance(msg.sender, address(this)) >=
                newRecipients.length * grantSize,
            "11"
        );

        uint256 numberRecipients = newRecipients.length;
        token.transferFrom(
            msg.sender,
            address(this),
            grantSize * numberRecipients
        );
        for (uint256 i = 0; i < numberRecipients; i++) {
            emit Transfer(address(0), newRecipients[i], grantSize);
            grants[newRecipients[i]] += grantSize;
        }
        emit GrantsAdded(owner, newRecipients);
    }

    /** 
        Returns the status of the grant.
     */
    function grantedAmount(address recipient) external view returns (uint256) {
        return grants[recipient];
    }

    /**
        Allows a user to claim their grant. Claimee has to be msg.sender.
     */
    function claim() external {
        address recipient = msg.sender;
        require(block.timestamp >= timeReceiveGrant, "7");
        uint256 grantAmount = grants[recipient];
        require(grantAmount > 0, "2");
        token.transfer(recipient, grantAmount);
        grants[recipient] = 0;
        // Emit grant claimed event
        emit Claimed(recipient, grantAmount);
        // Burn tracker token
        emit Transfer(recipient, address(0x0), grantAmount);
    }

    /**
        The owner of the grant can recover after the recovery timestamp passes.
        This sweeps remaining funds and destroys the contract data.
     */
    function recover() external onlyOwner {
        address payable sender = payable(msg.sender);
        require(block.timestamp >= timeRecoverGrant, "6");
        uint256 balance = token.balanceOf(address(this));
        emit Recovered(sender, balance);
        token.transfer(sender, balance);
        selfdestruct(sender);
    }
}
