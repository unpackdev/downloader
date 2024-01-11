// SPDX-License-Identifier: MIT

/// @author: valed
/*
Team members will receive an amount of tokens representing their shares. When a POPS NFT is sold, each
token holder receives a revenue proportional to the amount of tokens. The total supply is 100 (actually
10000, with 2 decimals), so the address holding 10 tokens will receive 10% of the revenues, the address
holding 7.5 tokens will receive 7.5% of the revenues and so on. By using this approach, shareholders
are free to transfer their shares to other wallets (or even trade them), the new holders will
automatically start earning dividends from new sales as soon as they receive the tokens.
*/

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./EmergencyWithdraw.sol";

contract POPSteamWallet is ERC20, Ownable, Pausable, ReentrancyGuard, EmergencyWithdraw {

    ///// TOKEN EVENTS /////
    event AddedShareholder(address indexed shareHolder, address[] shareholderList);
    event RemovedShareholder(address indexed shareHolder, address[] shareholderList);
    ///// WALLET EVENTS /////
    event DividendsClaimed(address indexed, uint);
    
    using SafeMath for uint256;

    ///// VARIABLES /////
    uint256 dividendsToDistribute;
    address[] shareholders;                                                                              // Array keeping track of the shareholders
    mapping (address => uint256) shareholderIndex;                                                       // Shareholder index in the two arrays above
    mapping (address => uint256) dividends;                                                              // Accrued dividends for each shareholder
    mapping (address => bool) isShareholder;                                                             // Flags which addresses are shareholders

    ///// CONSTRUCTOR /////
    constructor(string memory name, string memory symbol) Ownable() ERC20(name, symbol) {
        _mint(msg.sender, 100 * 10 ** decimals());                                                       // Mint 10k shares - such amount is fixed
    }

    ///// FUNCTIONS /////
    function decimals() public pure override returns (uint8) {                                           // Override the decimals function
        return 2;
    }
    
    // [Tx][Internal] Override _beforeTokenTransfer to make sure accrued dividends are properly allocated before the shareholders change
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override{   // Also updates shareholders database
        bool isMinting = from == address(0);                                                             // Checks if the transaction is a minting
        require(isMinting || amount <= balanceOf(from), "The amount exceeds the sender's balance");      // Check if sender has enough funds
        distributeDividends();                                                                           // Distribute dividends before updating the shareholder list
        addShareholder(to);                                                                              // Add recipient to the shareholder list (the function performs no action if the address is already in the list)
        if(isMinting || amount == balanceOf( from )){ removeShareholder( from ); }                       // Remove sender from the shareholders if transfers all shares, does nothing if the transfer is a minting
        super._beforeTokenTransfer(from, to, amount);
    }

    // [Tx][Private] Add new shareholder
    function addShareholder(address newShareholder) private returns(bool added){
        if(!isShareholder[newShareholder]){                                                              // Do if not a shareholder yet
            shareholderIndex[newShareholder] = shareholders.length;                                      // Store shareholder's index in array
            shareholders.push(newShareholder);                                                           // Append shareholder's address to array
            isShareholder[newShareholder]=true;                                                          // Flag the address as a shareholder
            emit AddedShareholder(newShareholder, shareholders);                                         // Emit event
            added=true;
        }
        else{ added=false; }
    }

    // [Tx][Private] Remove shareholder from database
    function removeShareholder(address shareholder) private returns(bool removed){
        if(isShareholder[shareholder]){                                                                  // Execute if the address is a shareholder
            shareholders[ shareholderIndex[shareholder] ] = shareholders[ shareholders.length - 1 ];     // Override item to be deleted with last item in array (address)
            shareholderIndex[ shareholders[ shareholders.length - 1 ] ] = shareholderIndex[shareholder]; // Update index of the array item being "moved"
            shareholders.pop();                                                                          // Remove last array item
            isShareholder[shareholder] = false;                                                          // Flag address removed from array as NOT a shareholder
            emit RemovedShareholder(shareholder, shareholders);                                          // Emit event
            removed = true;
        }
        else{ removed=false; }                                                                           // Do nothing if not a shareholder
    }

    // [View][Public] Get current number of shareholders
    function countShareholders() view public returns(uint count){
        count=shareholders.length;
    }

    // [View][Public] Get shareholders list
    function listShareholders() view public returns(address[] memory){
        return shareholders;
    }

     // [View][Public] Get the total accrued dividends (aka contract's balance)
    function totalAccruedDividends() view public returns(uint256){
        return address(this).balance;
    }

    // [View][Public] Get the accrued dividends of the given shareholder
    function accruedDividends(address shareholder) view public returns(uint256 accrued){
        accrued = dividends[shareholder] + calculateDividend(shareholder, dividendsToDistribute);
    }

    // [View][Private] Calculate dividend proportional to shares
    function calculateDividend(address shareholder, uint256 value) view private returns(uint256 dividend){
        dividend = value.mul(balanceOf(shareholder)).div(100 * 10 ** decimals());
    }

    // [Tx][Private] Distribute dividends
    function distributeDividends() private returns(bool){
        if(dividendsToDistribute>0){
            uint256 dividendsToDistribute_before = dividendsToDistribute;                                // Used at the end to check invariances
            uint256 distributed;                                                                         // Keeps the count of dividends distributed in the for loop below
            for(uint256 i=0; i<countShareholders(); i++){
                address shareholder = shareholders[i];
                uint256 dividend = calculateDividend(shareholder, dividendsToDistribute);
                dividends[shareholder] += dividend;
                distributed += dividend;
            }
            dividendsToDistribute -= distributed;                                                        // Use subtract instead of overriding to zero in case there is any reminder
            assert(distributed <= dividendsToDistribute_before);
            return true;
        }
        else{return false;}
    }

    // [Fallback] Fallback for incoming payments
    receive() external payable nonReentrant {
        dividendsToDistribute+=msg.value;
    }

    // [Tx][Public] Claim accrued dividends
    function claimDividends() public whenNotPaused nonReentrant returns(bool){
        require( accruedDividends(msg.sender)>0, "This address has no dividends to claim");
        distributeDividends();                                                                           // Make sure all dividends are distributed before claiming
        uint256 value = dividends[msg.sender];
        dividends[msg.sender]=0;
        (bool sent, ) = msg.sender.call{value: value}("");
        emit DividendsClaimed(msg.sender, value);
        return sent;
    }

    // [Tx][Public] Emergency balance withdraw (full consensus from the whole team is required)
    function emergencyWithdraw_propose(address payable _withdrawTo) public onlyOwner{
        super.emergencyWithdraw_start(_withdrawTo, shareholders);
    }

    // [Tx][Public] Pause the contract
    function pauseContract() public onlyOwner {
        _pause();
    }
    // [Tx][Public] Unpause the contract
    function unpauseContract() public onlyOwner {
        _unpause();
    }

}