// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Importing from OpenZeppelin's contract library
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./ComputerReacts.sol";

/// @title ComputerReactsMinter
/// @notice This contract allows minting of ComputerReacts tokens using either ETH or DROOL tokens.
/// @dev This contract uses OpenZeppelin's Ownable and ReentrancyGuard to provide basic access control and re-entrancy attack protection.
contract ComputerReactsMinter is ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    address private _signer;
    uint256 private _droolPrice;
    uint256 private _ethPrice;
    DROOL private _drool;
    ComputerReacts private _token;

    /// @notice Constructor sets the initial parameters for the contract.
    /// @param drool_ The address of the DROOL token contract.
    /// @param droolPrice_ The price for minting a token with DROOL.
    /// @param ethPrice_ The price for minting a token with ETH.
    /// @param signer_ The address of the signer for verification.
    /// @param token_ The address of the ComputerReacts token contract.
    constructor(address drool_, uint256 droolPrice_, uint256 ethPrice_, address signer_, address token_) {
        _drool = DROOL(drool_);
        _droolPrice = droolPrice_;
        _ethPrice = ethPrice_;
        _signer = signer_;
        _token = ComputerReacts(token_);
    }

    /// @notice Allows users to mint a new token with ETH.
    /// @dev Verifies the provided signature before minting the token.
    /// @param newTokenId The ID for the new token to be minted.
    /// @param newTokenURI The URI for the new token metadata.
    /// @param signature The signature to verify the minting.
    function Mint(uint256 newTokenId, string memory newTokenURI, bytes memory signature) public payable nonReentrant {
        bytes32 messageHash = keccak256(abi.encodePacked(newTokenId, newTokenURI));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ethSignedMessageHash.recover(signature);

        require(recoveredSigner == _signer, "Invalid signature");
        require(msg.value >= _ethPrice, "Insufficient payment");

        _token.mint(msg.sender, newTokenId, newTokenURI);
    }

    /// @notice Allows users to mint a new token with DROOL tokens.
    /// @dev Burns the DROOL tokens from the user's account after verification.
    /// @param newTokenId The ID for the new token to be minted.
    /// @param newTokenURI The URI for the new token metadata.
    /// @param signature The signature to verify the minting.
    function DroolMint(uint256 newTokenId, string memory newTokenURI, bytes memory signature) public nonReentrant {
        bytes32 messageHash = keccak256(abi.encodePacked(newTokenId, newTokenURI));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ethSignedMessageHash.recover(signature);
        require(recoveredSigner == _signer, "Invalid signature");

        _drool.burnFrom(msg.sender, _droolPrice);
        _token.mint(msg.sender, newTokenId, newTokenURI);
    }

    /// @notice Sets a new DROOL token price for minting.
    /// @param newDroolPrice The new price for minting with DROOL.
    function setDroolPrice(uint256 newDroolPrice) external onlyOwner {
        _droolPrice = newDroolPrice;
    }

    /// @notice Sets a new drool address.
    /// @param newDroolAddress The address of the drool token.
    function setDrool(address newDroolAddress) external onlyOwner {
        _drool = DROOL(newDroolAddress);
    }

    /// @notice Updates the signer address.
    /// @param newSigner The new signer's address.
    function setSigner(address newSigner) public onlyOwner {
        _signer = newSigner;
    }

    /// @notice Retrieves the signer address.
    /// @return The address of the current signer.
    function signer() public view returns (address) {
        return _signer;
    }

    /// @notice Retrieves the DROOL token contract.
    /// @return The DROOL token contract instance.
    function drool() public view returns (DROOL) {
        return _drool;
    }

    /// @notice Retrieves the ComputerReacts token contract.
    /// @return The ComputerReacts token contract instance.
    function token() public view returns (ComputerReacts) {
        return _token;
    }

    /// @notice Gets the current DROOL token price.
    /// @return The price for minting with DROOL.
    function droolPrice() public view returns (uint256) {
        return _droolPrice;
    }

    /// @notice Gets the current ETH price.
    /// @return The price for minting with ETH.
    function ethPrice() public view returns (uint256) {
        return _ethPrice;
    }

    /// @notice Withdraws the contract's entire Ether balance to an address
    function withdraw(address payable to) external onlyOwner {
        require(address(this).balance > 0, "No Ether left to withdraw");
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}

/// @title DROOL Token Interface
/// @notice This abstract contract defines the DROOL token interface for the ComputerReactsMinter contract.
abstract contract DROOL {
    /// @notice Retrieves the balance of a given account.
    /// @param account The address of the account to check.
    /// @return The balance of the account.
    function balanceOf(address account) public view virtual returns (uint256);

    /// @notice Burns a specific amount of DROOL from an account.
    /// @param _from The address to burn the DROOL from.
    /// @param _amount The amount of DROOL to burn.
    function burnFrom(address _from, uint256 _amount) external virtual;
}
