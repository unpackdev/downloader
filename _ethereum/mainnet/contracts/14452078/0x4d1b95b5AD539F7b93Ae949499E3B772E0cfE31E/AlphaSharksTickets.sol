// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Strings.sol";

/*

░█████╗░██╗░░░░░██████╗░██╗░░██╗░█████╗░  ░██████╗██╗░░██╗░█████╗░██████╗░██╗░░██╗░██████╗
██╔══██╗██║░░░░░██╔══██╗██║░░██║██╔══██╗  ██╔════╝██║░░██║██╔══██╗██╔══██╗██║░██╔╝██╔════╝
███████║██║░░░░░██████╔╝███████║███████║  ╚█████╗░███████║███████║██████╔╝█████═╝░╚█████╗░
██╔══██║██║░░░░░██╔═══╝░██╔══██║██╔══██║  ░╚═══██╗██╔══██║██╔══██║██╔══██╗██╔═██╗░░╚═══██╗
██║░░██║███████╗██║░░░░░██║░░██║██║░░██║  ██████╔╝██║░░██║██║░░██║██║░░██║██║░╚██╗██████╔╝
╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝  ╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░
*/

interface IAlphaSharksNFT {
    function safeMint(address, uint256) external;
}

contract AlphaSharksTickets is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32;

    IAlphaSharksNFT public alphaSharksNFT;

    /** Phase 1 - Whitelist */
    bool public phaseOneActive = false;
    /** Phase 2 - Whitelist */
    bool public phaseTwoActive = false;
    /** Phase 3 - Public Sale */
    bool public phaseThreeActive = false;

    uint256 public maxSupply = 5969;
    uint256 public whitelistSupply = 5500;

    uint256 public maxTicketsPerUserPhaseTwo = 1;
    uint256 public maxTicketsPerUserPhaseThree = 2;

    /*MINT PRICE FOR WHITELIST*/
    uint256 public whitelistTicketPrice = 0.2 ether;
    /*MINT PRICE FOR PUBLIC*/
    uint256 public publicTicketPrice = 0.3 ether;

    uint256 public ticketSales = 0;

    mapping(address => uint256) public addressToTickets;
    mapping(address => uint256) public addressToMaxMintWhitelist;
    mapping(address => bool) public addressToIsAllowedPhase3;
    mapping(address => uint256) public addressToPhaseTwoTickets;
    mapping(address => uint256) public addressToPhaseThreeTickets;

    /**
        Security
     */
    mapping(address => uint256) public addressToTicketMints;

    constructor() {}

    function setAlphaSharksNFT(IAlphaSharksNFT _alphaSharksNFT)
        external
        onlyOwner
    {
        alphaSharksNFT = _alphaSharksNFT;
    }

    function uploadWhitelistPhase1Phase2(
        address[] calldata addresses,
        uint256[] calldata counts
    ) public onlyOwner {
        require(
            addresses.length == counts.length,
            "NUMBER OF ADDRESSES AND COUNTS ARE NOT EQUAL"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            addressToMaxMintWhitelist[addresses[i]] = counts[i];
        }
    }

    function uploadWhitelistPhase3(
        address[] calldata addresses,
        bool[] calldata bools
    ) public onlyOwner {
        require(
            addresses.length == bools.length,
            "NUMBER OF ADDRESSES AND BOOLS ARE NOT EQUAL"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            addressToIsAllowedPhase3[addresses[i]] = bools[i];
        }
    }

    function makePhaseOneActive(bool _val) external onlyOwner {
        phaseOneActive = _val;
        phaseTwoActive = false;
        phaseThreeActive = false;
    }

    function makePhaseTwoActive(bool _val) external onlyOwner {
        phaseTwoActive = _val;
        phaseOneActive = false;
        phaseThreeActive = false;
    }

    function makePhaseThreeActive(bool _val) external onlyOwner {
        phaseThreeActive = _val;
        phaseOneActive = false;
        phaseTwoActive = false;
    }

    function updateMaxTicketsPerUserPhaseTwo(uint256 _val) external onlyOwner {
        maxTicketsPerUserPhaseTwo = _val;
    }

    function updateMaxTicketsPerUserPhaseThree(uint256 _val)
        external
        onlyOwner
    {
        maxTicketsPerUserPhaseThree = _val;
    }

    function phaseOneBuyTickets(uint256 _amount) external payable {
        /* STEP 1:  Check if phase is active */
        require(phaseOneActive, "PHASE ONE NOT ACTIVE");

        /* STEP 2:  Check the tickets amount */
        require(_amount > 0, "HAVE TO BUY AT LEAST 1");
        require(
            ticketSales.add(_amount) <= whitelistSupply,
            "MAX TICKETS SOLD"
        );

        /* STEP 3:  Check if user is allowed to buy mint tickets */
        require(
            addressToTickets[msg.sender].add(_amount) <=
                addressToMaxMintWhitelist[msg.sender],
            "NOT ALLOWED TO MINT THIS AMOUNT"
        );

        /* STEP 4:  Check if user has sent correct amount of ether to buy tickets */
        require(
            msg.value == whitelistTicketPrice.mul(_amount),
            "INCORRECT AMOUNT PAID"
        );

        /* STEP 5:  Buy the mint tickets */
        addressToTickets[msg.sender] = addressToTickets[msg.sender].add(
            _amount
        );
        ticketSales = ticketSales.add(_amount);
        mintAlphaSharks();
    }

    function phaseTwoBuyTickets(uint256 _amount) external payable {
        /* STEP 1:  Check if phase is active */
        require(phaseTwoActive, "PHASE TWO NOT ACTIVE");

        /* STEP 2:  Check the tickets amount */
        require(_amount > 0, "HAVE TO BUY AT LEAST 1");
        require(
            ticketSales.add(_amount) <= whitelistSupply,
            "MAX TICKETS SOLD"
        );

        /* STEP 3:  Check if user is allowed to buy mint tickets */
        require(
            addressToMaxMintWhitelist[msg.sender] > 0,
            "NOT ALLOWED TO MINT THIS AMOUNT"
        );
        require(
            addressToPhaseTwoTickets[msg.sender].add(_amount) <=
                maxTicketsPerUserPhaseTwo,
            "NOT ALLOWED TO MINT THIS AMOUNT"
        );

        /* STEP 4:  Check if user has sent correct amount of ether to buy tickets */
        require(
            msg.value == whitelistTicketPrice.mul(_amount),
            "INCORRECT AMOUNT PAID"
        );

        /* STEP 5:  Buy the mint tickets */
        addressToPhaseTwoTickets[msg.sender] = addressToPhaseTwoTickets[
            msg.sender
        ].add(_amount);
        addressToTickets[msg.sender] = addressToTickets[msg.sender].add(
            _amount
        );
        ticketSales = ticketSales.add(_amount);
        mintAlphaSharks();
    }

    function phaseThreeBuyTickets(uint256 _amount) external payable {
        /* STEP 1:  Check if phase is active */
        require(phaseThreeActive, "PHASE THREE NOT ACTIVE");

        /* STEP 2:  Check the tickets amount */
        require(_amount > 0, "HAVE TO BUY AT LEAST 1");
        require(ticketSales.add(_amount) <= maxSupply, "MAX TICKETS SOLD");

        /* STEP 3:  Check if user is allowed to buy mint tickets */
        require(
            addressToIsAllowedPhase3[msg.sender] == true,
            "NOT ALLOWED TO MINT"
        );
        require(
            addressToPhaseThreeTickets[msg.sender].add(_amount) <=
                maxTicketsPerUserPhaseThree,
            "NOT ALLOWED TO MINT THIS AMOUNT"
        );

        /* STEP 4:  Check if user has sent correct amount of ether to buy tickets */
        require(
            msg.value == publicTicketPrice.mul(_amount),
            "INCORRECT AMOUNT PAID"
        );

        /* STEP 5:  Buy the mint tickets */
        addressToPhaseThreeTickets[msg.sender] = addressToPhaseThreeTickets[
            msg.sender
        ].add(_amount);
        addressToTickets[msg.sender] = addressToTickets[msg.sender].add(
            _amount
        );
        ticketSales = ticketSales.add(_amount);
        mintAlphaSharks();
    }

    function mintAlphaSharks() public {
        uint256 ticketsOfSender = addressToTickets[msg.sender];

        uint256 mintsOfSender = addressToTicketMints[msg.sender];
        uint256 mintable = ticketsOfSender.sub(mintsOfSender);

        require(mintable > 0, "NO MINTABLE TICKETS");

        addressToTicketMints[msg.sender] = addressToTicketMints[msg.sender].add(
            mintable
        );

        alphaSharksNFT.safeMint(msg.sender, mintable);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
