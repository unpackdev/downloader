// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./console.sol";

interface IMynft {
    function mintTo(uint256, address) external;
}

contract MynftPreSale is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32; 

    IMynft public mynft;
     
    /** Off-chain handlers */
    address public signatureProvider;
    mapping(address => uint256) public preSaleAddressToNonce;
    mapping(address => uint256) public giveAwayAddressToNonce;

    /** Phase 1 */
    bool public phaseOneActive = false;
    uint256 public constant phaseOneMaxSupply = 3;
    uint256 public constant phaseOneMaxTicketsPerUser = 1; 
    uint256 public constant phaseOneTicketPrice = 0.000008 ether; // 0.08 ether

    uint256 public phaseOneTicketSales = 0;
    mapping(address => uint256) public phaseOneAddressToTickets;

    /** Phase 2 */
    bool public phaseTwoActive = false;
    uint256 public constant phaseTwoMaxSupply = 5;
    uint256 public constant phaseTwoMaxTicketsPerUser = 3; 
    uint256 public constant phaseTwoTicketPrice = 0.000008 ether; // 0.08 ether    

    uint256 public phaseTwoTicketSales = 0;
    mapping(address => uint256) public phaseTwoAddressToTickets;

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
    event SetSignatureProvider(address _provider);
    event MakePhaseOneActive(bool _active);
    event MakePhaseTwoActive(bool _active);
    event MintSloties(address _sender, uint256 _amount);

    constructor(
        address _mft,
        address _signatureProvider
    ) Ownable() {
        mynft = IMynft(_mft);
        signatureProvider = _signatureProvider;
    }

    /**
     * @dev sets the address of the signature wallet.
     * Only owner can call this function.
     */
    function setSignatureProvider(address _address) external onlyOwner {
        signatureProvider = _address;
        emit SetSignatureProvider(_address);
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
     * to verify the message and the sender
     * @param sig the signature to split
     */
    function splitSignature(bytes memory sig)
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
    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function phaseOneBuyTickets(
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
    }
    
    function mintSloties() external {
        uint256 ticketsOfSender = phaseOneAddressToTickets[msg.sender]
                                  .add(phaseTwoAddressToTickets[msg.sender]);

        uint256 mintsOfSender = addressToTicketMints[msg.sender];
        uint256 mintable = ticketsOfSender.sub(mintsOfSender);

        require(mintable > 0, "NO MINTABLE TICKETS");
        
        addressToTicketMints[msg.sender] = addressToTicketMints[msg.sender].add(mintable);

        mynft.mintTo(mintable, msg.sender);
        emit MintSloties(msg.sender, mintable);
    }

    /** GIVEAWAY */
    function claimGiveaway(uint256 _amount, uint256 nonce, bytes memory signature) external {
        require(_amount > 0, "HAVE TO BUY AT LEAST 1");

        require(giveAwayAddressToNonce[msg.sender] == nonce, "INCORRECT NONCE");
        bytes32 message = keccak256(abi.encodePacked(msg.sender, _amount, nonce, address(this))).toEthSignedMessageHash();
        require(recoverSigner(message, signature) == signatureProvider, "SIGNATURE NOT FROM PROVIDER WALLET");
        giveAwayAddressToNonce[msg.sender] = giveAwayAddressToNonce[msg.sender].add(1);

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