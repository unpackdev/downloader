// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./console.sol";
import "./MerkleProof.sol";

interface Imynft {
    function mintTo(uint256, address) external;
}

contract Mynftpresale is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32; 

    Imynft public mynft;

    /** Phase 1 */
    bool public phaseOneActive = false;
    bool public phaseTwoActive = false;
    uint256 public constant maxSupply = 11;
    uint256 public constant ticketsPerUser = 3; 
    uint256 public constant ticketPrice = 0.08 ether; // 0.08 ether

    uint256 public ticketSales = 1;
    mapping(address => uint256) public addressToTickets;

    /** MERKLE */
    bytes32 public phaseOneMerkleRoot = 0x818f6f446478b11c09d323e2fc758252192d631857fffea68e0156bcf7a7b643;
    bytes32 public phaseTwoMerkleRoot = 0x1be0f100df9f0bd9831e225b6061aa8ccefd3f4a7c73fb7aeffbf70e22c24be5;
    bytes32 public giveawayMerkleRoot = 0x79a4721bd97530239a8115876e056b9c019890f143e755da3c695857283a00c7;

    /**
        Giveaway
     */
    uint256 public giveAwaySupply = 500;

    /**
        Security
     */
    mapping(address => uint256) public addressToTicketMints;
    mapping(address => uint256) public addressToGiveawayMints;
    //uint256 public constant maxMintPerTx = 30;

    /** Events */
    event MakePhaseOneActive(bool _active);
    event MakePhaseTwoActive(bool _active);
    
    constructor(
        address _mft
    ) Ownable() {
        mynft = Imynft(_mft);
    }

    function setMFT(Imynft _mft) external onlyOwner {
        mynft = _mft;
    }

    function makePhaseOneActive(bool _val) external onlyOwner {
        phaseOneActive = _val;
        emit MakePhaseOneActive(_val);
    }

    function makePhaseTwoActive(bool _val) external onlyOwner {
        phaseTwoActive = _val;
        emit MakePhaseTwoActive(_val);
    }

    /**
     * Splits a signature to given bytes
     * that the erecover method can use
     * to verify the message and the sende
     */
    /*function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    /**
     * takes the message and the signature
     * and verifies that the message is correct
     * and then returns the signer address of the signature
     */
    /*function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    /*function phaseOneBuyTickets(
        uint256 amount,
        uint256 nonce, 
        bytes memory signature
    )  external payable {
        require(phaseOneActive, "PHASE ONE NOT ACTIVE");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(phaseOneAddressToTickets[msg.sender].add(amount) <= phaseOneMaxTicketsPerUser, "ALREADY BOUGHT MAX TICKET");
        require(msg.value == phaseOneTicketPrice.mul(amount), "INCORRECT AMOUNT PAID");
        require(phaseOneTicketSales.add(amount) <= phaseOneMaxSupply, "PHASE 1 TICKETS SOLD");

        require(preSaleAddressToNonce[msg.sender] == nonce, "INCORRECT NONCE");
        bytes32 message = keccak256(abi.encodePacked(msg.sender, true, nonce, address(this))).toEthSignedMessageHash();
        require(recoverSigner(message, signature) == signatureProvider, "SIGNATURE NOT FROM PROVIDER WALLET");
        preSaleAddressToNonce[msg.sender] = preSaleAddressToNonce[msg.sender].add(1);

        phaseOneAddressToTickets[msg.sender] = amount;
        phaseOneTicketSales = phaseOneTicketSales.add(amount);
    }

    function phaseTwoBuyTickets(
        uint256 amount,
        uint256 nonce, 
        bytes memory signature
    )  external payable {
        require(phaseTwoActive, "PHASE TWO NOT ACTIVE");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(phaseTwoAddressToTickets[msg.sender].add(phaseOneAddressToTickets[msg.sender]).add(amount) <= phaseTwoMaxTicketsPerUser, "INCORRECT TICKET AMOUNT");
        require(msg.value == phaseTwoTicketPrice.mul(amount), "INCORRECT AMOUNT PAID");
        require(phaseTwoTicketSales.add(amount) <= phaseTwoMaxSupply.add(phaseOneMaxSupply.sub(phaseOneTicketSales)), "PHASE 2 TICKETS SOLD");

        require(preSaleAddressToNonce[msg.sender] == nonce, "INCORRECT NONCE");
        bytes32 message = keccak256(abi.encodePacked(msg.sender, false, nonce, address(this))).toEthSignedMessageHash();
        require(recoverSigner(message, signature) == signatureProvider, "SIGNATURE NOT FROM PROVIDER WALLET");
        preSaleAddressToNonce[msg.sender] = preSaleAddressToNonce[msg.sender].add(1);

        phaseTwoAddressToTickets[msg.sender] = phaseTwoAddressToTickets[msg.sender].add(amount);
        phaseTwoTicketSales = phaseTwoTicketSales.add(amount);
    }*/

    function phaseOneBuyTicketsMerkle(
        bytes32[] calldata proof
    )  external payable {
        require(phaseOneActive, "PHASE ONE NOT ACTIVE");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, phaseOneMerkleRoot, leaf), "INVALID PROOF");
        require(addressToTickets[msg.sender] == 0, "ALREADY GOT TICKET");
        require(msg.value == ticketPrice, "INCORRECT AMOUNT PAID");
        addressToTickets[msg.sender] = 1;
        ticketSales = ticketSales + 1;
    }

    function phaseTwoBuyTicketsMerkle(
        uint256 _amount,
        bytes32[] calldata proof
    )  external payable {
        require(phaseTwoActive, "PHASE TWO NOT ACTIVE");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, phaseTwoMerkleRoot, leaf), "INVALID PROOF");
        require(addressToTickets[msg.sender].add(_amount) <= 3, "ALREADY GOT TICKET");
        require(ticketSales.add(_amount) <= maxSupply, "MAX TICKETS SOLD");
        require(msg.value == ticketPrice.mul(_amount), "INCORRECT AMOUNT PAID");
        addressToTickets[msg.sender] = addressToTickets[msg.sender] + _amount;
        ticketSales = ticketSales + _amount;
    }
    
    function mintSloties() external {
        uint256 ticketsOfSender = addressToTickets[msg.sender];

        uint256 mintsOfSender = addressToTicketMints[msg.sender];
        uint256 mintable = ticketsOfSender.sub(mintsOfSender);

        require(mintable > 0, "NO MINTABLE TICKETS");
        
        addressToTicketMints[msg.sender] = addressToTicketMints[msg.sender].add(mintable);

        mynft.mintTo(mintable, msg.sender);
    }

    /** GIVEAWAY */
    function claimGiveaway(uint256 _amount, bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(MerkleProof.verify(proof, giveawayMerkleRoot, leaf), "INVALID PROOF");

        uint256 giveAwayMints = addressToGiveawayMints[msg.sender];
        require(giveAwayMints == 0, "ALREADY CLAIMED");


        addressToGiveawayMints[msg.sender] = addressToGiveawayMints[msg.sender].add(_amount);
        mynft.mintTo(_amount, msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw ether
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}