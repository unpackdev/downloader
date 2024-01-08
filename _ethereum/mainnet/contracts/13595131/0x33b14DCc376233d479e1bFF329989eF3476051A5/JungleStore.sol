// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./IMintingContract.sol";
import "./ITokenContract.sol";

/*
    ____  ____  ___    ____  _____   ________   __    _________    ____  __________  _____
   / __ \/ __ \/   |  / __ \/  _/ | / / ____/  / /   / ____/   |  / __ \/ ____/ __ \/ ___/
  / /_/ / / / / /| | / /_/ // //  |/ / / __   / /   / __/ / /| | / / / / __/ / /_/ /\__ \ 
 / _, _/ /_/ / ___ |/ _, _// // /|  / /_/ /  / /___/ /___/ ___ |/ /_/ / /___/ _, _/___/ / 
/_/ |_|\____/_/  |_/_/ |_/___/_/ |_/\____/  /_____/_____/_/  |_/_____/_____/_/ |_|/____/  
                                                                                          

I see you nerd! ⌐⊙_⊙
*/

contract JungleStore is Ownable, Pausable {
    using ECDSA for bytes32;

    ITokenContract public roarTokenContractInstance;

    // Used to validate authorized mint addresses
    address public signerAddress = 0xB44b7e7988A225F8C479cB08a63C04e0039B53Ff;

    event ItemPurchased(address from, uint256 itemId, uint256 quantity, uint256 totalRoar);

    event ItemMinted(address from, address contractAddress, uint256 quantity, uint256 totalRoar, uint256[] tokenIds);

    constructor(address roarTokenAddress) {
        roarTokenContractInstance = ITokenContract(roarTokenAddress);
        _pause();
    }

    function hashPurchase(address buyer, uint256 itemId, uint256 quantity, uint256 totalRoar, uint256 expiry) public pure returns (bytes32) {
        return keccak256(abi.encode(
            buyer,
            itemId,
            quantity,
            totalRoar,
            expiry
        ));
    }

    function hashMint(address buyer, address contractAddress, uint256 quantity, uint256 totalRoar, uint256 expiry) public pure returns (bytes32) {
        return keccak256(abi.encode(
            buyer,
            contractAddress,
            quantity,
            totalRoar,
            expiry
        ));
    }

    function setAddresses(address roarTokenAddress, address newSignerAddress) public onlyOwner {
        roarTokenContractInstance = ITokenContract(roarTokenAddress);
        signerAddress = newSignerAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function purchaseItem(uint256 itemId, uint256 quantity, uint256 totalRoar, uint256 expiry, bytes memory signature) public whenNotPaused {
        require(block.timestamp < expiry, "Preapproved purchase expired");
        bytes32 hashToVerify = hashPurchase(msg.sender, itemId, quantity, totalRoar, expiry);
        require(signerAddress == hashToVerify.toEthSignedMessageHash().recover(signature), "Invalid signature");

        roarTokenContractInstance.burnFrom(msg.sender, totalRoar * 10 ** 18);
        emit ItemPurchased(msg.sender, itemId, quantity, totalRoar);
    }

    function mintItem(address contractAddress, uint256 quantity, uint256 totalRoar, uint256 expiry, bytes memory signature) public whenNotPaused {
        require(block.timestamp < expiry, "Preapproved mint expired");
        bytes32 hashToVerify = hashMint(msg.sender, contractAddress, quantity, totalRoar, expiry);
        require(signerAddress == hashToVerify.toEthSignedMessageHash().recover(signature), "Invalid signature");

        roarTokenContractInstance.burnFrom(msg.sender, totalRoar * 10 ** 18);
        uint256[] memory tokenIds = IMintingContract(contractAddress).mintViaRoar(msg.sender, quantity);
        emit ItemMinted(msg.sender, contractAddress, quantity, totalRoar, tokenIds);
    }
}