// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";

contract MoonLoot is ERC721, Ownable {

    uint constant public TICKET_ID = 0;
    uint constant public MAX_SUPPLY = 10000;
    uint constant public PRICE = 0.03 ether;

    string private baseURI;
    IERC1155 public ticketsContract;

    uint public maxNFTPerMint;
    uint public maxMintsPerWallet;

    bool public isClaimingWithTicketsEnabled;
    bool public isMintingAvailable;
    uint public totalSupply;

    mapping(address => uint) public mintedNFTs;
    mapping(address => uint) public claimedWithTickets;
    mapping(address => uint) public availableODBSets;

    constructor() ERC721("One Day Loot", "ODB") {

    }

    // Setters region
    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function setTicketsContract(IERC1155 _ticketsContract) external onlyOwner {
        ticketsContract = _ticketsContract;
    }

    function setIsClaimingWithTicketsEnabled(bool _isClaimingWithTicketsEnabled) external onlyOwner {
        isClaimingWithTicketsEnabled = _isClaimingWithTicketsEnabled;
    }

    function setIsMintingAvailable(bool _isMintingAvailable) external onlyOwner {
        isMintingAvailable = _isMintingAvailable;
    }

    function setMaxMintsPerWallet(uint _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }


    function configure(
        IERC1155 _ticketsContract,
        bool _isMintingAvailable,
        bool _isClaimingWithTicketsEnabled,
        uint _maxMintsPerWallet
    ) external onlyOwner {
        ticketsContract = _ticketsContract;
        isMintingAvailable = _isMintingAvailable;
        isClaimingWithTicketsEnabled = _isClaimingWithTicketsEnabled;
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setODBSet(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        require(addresses.length == amounts.length, "addresses.length != amounts.length");
        for (uint i = 0; i < addresses.length; i++) {
            availableODBSets[addresses[i]] = amounts[i];
        }
    }
    // endregion

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier maxSupplyCheck(uint amount)  {
        require(totalSupply + amount <= MAX_SUPPLY, "Tokens supply reached limit");
        _;
    }

    // Mint and Claim functions
    function findRemainingClaimsWithTickets() view public returns (uint) {
        if (isClaimingWithTicketsEnabled) {
            uint tickets = ticketsContract.balanceOf(msg.sender, TICKET_ID);
            uint claimed = claimedWithTickets[msg.sender];
            return claimed > tickets ? 0 : tickets - claimed;
        } else {
            return 0;
        }
    }

    function remainingFreeMints() view public returns (uint) {
        uint minted = mintedNFTs[msg.sender];
        uint remainingClaimsWithTickets = findRemainingClaimsWithTickets();

        uint remainingClaims = remainingClaimsWithTickets + availableODBSets[msg.sender];
        return remainingClaims > minted ? remainingClaims - minted : 0;
    }

    function accountFreeMints(uint freeMintsUsed) internal {
        if (freeMintsUsed == 0) {
            return;
        }
        uint remainingClaimsWithTickets = findRemainingClaimsWithTickets();
        if (remainingClaimsWithTickets >= freeMintsUsed) {
            claimedWithTickets[msg.sender] += freeMintsUsed;
        } else {
            claimedWithTickets[msg.sender] += remainingClaimsWithTickets;
            availableODBSets[msg.sender] -= freeMintsUsed - remainingClaimsWithTickets;
        }
    }

    function mintPrice(uint amount) public view returns (uint) {
        uint freeMints = remainingFreeMints();
        if (freeMints > amount) {
            return 0;
        } else {
            return (amount - freeMints) * PRICE;
        }
    }

    function mint(uint amount) external payable {
        require(isMintingAvailable, "Minting is not available");

        uint freeMints = remainingFreeMints();
        uint freeMintsForAmount = freeMints > amount ? amount : freeMints;

        require(mintedNFTs[msg.sender] + amount - freeMintsForAmount <= maxMintsPerWallet, "maxMintsPerWallet constraint violation");
        require(mintPrice(amount) == msg.value, "Wrong ethers value");

        mintedNFTs[msg.sender] += amount - freeMintsForAmount;
        accountFreeMints(freeMintsForAmount);
        mintNFTs(amount);
    }

    function mintNFTs(uint amount) internal maxSupplyCheck(amount) {
        uint fromToken = totalSupply + 1;
        totalSupply += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, fromToken + i);
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint share1 = balance / 18 * 3;
        payable(0x50131231dE9E36B3838c5F4B9D80D07e45FDD7Ae).transfer(share1);
        payable(0x55dFc6B1A586542e0aB569434F5f38766D3bD0a1).transfer(balance - share1);
    }

}