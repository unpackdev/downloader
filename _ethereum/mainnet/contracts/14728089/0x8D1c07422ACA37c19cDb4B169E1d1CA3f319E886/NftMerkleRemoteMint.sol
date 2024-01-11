// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "./console.sol";
import "./Ownable.sol";
import "./Pausable.sol";

import "./MerkleAllowList.sol";


contract NftMerkleRemoteMint is MerkleAllowList, Pausable, Ownable {
    address payable public payeeAddress;
    uint256 public fee = 0.004 ether;
    bool public mintEnabled = true;

    //Remote Mint Event Emitter
    event RemoteMint(address account);
    constructor(address payable _payeeAddress, bytes32 merkleRoot) MerkleAllowList(merkleRoot)  {
        require(_payeeAddress != address(0x0), "payeeAddress Need a valid address");
        payeeAddress = _payeeAddress;
    }
    function setPayee(address _payeeAddress) public onlyOwner {
        require(_payeeAddress != address(0x0), "Need a valid address");
        payeeAddress = payable(_payeeAddress);
    }

    function setFee(bool newMintEnabled) public onlyOwner {
        mintEnabled = newMintEnabled;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        _setMerkleRoot(newMerkleRoot);
    }

    function setMintEnabled(uint256 newFee) public onlyOwner {
        fee = newFee;
    }

    function sendFeesToPayee(uint256 transferAmount) public onlyOwner {
        require(transferAmount <= address(this).balance, "transferAmount must be less or equal to the balance");
        payeeAddress.transfer(transferAmount);
    }

    function mintEvent(address to) public payable onlyPublicSale whenNotPaused {
        require(msg.value >= fee, "Payable must be at least the fee");
        require(mintEnabled == true, "Mint is disabled");
        emit RemoteMint(to);
    }

    function mintMerkle(address to, bytes32[] calldata proofs) public payable canMint(proofs) whenNotPaused {
        require(msg.value >= fee, "Payable must be at least the fee");
        require(mintEnabled == true, "Mint is disabled");
        // value checked in modifiers
        emit RemoteMint(to);
    }

    // Enable controlled access to imports
    function enableAllowList() public onlyOwner {
        _enableAllowList();
    }

    function disableAllowList() public onlyOwner {
        _disableAllowList();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}
