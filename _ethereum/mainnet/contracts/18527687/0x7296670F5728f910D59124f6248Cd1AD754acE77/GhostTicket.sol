// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title GhostTicket
/// @notice This is a contract for the Ghost Tickets used for Burn Ghost's sweepstakes
/// @dev This contract uses the OpenZeppelin library
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IBGSweepstake.sol";

contract GhostTicket is ERC20, ERC20Burnable, Ownable {

    /// @notice Mapping to track registered contracts/addresses allowed to burn tokens
    mapping(address => bool) public approvedToBurn; 

    constructor() ERC20("Ghost Ticket", "GTKT") {}

    /// @notice Mint tokens
    /// @param to - Receiving address
    /// @param amount - Amount of tokens to mint
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @notice Batch mint tokens
    /// @param toList - List of receiving addresses
    /// @param amountList - List of amount of tokens to mint
    function batchMint(address[] memory toList, uint256[] memory amountList) public onlyOwner {
        for(uint256 i; i < toList.length; i++) {
            mint(toList[i], amountList[i]);
        }
    }

    /// @notice Approve an address to burn tokens
    /// @dev Ensure that only approved contracts can burn user's tokens
    /// @param approvedAddress - Receiving addresses
    /// @param approved - Approved or not
    function setApprovedToBurn(address[] memory approvedAddress, bool[] memory approved) external onlyOwner {
        require(approvedAddress.length == approved.length, "GhostTicket : invalid parameters");

        for(uint i; i < approvedAddress.length; i++) {
            approvedToBurn[approvedAddress[i]] = approved[i]; 
        }
    }

    /// @notice System burns token on user's behalf
    /// @dev Saves user gas
    /// @param account - Token owner address
    /// @param amount - Amount of tokens to burn
    function systemBurn(address account, uint256 amount) external returns(bool) {
        // Ensure that the calling address is approved to burn
        require(approvedToBurn[_msgSender()], "GhostTicket : Caller not approved to burn tokens");

        _burn(account, amount);

        return true;
    }
}