// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./Address.sol";

contract PiggyBank is Ownable {

    address private _manager;

    IERC721Enumerable private _devilsContractInstance;

    uint256 public ethDepositedPerToken;

    // Mapping from token ID to the amount of claimed eth
    mapping(uint256 => uint256) private _claimedEth;

    event EthDeposited(uint256 amount);

    event EthClaimed(address to, uint256 amount);

    constructor(address devilsContractAddress) {
        _devilsContractInstance = IERC721Enumerable(devilsContractAddress);
    }

    /*
    * Set the manager address for deposits.
    */
    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }

    /**
     * @dev Throws if called by any account other than the owner or manager.
     */
    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller is not the owner or manager");
        _;
    }

    function withdraw(uint256 amount) public onlyOwnerOrManager {
        require(address(this).balance >= amount, "Insufficient balance");
        
        Address.sendValue(payable(msg.sender), amount);
    }

    function deposit() public payable onlyOwnerOrManager {
        ethDepositedPerToken += msg.value / _devilsContractInstance.totalSupply();

        emit EthDeposited(msg.value);
    }

    /*
    * Get the claimable balance of a token ID.
    */
    function claimableBalanceOfTokenId(uint256 tokenId) public view returns (uint256) {
        return ethDepositedPerToken - _claimedEth[tokenId];
    }

    /*
    * Get the total claimable balance for an owner.
    */
    function claimableBalance(address owner) public view returns (uint256) {
        uint256 balance = 0;
        uint256 numTokens = _devilsContractInstance.balanceOf(owner);

        for(uint256 i = 0; i < numTokens; i++) {
            balance += claimableBalanceOfTokenId(_devilsContractInstance.tokenOfOwnerByIndex(owner, i));
        }

        return balance;
    }

    function claim() public {
        uint256 amount = 0;
        uint256 numTokens = _devilsContractInstance.balanceOf(msg.sender);

        for(uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = _devilsContractInstance.tokenOfOwnerByIndex(msg.sender, i);
            amount += ethDepositedPerToken - _claimedEth[tokenId];
            // Add the claimed amount so as to protect against re-entrancy attacks.
            _claimedEth[tokenId] = ethDepositedPerToken;
        }

        require(amount > 0, "There is no amount left to claim");

        emit EthClaimed(msg.sender, amount);

        // We must transfer at the very end to protect against re-entrancy.
        Address.sendValue(payable(msg.sender), amount);
    }

    function claimByTokenIds(uint256[] calldata tokenIds) public {
        uint256 amount = 0;

        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(_devilsContractInstance.ownerOf(tokenIds[i]) == msg.sender, "You are not the owner of the token ID");
            amount += ethDepositedPerToken - _claimedEth[tokenIds[i]];
            // Add the claimed amount so as to protect against re-entrancy attacks.
            _claimedEth[tokenIds[i]] = ethDepositedPerToken;
        }

        require(amount > 0, "There is no amount left to claim");

        emit EthClaimed(msg.sender, amount);

        // We must transfer at the very end to protect against re-entrancy.
        Address.sendValue(payable(msg.sender), amount);
    }
}
