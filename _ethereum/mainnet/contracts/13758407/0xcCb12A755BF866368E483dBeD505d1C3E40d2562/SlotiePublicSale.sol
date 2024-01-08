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

contract SlotiePublicSale is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32; 

    SlotieNFT public slotieNFT;

    /** Phase 3 */
    bool public phaseThreeActive = false;
    uint256 public constant phaseThreeMaxSupply = 7151;
    uint256 public constant phaseThreeMaxTicketsPerUser = 10; 
    uint256 public constant phaseThreeTicketPrice = 0.16 ether; // 0.08 ether    

    uint256 public phaseThreeTicketSales = 1;
    mapping(address => uint256) public phaseThreeAddressToTickets;

    /**
        Whale mint
     */
    uint256 public constant phaseThreeMaxTicketsPerWhale = 100;
    mapping(address => uint256) public phaseThreeWhaleAddressToTickets;
    bytes32 public whaleMerkleRoot = 0x72c8b62b16c9872b4794735ab30257cf069826f752ed1b8c009f8bb816624995;

    /**
        Security
     */
    mapping(address => uint256) public addressToTicketMints;
    uint256 public constant maxMintPerTx = 30;

    /** Events */
    event SetSlotieNFT(address _slotieNFT);
    event MakePhaseThreeActive(bool _active);
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

    function setWhaleMerkleRoot(bytes32 _root) external onlyOwner {
        whaleMerkleRoot = _root;
    }

    function makePhaseThreeActive(bool _val) external onlyOwner {
        phaseThreeActive = _val;
        emit MakePhaseThreeActive(_val);
    }

    function phaseThreeBuyTickets(
        uint256 amount
    )  external payable {
        require(phaseThreeActive, "PHASE THREE NOT ACTIVE");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(phaseThreeAddressToTickets[msg.sender].add(amount) <= phaseThreeMaxTicketsPerUser, "INCORRECT TICKET AMOUNT");
        require(msg.value == phaseThreeTicketPrice.mul(amount), "INCORRECT AMOUNT PAID");
        require(phaseThreeTicketSales.add(amount) <= phaseThreeMaxSupply, "PHASE 3 TICKETS SOLD");
        require(phaseThreeWhaleAddressToTickets[msg.sender] == 0, "WHALES NOT ALLOWED");

        phaseThreeAddressToTickets[msg.sender] = phaseThreeAddressToTickets[msg.sender].add(amount);
        phaseThreeTicketSales = phaseThreeTicketSales.add(amount);
    }

    /** WHALE PASS */
    function whaleBuyTicket(uint256 amount, bytes32[] calldata proof) external payable {
        require(phaseThreeActive, "PHASE THREE NOT ACTIVE");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, whaleMerkleRoot, leaf), "INVALID PROOF");

        require(phaseThreeWhaleAddressToTickets[msg.sender]
            .add(phaseThreeAddressToTickets[msg.sender])
            .add(amount) <= phaseThreeMaxTicketsPerWhale, "INCORRECT TICKET AMOUNT");
        require(msg.value == phaseThreeTicketPrice.mul(amount), "INCORRECT AMOUNT PAID");
        require(phaseThreeTicketSales.add(amount) <= phaseThreeMaxSupply, "PHASE 3 TICKETS SOLD");

        phaseThreeWhaleAddressToTickets[msg.sender] = phaseThreeWhaleAddressToTickets[msg.sender].add(amount);
        phaseThreeTicketSales = phaseThreeTicketSales.add(amount);
    }

    function mintSloties() external {
        uint256 ticketsOfSender = phaseThreeAddressToTickets[msg.sender].add(phaseThreeWhaleAddressToTickets[msg.sender]);
        uint256 mintsOfSender = addressToTicketMints[msg.sender];
        uint256 mintable = ticketsOfSender.sub(mintsOfSender);

        require(mintable > 0, "NO MINTABLE TICKETS");

        uint256 toMint = mintable >= maxMintPerTx ? maxMintPerTx : mintable;
        
        addressToTicketMints[msg.sender] = addressToTicketMints[msg.sender].add(toMint);

        slotieNFT.mintTo(toMint, msg.sender);
        emit MintSloties(msg.sender, toMint);
    }

    /**
     * @dev Allows the owner to withdraw ether
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}