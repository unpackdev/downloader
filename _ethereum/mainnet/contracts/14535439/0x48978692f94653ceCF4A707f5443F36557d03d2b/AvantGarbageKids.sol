// SPDX-License-Identifier: MIT
/**
     ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄ ▄▄    ▄ ▄▄▄▄▄▄▄    ▄▄▄▄▄▄▄ ▄▄▄▄▄▄ ▄▄▄▄▄▄   ▄▄▄▄▄▄▄ ▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄    ▄▄▄   ▄ ▄▄▄ ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ 
    █       █  █ █  █      █  █  █ █       █  █       █      █   ▄  █ █  ▄    █      █       █       █  █   █ █ █   █      ██       █
    █   ▄   █  █▄█  █  ▄   █   █▄█ █▄     ▄█  █   ▄▄▄▄█  ▄   █  █ █ █ █ █▄█   █  ▄   █   ▄▄▄▄█    ▄▄▄█  █   █▄█ █   █  ▄    █  ▄▄▄▄▄█
    █  █▄█  █       █ █▄█  █       █ █   █    █  █  ▄▄█ █▄█  █   █▄▄█▄█       █ █▄█  █  █  ▄▄█   █▄▄▄   █      ▄█   █ █ █   █ █▄▄▄▄▄ 
    █       █       █      █  ▄    █ █   █    █  █ █  █      █    ▄▄  █  ▄   ██      █  █ █  █    ▄▄▄█  █     █▄█   █ █▄█   █▄▄▄▄▄  █
    █   ▄   ██     ██  ▄   █ █ █   █ █   █    █  █▄▄█ █  ▄   █   █  █ █ █▄█   █  ▄   █  █▄▄█ █   █▄▄▄   █    ▄  █   █       █▄▄▄▄▄█ █
    █▄▄█ █▄▄█ █▄▄▄█ █▄█ █▄▄█▄█  █▄▄█ █▄▄▄█    █▄▄▄▄▄▄▄█▄█ █▄▄█▄▄▄█  █▄█▄▄▄▄▄▄▄█▄█ █▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█  █▄▄▄█ █▄█▄▄▄█▄▄▄▄▄▄██▄▄▄▄▄▄▄█

    Artist: Jon Swartz
    Developer: Shawn Barto
 */
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract AvantGarbageKids is ERC721Enumerable, Ownable {

    struct Hunt {
        bool claimed;
        bool rewarded;
        uint256 tokenId;
        address winner;
        bytes32 huntHash;
    }
 
    bool public fundsWithdrawn = false;
    bool public gratuityAllowed = false;
    uint256 public constant HUNT_SUPPLY = 30;
    uint256 public constant MAX_DUDES = 8008 - HUNT_SUPPLY;
    uint256 public constant price = 0.08 ether;
    uint256 public giveawaySupply = 8.08 ether;
    uint256 public donationSupply;
    uint256 public rewardBlockNumber = 0;
    uint256 public rewardOffset = 1;
    uint256 public startTime = 1650427200;
    string public baseTokenURI = "https://www.avantgarbagekids.com/dudes/";
    string public provenanceHash = "0b6305ff0077ac93a6eec972d7464d30b51ae177cff079ab2b602f3c608e1470";

    mapping(address => uint256) public purchased;
    mapping(bytes32 => Hunt) public huntedGarbage;

    event Donation(uint256 amount, string organization, uint256 timestamp);
    event DonationReceipt(string note, uint256 amount, uint256 timestamp);
    event GiveawayReceipt(uint256 amount, uint256 timestamp);
    event HuntRewarded(address winner, uint256 tokenId);
    event GiveawayRewarded(address winner, uint256 amount, uint256 offset, uint256 tokenId);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /** @notice ETH transfer wrapper. */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "Transfer FAILED");
    }

    /** @notice Override for managing the token uri.*/
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseTokenURI;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

    function claimGarbage(string memory goldenTicket) external {
        bytes32 _hash = keccak256(abi.encodePacked(goldenTicket));
        require(!huntedGarbage[_hash].claimed, "Already Claimed");
        require(huntedGarbage[_hash].huntHash == _hash, "Not a Golden Ticket!");
        huntedGarbage[_hash].claimed = true;
        huntedGarbage[_hash].winner = msg.sender;
    }


    function acceptTips(bool allow) external onlyOwner {
        require(totalSupply() == 8008);
        gratuityAllowed = allow;
    }

    /** @notice All Donations will be further Donated. */
    function graciousDonatious(string memory note) external payable {
        require(gratuityAllowed && msg.value > 0, "dontdothat");
        donationSupply += msg.value;
        emit DonationReceipt(note, msg.value, block.timestamp);
    }
 
    /** @notice 
        Anyone may increase the giveaway supply! 
        We'll just give it away cuz we're crazy like that!
        We will call this if we end up being the recipient of a giveaway;
        Or we decide to grease some more of ya'lls wheelz!?!
    */ 
    function increaseGiveaway() external payable {
        require(gratuityAllowed && msg.value > 0, "dontdothat");
        giveawaySupply += msg.value;
        emit GiveawayReceipt(msg.value, block.timestamp);

    }

    /** @notice Mint A Dude */
    function mintGarbageKid(uint256 amount) external payable {
        require(startTime < block.timestamp, "Minting hasn't started.");
        require(purchased[msg.sender] + amount <= 20 && amount > 0 && amount <= 10, "Invalid quantity.");
        require(totalSupply() < MAX_DUDES, "Sorry! Minting has completed.");
        require(price * amount <= msg.value, "Invalid payment.");
        purchased[msg.sender] += amount;
        for (uint256 i = 0; i < amount; i++)
            if (totalSupply() < MAX_DUDES) 
                _mint(msg.sender, totalSupply() + 1);
    }

    /** @notice Mint the first two for us. */
    function mintOurGarbage() external onlyOwner {
        require(totalSupply() == 0, "It has begun!");
        startTime = block.timestamp;
        _mint(msg.sender, 1);
        _mint(msg.sender, 2);
    }

    /** @notice Treasure Hunt start after all minted */
    function mintTreasureKids() external onlyOwner {
        require(totalSupply() == MAX_DUDES, "You must wait Sensai."); 
        for (uint256 i = 0; i < HUNT_SUPPLY; i++)
            _mint(msg.sender, totalSupply() + 1);
    }

    /** @notice
        Magic ETH giveaway function.
        Winners will be selected by the blockchain!
        If we happen to win, we will mulligan the giveaway!
        Best Wishes!!!
    */
    function rewardGiveaway(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount && giveawaySupply >= amount, "Balance too low.");
        require(block.number - rewardBlockNumber > 256, "Wait for more blocks.");

        /** @notice
            The Magic: A Simple Hash RNG!
            Turn blockhash into number, generate offset from modulus operation.
            Use offset to generate winner tokenId via same process.
        */
        uint256 offset = (uint256(blockhash(block.number - rewardOffset)) % 256) + 1;
        uint256 winnerId = (uint256(blockhash(block.number - offset)) % 8008) + 1;
        address winner = ownerOf(winnerId);
        require(!_isContract(address(winner)), "No contracts.");
        rewardOffset = offset;
        rewardBlockNumber = block.number;
        giveawaySupply -= amount;
        _safeTransferETH(winner, amount);
        emit GiveawayRewarded(winner, amount, offset, winnerId);
    }

    function rewardTrash(bytes32 answer) external onlyOwner {
        require(huntedGarbage[answer].winner != address(0x00) && huntedGarbage[answer].tokenId > 0, "Invalid Hunt!");
        require(!huntedGarbage[answer].rewarded, "Already Rewarded!");
        safeTransferFrom(msg.sender, huntedGarbage[answer].winner, huntedGarbage[answer].tokenId);
        huntedGarbage[answer].rewarded = true;
        emit HuntRewarded(huntedGarbage[answer].winner, huntedGarbage[answer].tokenId);
    } 

    /** @notice For the move to IPFS after mint. Update Base Token URI */
    function setBaseTokenURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function setHuntHashes(bytes32[] memory hashes) external onlyOwner {
        require(totalSupply() == 8008 && hashes.length == HUNT_SUPPLY, "Length Mismatch!");
        uint256 tokenId = MAX_DUDES + 1;
        for(uint256 i = 0; i < hashes.length; i++){
            huntedGarbage[hashes[i]].claimed = false;
            huntedGarbage[hashes[i]].tokenId = tokenId + i;
            huntedGarbage[hashes[i]].huntHash = hashes[i];
        }
    }

    /** @notice Community Function to set initial reward offset.  Anyone may change */
    function setRewardOffset(uint256 offset) external {
        require(offset > 0 && offset < 257, "Size must be between 1 - 256!");
        rewardOffset = offset;
    }

    /** @notice  Emergency Set the provenance hash. */ 
    function setProvenance(string memory _provenance) external onlyOwner {
        provenanceHash = _provenance;
    }

    /** @notice  Withdraw Contracts Balance & Ensures Safekeeping of giveawaySupply and donationSupply. */
    function withdrawFunds() external onlyOwner {
        require(address(this).balance > (giveawaySupply + donationSupply), "Supply error.");
        _safeTransferETH(msg.sender, address(this).balance - (giveawaySupply + donationSupply));
        fundsWithdrawn = true;
    }

    /** @notice Donation Withdrawal.  Emits an event for transparency.*/
    function withdrawDonation(uint256 amount, string memory organization) external onlyOwner {
        require(address(this).balance >= donationSupply && amount <= donationSupply, "Supply error.");
        donationSupply -= amount;
        _safeTransferETH(msg.sender, amount);
        emit Donation(amount, organization, block.timestamp);
    }

    /** @notice 
        Withdrawing this way can only be done upto 50% minted.
        Only if main withdrawal has not been called.
        Afterwards withdrawals are fully limited by the remaining giveaway & donation supply.
        This allows for us to start on the activations.
     */
    function withdrawLunchMoney() external onlyOwner {
        require(totalSupply() < 4004 && !fundsWithdrawn, "No more lunch money :(");
        _safeTransferETH(msg.sender, (address(this).balance - donationSupply));
    }

}
