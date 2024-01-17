// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";

error NotAllowed();
error InvalidAddress();
error WhiteHatOnly();

error NotWithinLockPeriod();
error NotAfterLockExpires();

error AlreadyLocked();
error ContractLocked();

contract HTLCLocked is Ownable, ReentrancyGuard {
    uint256 public constant LOCK_TIME = 43200 seconds; // 12 hours

    // Indicates the start of the lock period (the most recent fund time).
    uint256 public startTime;

    // The current bounty amount (independent of contract balance).
    uint256 public amount;

    // The white hat determines which address the bounty will be paid out to.
    address payable public whiteHat = payable(0x1a38e21bE7768201D3feD2FA54f3BFBdC6056096);
    // The NFT contract which will have its ownership transferred
    address public constant NFT_CONTRACT = 0x40f5434cbED8ac30a0A477a7aFc569041B3d2012;
    // The new owner of the NFT contract
    address public newOwner = 0xB48495B000e82bF4bCbDEe17997a70146964d601;

    // If the HTLC contract has been permanently locked.
    bool public IS_LOCKED;

    // Prevent HTLC ownership transfers.
    function renounceOwnership() public override onlyOwner {
        revert NotAllowed();
    }
    function transferOwnership(address) public override onlyOwner nonReentrant {
        revert NotAllowed();
    }

    // 1) Team calls to fund bounty, this sets the start of the time lock period.
    function fund() external payable onlyOwner nonReentrant {
        if (IS_LOCKED) {
            revert ContractLocked();
        }

        startTime = block.timestamp;
        amount += msg.value;
    }

    // 2) White hat transfers ownership of NFT contract to HTLC contract
    // 3) White hat calls withdraw() to withdraw bounty
    function withdraw(address recipient) external nonReentrant {
        if (IS_LOCKED) {
            revert ContractLocked();
        }

        // Make sure only the white hat can call within the lock period
        if (msg.sender != whiteHat) {
            revert WhiteHatOnly();
        }
        if (
            block.timestamp < startTime ||
            block.timestamp > (startTime + LOCK_TIME)
        ) {
            revert NotWithinLockPeriod();
        }

        // Transfer ownership to new owner before bounty
        Ownable(NFT_CONTRACT).transferOwnership(newOwner);
        // Pay out bounty to the white hat's designated recipient.
        payable(recipient).transfer(amount);

        // Reset
        _resetContract();
    }

    // Reset / refund mechanisms if time lock expires
    function refund() external onlyOwner nonReentrant {
        if (block.timestamp < (startTime + LOCK_TIME)) {
            revert NotAfterLockExpires();
        }

        // Reset
        _resetContract();
    }
    function resetContractOwnerAndRefund() external onlyOwner nonReentrant {
        if (IS_LOCKED) {
            revert ContractLocked();
        }
        if (block.timestamp < (startTime + LOCK_TIME)) {
            revert NotAfterLockExpires();
        }

        // Transfer ownership
        Ownable(NFT_CONTRACT).transferOwnership(newOwner);

        // Reset
        _resetContract();
    }

    // Setters
    function setWhiteHat(address _whiteHat) external onlyOwner nonReentrant {
        // Make sure the white hat is a valid and unique address
        if (
            _whiteHat == address(0) ||
            _whiteHat == address(this) ||
            _whiteHat == whiteHat ||
            _whiteHat == newOwner ||
            _whiteHat == NFT_CONTRACT
        ) {
            revert InvalidAddress();
        }

        whiteHat = payable(_whiteHat);
    }
    function setNewOwner(address _newOwner) external onlyOwner nonReentrant {
        // Make sure the new owner is a valid and unique address
        if (
            _newOwner == address(0) ||
            _newOwner == address(this) ||
            _newOwner == whiteHat ||
            _newOwner == newOwner ||
            _newOwner == NFT_CONTRACT
        ) {
            revert InvalidAddress();
        }

        newOwner = _newOwner;
    }

    // Reset and drain contract.
    // Can only be called if time lock expires or as part of normal bounty mechanism.
    function _resetContract() internal {
        if (address(this).balance > 0) {
            payable(owner()).transfer(address(this).balance);
        }

        amount = 0;
        startTime = 0;
    }

    // Permanently lock the HTLC contract.
    function lockContract() external onlyOwner nonReentrant {
        if (IS_LOCKED) {
            revert AlreadyLocked();
        }

        IS_LOCKED = true;
    }
}
