// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";

/// @title Ed Fornieles Studio Certificates
/// @author Jake Allen
/// @notice https://www.edfornielesstudios.com/
contract StudioCerts is Ownable {
    using ECDSA for bytes32;

    /// @notice link to original 2018 contract for provenance
    address public originalContract = 0x6959396DC62b52C64e9A99c8227322D2305ae89e;

    /// @notice merkle root of valid certificate addresses
    bytes32 public merkleRoot = 0x19b05c521116c0d1cdde3e9e63a17ba836335503e7b6f32a154f42435ef13d91;

    /// @notice certificate address => already claimed. certs are one time use.
    mapping(address => bool) public hasClaimed;

    /// @notice keeps track of how many certificates have been redeemed
    uint256 public claimedCount;

    /// @notice dev address, used for payments
    address public dev = 0x97bB1eFC534fF3dC0DDF5fb83743605d5FAEcB27;

    /// @notice artist address, used for payments
    address public artist = 0x18CE6cD5c283dCa2F50c8347420607a4e59716A6;

    /// @notice the current cost of a studio certificate
    uint256 public price = .2 ether;

    /// @notice the quantities sold for each edition. 0 index = 1st edition, etc.
    uint256[] public editionsSold = [30, 41, 29, 40, 36];
    
    /// @notice the total quantities allowed for each edition. 0 index = 1st edition, etc.
    uint256[] public editionsAllowed = [100, 100, 100, 100, 100];

    /// @notice emitted after a successful redemption
    event Redeem(address indexed payee, address indexed certificateAddress);

    /// @notice redeem a certificate and receive payment
    /// @dev receives a signature and a payout address, which validates that the
    /// signature was produced by a private key corresponding to a valid (i.e.
    /// in our merkle tree) public certificate address
    /// @param merkleProof the merkleProof corresponding to the certificate address
    /// @param signedHash the signature produced by hashing and signing the
    /// payoutAddress
    /// @param payoutAddress the address to send payment to. will be hashed and
    /// compared with signature for verification.
    function redeem(
        bytes32[] calldata merkleProof,
        bytes calldata signedHash,
        address payoutAddress
    ) external {

        // checks
        // verify that end user signed a message with a cert private key, and
        // that the signed message correponds to the redeemAddress where we'll
        // send the payout
        address certAddress = keccak256(abi.encodePacked(payoutAddress))
            .toEthSignedMessageHash()
            .recover(signedHash);

        // verify merkle proof and ensure not already claimed
        require(!hasClaimed[certAddress], "Already claimed");
        require(checkMerkleProof(merkleProof, certAddress), "Invalid proof");

        // capture the amount owed before we reduce supply
        uint256 payoutAmount = currentPayout();

        // effects. invalidate certificate address and reduce circulating supply
        hasClaimed[certAddress] = true;
        claimedCount++;

        // interactions. payout the redeemAddress (NOT the recovered signer address)
        payable(payoutAddress).transfer(payoutAmount);

        // emit redeem event
        emit Redeem(payoutAddress, certAddress);
    }

    /// @notice check whether the merkleProof is valid for a given address
    function checkMerkleProof(
      bytes32[] calldata merkleProof,
      address _address
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /// @notice calculate current payout amount
    /// @dev loop through the editionsSold counts, add them up, then subtract the
    /// number claimed. divide total contract balance by this number of circulating
    /// certs.
    function currentPayout() public view returns (uint256) {
        uint256 inCirculation;
        for (uint256 i = 0; i < editionsSold.length; i++) {
            inCirculation += editionsSold[i];
        }
        inCirculation -= claimedCount;
        require(inCirculation > 0, "No certs in circulation");
        return address(this).balance / inCirculation;
    }

    /// @notice purchase studio certificates
    /// @param quantity an array of the quantity, indexed by edition. 0 = first
    /// edition, etc. [0,2,0,0,0] for example means 2 second editions.
    function purchase(uint256[] calldata quantity) external payable {
        uint256 counter;

        // loop through quantities and reduce supplies, keeping track of the total
        // number purchased
        for (uint256 i = 0; i < quantity.length; i++) {
            if (quantity[i] > 0) {
                uint256 newAmountSold = editionsSold[i] + quantity[i];
                require(newAmountSold <= editionsAllowed[i], "Not enough supply for edition");
                editionsSold[i] = newAmountSold;
                counter += quantity[i];
            }
        }

        // ensure included enough ether for counter amount, else revert
        require(msg.value >= counter * price, "Not enough ether sent");

        // pay splits
        payDevSplit(msg.value);
        payArtistSplit(msg.value);
    }

    /// @notice rescue funds
    /// @dev let owner withdraw all funds in case of emergency or contract upgrade.
    /// this introduces a layer of trust, but this is acceptable since this entire
    /// project requires trust.
    function emergencyRescue() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice let owner set the merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice update the price of a studio certificate
    function updatePrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    /// @notice update the artist address
    function updateArtist(address _address) external onlyOwner {
        artist = _address;
    }

    /// @notice update the dev address
    function updateDev(address _address) external onlyOwner {
        dev = _address;
    }

    /// @notice edit existing editions
    /// @param index the edition number, zero-indexed. 0 = 1st edition, etc.
    /// @param numberSold the number of this edition sold.
    /// @param maxSupply the count of this edition.
    function updateEdition(uint256 index, uint256 numberSold, uint256 maxSupply) external onlyOwner {
        editionsSold[index] = numberSold;
        editionsAllowed[index] = maxSupply;
    }

    /// @notice add new editions
    /// @param numberSold the number of this edition sold. normally 0 for new editions.
    /// @param maxSupply the total amount printed of this edition.
    function addEdition(uint256 numberSold, uint256 maxSupply) external onlyOwner {
        editionsSold.push(numberSold);
        editionsAllowed.push(maxSupply);
    }

    /// @notice refund a purchase (in case of shipping errors)
    /// @param amount formatted in wei
    /// @param _address the address of the refund recipient
    function refund(uint256 amount, address _address) external onlyOwner {
        payable(_address).transfer(amount);
    }
    
    /// @notice pay dev split
    function payDevSplit(uint256 amount) internal {
        (bool success, ) = dev.call{value: amount * 8 / 100}(""); // 8%
        require(success, "Dev payment failed");
    }

    /// @notice pay artist split
    function payArtistSplit(uint256 amount) internal {
        (bool success, ) = artist.call{value: amount * 42 / 100}(""); // 42%
        require(success, "Artist payment failed");
    }

    /// @notice fallback function for receiving eth
    receive() external payable {}

}