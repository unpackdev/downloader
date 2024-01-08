// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

interface SlotieNFT {
    function mintTo(uint256, address) external;
}

contract SlotiePreSale is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32; 

    SlotieNFT public slotieNFT;

    /** Phase 1 */
    bool public phaseOneActive = false;
    bool public phaseTwoActive = false;
    uint256 public constant maxSupply = 2501;
    uint256 public constant ticketsPerUser = 3; 
    uint256 public constant ticketPrice = 0.08 ether; // 0.08 ether

    uint256 public ticketSales = 1;
    mapping(address => uint256) public addressToTickets;

    /** MERKLE */
    bytes32 public phaseOneMerkleRoot = 0x5406f95cc1896abac2d843cd72298f3d6072f06941ef21e103d6bcae59807df0;
    bytes32 public phaseTwoMerkleRoot = 0x74a7375e09ffd2a49c6cfe5325df5afb05b87dfd3dbfb2708c140e805b89ad0e;
    bytes32 public giveawayMerkleRoot = 0xef7d2b691d30203e53e5df4f3d16f015208170d6d468f9af39a8d7ef2a12b424;

    /**
        Giveaway
     */
    uint256 public giveAwaySupply = 350;

    /**
        Security
     */
    mapping(address => uint256) public addressToTicketMints;
    mapping(address => uint256) public addressToGiveawayMints;
    //uint256 public constant maxMintPerTx = 30;

    /** Events */
    event SetSlotieNFT(address _slotieNFT);
    event SetSignatureProvider(address _provider);
    event MakePhaseOneActive(bool _active);
    event MakePhaseTwoActive(bool _active);
    event MintSloties(address _sender, uint256 _amount);

    constructor(
        address _sloties
    ) Ownable() {
        slotieNFT = SlotieNFT(_sloties);
    }

    function setSlotieNFT(SlotieNFT _slotieNFT) external onlyOwner {
        slotieNFT = _slotieNFT;
        emit SetSlotieNFT(address(_slotieNFT));
    }

    function setPhaseOneMerkleRoot(bytes32 _root) external onlyOwner {
        phaseOneMerkleRoot = _root;
    }

    function setPhaseTwoMerkleRoot(bytes32 _root) external onlyOwner {
        phaseTwoMerkleRoot = _root;
    }

    function setGiveAwayMerkleRoot(bytes32 _root) external onlyOwner {
        giveawayMerkleRoot = _root;
    }

    function makePhaseOneActive(bool _val) external onlyOwner {
        phaseOneActive = _val;
        emit MakePhaseOneActive(_val);
    }

    function makePhaseTwoActive(bool _val) external onlyOwner {
        phaseTwoActive = _val;
        emit MakePhaseTwoActive(_val);
    }

    function phaseOneBuyTicketsMerkle(
        bytes32[] calldata proof
    )  external payable {
        require(phaseOneActive, "PHASE ONE NOT ACTIVE");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, phaseOneMerkleRoot, leaf), "INVALID PROOF");
        require(addressToTickets[msg.sender] == 0, "ALREADY GOT TICKET");
        require(msg.value == ticketPrice, "INCORRECT AMOUNT PAID");
        addressToTickets[msg.sender] = 1;
        ticketSales = ticketSales.add(1);
    }

    function phaseTwoBuyTicketsMerkle(
        uint256 _amount,
        bytes32[] calldata proof
    )  external payable {
        require(phaseTwoActive, "PHASE TWO NOT ACTIVE");
        require(_amount > 0, "HAVE TO BUY AT LEAST 1");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, phaseTwoMerkleRoot, leaf), "INVALID PROOF");
        require(addressToTickets[msg.sender].add(_amount) <= ticketsPerUser, "ALREADY GOT TICKET");
        require(ticketSales.add(_amount) <= maxSupply, "MAX TICKETS SOLD");
        require(msg.value == ticketPrice.mul(_amount), "INCORRECT AMOUNT PAID");
        addressToTickets[msg.sender] = addressToTickets[msg.sender].add(_amount);
        ticketSales = ticketSales.add(_amount);
    }
    
    function mintSloties() external {
        uint256 ticketsOfSender = addressToTickets[msg.sender];

        uint256 mintsOfSender = addressToTicketMints[msg.sender];
        uint256 mintable = ticketsOfSender.sub(mintsOfSender);

        require(mintable > 0, "NO MINTABLE TICKETS");
        
        addressToTicketMints[msg.sender] = addressToTicketMints[msg.sender].add(mintable);

        slotieNFT.mintTo(mintable, msg.sender);
        emit MintSloties(msg.sender, mintable);
    }

    /** GIVEAWAY */
    function claimGiveaway(uint256 _amount, bytes32[] calldata proof) external {
        require(_amount > 0, "HAVE TO BUY AT LEAST 1");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(MerkleProof.verify(proof, giveawayMerkleRoot, leaf), "INVALID PROOF");

        uint256 giveAwayMints = addressToGiveawayMints[msg.sender];
        require(giveAwayMints == 0, "ALREADY CLAIMED");


        addressToGiveawayMints[msg.sender] = addressToGiveawayMints[msg.sender].add(_amount);
        slotieNFT.mintTo(_amount, msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw ether
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}