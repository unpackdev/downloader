// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./IMintingContract.sol";
import "./ITokenContract.sol";

/*

  _________                           __  .__              _____                __  .__             ________              .__.__          
 /   _____/__.__. _____ ___________ _/  |_|  |__ ___.__. _/ ____\___________  _/  |_|  |__   ____   \______ \   _______  _|__|  |   ______
 \_____  <   |  |/     \\____ \__  \\   __\  |  <   |  | \   __\/  _ \_  __ \ \   __\  |  \_/ __ \   |    |  \_/ __ \  \/ /  |  |  /  ___/
 /        \___  |  Y Y  \  |_> > __ \|  | |   Y  \___  |  |  | (  <_> )  | \/  |  | |   Y  \  ___/   |    `   \  ___/\   /|  |  |__\___ \ 
/_______  / ____|__|_|  /   __(____  /__| |___|  / ____|  |__|  \____/|__|     |__| |___|  /\___  > /_______  /\___  >\_/ |__|____/____  >
        \/\/          \/|__|       \/          \/\/                                      \/     \/          \/     \/                  \/ 

I see you nerd! ⌐⊙_⊙
*/

contract HellStore is Ownable, Pausable {
    using ECDSA for bytes32;

    ITokenContract public sinsTokenContractInstance;

    // Used to validate authorized mint addresses
    address public signerAddress = 0xB44b7e7988A225F8C479cB08a63C04e0039B53Ff;

    event ItemPurchased(address from, uint256 itemId, uint256 quantity, uint256 totalSins);

    event ItemMinted(address from, address contractAddress, uint256 quantity, uint256 totalSins, uint256[] tokenIds);

    constructor(address sinsTokenAddress) {
        sinsTokenContractInstance = ITokenContract(sinsTokenAddress);
        _pause();
    }

    function hashPurchase(address buyer, uint256 itemId, uint256 quantity, uint256 totalSins, uint256 expiry) public pure returns (bytes32) {
        return keccak256(abi.encode(
            buyer,
            itemId,
            quantity,
            totalSins,
            expiry
        ));
    }

    function hashMint(address buyer, address contractAddress, uint256 quantity, uint256 totalSins, uint256 expiry) public pure returns (bytes32) {
        return keccak256(abi.encode(
            buyer,
            contractAddress,
            quantity,
            totalSins,
            expiry
        ));
    }

    function setAddresses(address sinsTokenAddress, address newSignerAddress) public onlyOwner {
        sinsTokenContractInstance = ITokenContract(sinsTokenAddress);
        signerAddress = newSignerAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function purchaseItem(uint256 itemId, uint256 quantity, uint256 totalSins, uint256 expiry, bytes memory signature) public whenNotPaused {
        require(block.timestamp < expiry, "Preapproved purchase expired");
        bytes32 hashToVerify = hashPurchase(msg.sender, itemId, quantity, totalSins, expiry);
        require(signerAddress == hashToVerify.toEthSignedMessageHash().recover(signature), "Invalid signature");

        sinsTokenContractInstance.burnFrom(msg.sender, totalSins * 10 ** 18);
        emit ItemPurchased(msg.sender, itemId, quantity, totalSins);
    }

    function mintItem(address contractAddress, uint256 quantity, uint256 totalSins, uint256 expiry, bytes memory signature) public whenNotPaused {
        require(block.timestamp < expiry, "Preapproved mint expired");
        bytes32 hashToVerify = hashMint(msg.sender, contractAddress, quantity, totalSins, expiry);
        require(signerAddress == hashToVerify.toEthSignedMessageHash().recover(signature), "Invalid signature");

        sinsTokenContractInstance.burnFrom(msg.sender, totalSins * 10 ** 18);
        uint256[] memory tokenIds = IMintingContract(contractAddress).mintViaSins(msg.sender, quantity);
        emit ItemMinted(msg.sender, contractAddress, quantity, totalSins, tokenIds);
    }
}