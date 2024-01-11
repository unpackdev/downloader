//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./Ownable.sol";

import "./FourLetterWords.sol";

contract Claim is Ownable {

    address public fourLetterWords = 0xf39aEC568494668A1b864B64de28ef4E660357Ed;
    address public sourceAccount;
    uint256 public nextToSend;
    bool public paused = true;
    
    // Limits
    uint256 public holderClaimsAllowed;
    uint256 public generalClaimsAllowed;

    // Tracking of claim numbers per address
    mapping (address => uint256) public claimed;


    constructor(address _sourceAccount) {
        sourceAccount = _sourceAccount;
    }

    /**
     * Allows accounts to claim Four Letter Words from the claims wallet.
     * Assumes an approval from the claims wallet.
     */
    function freeMint(uint256 _number) public {
        require(!paused, "Claims paused");
        require(msg.sender == tx.origin, "No contracts");
        require(mintsAvailable(msg.sender) >= _number, "Claiming too many");

        uint256 totalSupply = FourLetterWords(fourLetterWords).totalSupply();
        uint256 sent = 0;
        for (uint256 i = nextToSend; _number > sent && i < totalSupply; i++) {
            if (FourLetterWords(fourLetterWords).ownerOf(i) == sourceAccount) {
                sent++;
                nextToSend++;
                FourLetterWords(fourLetterWords).transferFrom(sourceAccount, msg.sender, i);
            }
        }
        claimed[msg.sender] += sent;
    }

    /**
     * Returns the number of available claims for an account. Each account
     * is able to claim a specific number of Four Letter Words for each
     * word that it already owes. Addresses that do not own a four letter
     * word can claim a specific number too.
     */
    function mintsAvailable(address _account) public view returns(uint256) {
        uint256 balance = FourLetterWords(fourLetterWords).balanceOf(_account);
        uint256 alreadyClaimed = claimed[_account];
        balance = balance < alreadyClaimed ? 0 : balance - alreadyClaimed;
        if (balance > 0) {
            uint256 limit = balance * holderClaimsAllowed;
            return alreadyClaimed > limit ? 0 : limit - alreadyClaimed;
        } else {
            return alreadyClaimed > generalClaimsAllowed ? 0 : generalClaimsAllowed - alreadyClaimed;
        }
    }

    /**
     * Sets the next NFT that will be sent from the claims wallet. 
     * The function can be used for restarting the process.
     */
    function setNextToClaim(uint256 _nextToSend) public onlyOwner {
        nextToSend = _nextToSend;
    }

    /**
     * Set claiming limits.
     */
    function setLimits(uint256 _general, uint256 _holders) public onlyOwner {
        holderClaimsAllowed = _holders;
        generalClaimsAllowed = _general;
    }

    /**
     * Pauses and unpauses.
     */
    function setPaused(bool _value) public onlyOwner {
        paused = _value;
    }
}
