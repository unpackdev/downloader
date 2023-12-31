// SPDX-License-Identifier: MIT

//Limited minting contract for the PoliticalCorruption NFT collection, designed to facilitate interaction with seadrop.
//Off platform minting contract, as well as all other portions of the PoliticalCorruption NFT ecosystem, can be found in the PoliticalCorruptionControl directory

// Specifies the Solidity compiler version
pragma solidity 0.8.17;

// Importing the ERC721SeaDrop contract from a relative path
import "./ERC721SeaDrop.sol";

// Contract definition
contract PoliticalCorruptionPacksV1SeadropCompatible is ERC721SeaDrop {

    // State variable to store the address of the PoliticalCorruptionControl contract
    address private _politicalCorruptionControl;

    // Event emitted when the PoliticalCorruptionControl address is updated
    event PoliticalCorruptionControlUpdated(address indexed newAddress);

    // Event emitted when a token is burned
    event TokenBurned(uint256 tokenId);

    // Constructor to initialize the contract
    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) ERC721SeaDrop(name, symbol, allowedSeaDrop) {}

    // Function to set the address of the PoliticalCorruptionControl contract
    function setPoliticalCorruptionControl(address newAddress) external onlyOwner {
        // Ensuring the new address is not a zero address
        require(newAddress != address(0), "Address cannot be zero");
        
        // Updating the state variable
        _politicalCorruptionControl = newAddress;
        
        // Emitting an event to log the change
        emit PoliticalCorruptionControlUpdated(newAddress);
    }

    // Function to get the address of the PoliticalCorruptionControl contract
    function getPoliticalCorruptionControl() external view returns (address) {
        return _politicalCorruptionControl;
    }

    // Function to burn a token
    function burn(uint256 tokenId) external {
        require(
            msg.sender == _politicalCorruptionControl || msg.sender == ownerOf(tokenId),
            "Only PoliticalCorruptionControl or the token owner can call this function"
        );
        require(
            getApproved(tokenId) == _politicalCorruptionControl,
            "PoliticalCorruptionControl is not approved to burn this token"
        );
    
        // Calling the internal _burn function from the parent contract
        _burn(tokenId, true);

        // Emitting an event to signal that the token has been burned
        emit TokenBurned(tokenId);
    }
}