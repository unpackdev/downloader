// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./MerkleProof.sol";
import "./IShatteredWL.sol";
import "./IPytheas.sol";
import "./IOrbitalBlockade.sol";
import "./IColonist.sol";
import "./ITColonist.sol";
import "./IEON.sol";
import "./IRAW.sol";
import "./IImperialGuild.sol";

contract ShatteredWL is IShatteredWL, Pausable {
    // address => can call
    mapping(address => bool) private admins;

    struct HonorsList {
        bool isHonorsMember;
        bool hasClaimed;
        uint8 honorsId;
    }

    address public auth;

    address payable ImperialGuildTreasury;

    bool public hasPublicSaleStarted;
    bool public isWLactive;
    bool public isHonorsActive;

    uint256 public constant paidTokens = 10000;
    uint256 public constant whitelistPrice = 0.08 ether;
    uint256 public constant publicPrice = 0.08 ether;

    mapping(address => uint8) private _WLmints;

    mapping(address => HonorsList) private _honorsAddresses;

    event newUser(address newUser);

    bytes32 internal merkleRoot =
        0xd60676eb70cb99e173a40e78e3c1d139722ab50092a4afb575ee44c5c3e78e7f;

    bytes32 internal entropySauce;

    // reference to the colonist NFT collection
    IColonist public colonistNFT;

    constructor() {
        _pause();
        auth = msg.sender;
        admins[msg.sender] = true;
    }

    /** CRITICAL TO SETUP */
    modifier requireContractsSet() {
        require(
            address(colonistNFT) != address(0),
            "Contracts not set"
        );
        _;
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            admins[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;

        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }
    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    function setContracts(address _colonistNFT) external onlyOwner {
        colonistNFT = IColonist(_colonistNFT);
    }

    /** EXTERNAL */

    function WlMintColonist(uint256 amount, bytes32[] calldata _merkleProof)
        external
        payable
        noCheaters
        whenNotPaused
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint16 minted = colonistNFT.minted();
        require(isWLactive == true, "whitelist mints not yeat active");
        require(amount > 0 && amount <= 5, "5 max mints per tx");
        require(minted + amount <= paidTokens, "All sale tokens minted");
        require(amount * whitelistPrice == msg.value, "Invalid payment amount");
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not on the list"
        );
        require(_WLmints[msg.sender] + amount <= 5, "limit 5 per whitelist");
        _WLmints[msg.sender] += uint8(amount);

        uint256 seed;
        address origin = tx.origin;
        bytes32 blockies = blockhash(block.number - 1);
        bytes32 sauce = entropySauce;
        uint256 blockTime = block.timestamp;
        uint16[] memory tokenIds = new uint16[](amount);
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(origin, blockies, sauce, minted, blockTime);
            tokenIds[i] = minted;
            colonistNFT._mintColonist(msg.sender, seed);
        }
        emit newUser(msg.sender);
    }

    /** Mint colonist.
     */
    function mintColonist(uint256 amount)
        external
        payable
        noCheaters
        whenNotPaused
    {
        uint16 minted = colonistNFT.minted();
        require(amount > 0 && amount <= 5, "5 max mints per tx");
        require(minted + amount <= paidTokens, "All sale tokens minted");
        require(hasPublicSaleStarted == true, "Public sale not open");
        require(msg.value >= amount * publicPrice, "Invalid Payment amount");
        uint256 seed;
        address origin = tx.origin;
        bytes32 blockies = blockhash(block.number - 1);
        bytes32 sauce = entropySauce;
        uint256 blockTime = block.timestamp;
        uint16[] memory tokenIds = new uint16[](amount);
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(origin, blockies, sauce, minted, blockTime);
            tokenIds[i] = minted;
            colonistNFT._mintColonist(msg.sender, seed);
        }
        emit newUser(msg.sender);
    }

    /**Mint to honors */
    function mintToHonors(uint256 amount, address recipient)
        external
        onlyOwner
    {
        uint16 minted = colonistNFT.minted();
        require(minted + amount <= 1000, "Honor tokens have been sent");
        uint16[] memory tokenIds = new uint16[](amount);
        uint256 seed;
        address origin = tx.origin;
        bytes32 blockies = blockhash(block.number - 1);
        bytes32 sauce = entropySauce;
        uint256 blockTime = block.timestamp;
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(origin, blockies, sauce, minted, blockTime);
            tokenIds[i] = minted;
            colonistNFT._mintToHonors(address(recipient), seed);
        }
        emit newUser(recipient);
    }

    function revealHonors() external noCheaters {
        require(isHonorsActive == true, "Honor mints have not been activated");
        require(
            _honorsAddresses[msg.sender].isHonorsMember,
            "Not an honors student"
        );
        require(
            _honorsAddresses[msg.sender].hasClaimed == false,
            "Already claimed"
        );

        uint8 id = _honorsAddresses[msg.sender].honorsId;
        _honorsAddresses[msg.sender].hasClaimed = true;
        colonistNFT._mintHonors(msg.sender, id);

        emit newUser(msg.sender);
    }

    function addToHonorslist(address honorsAddress, uint8 honorsId)
        external
        onlyOwner
    {
        _honorsAddresses[honorsAddress] = HonorsList({
            isHonorsMember: true,
            hasClaimed: false,
            honorsId: honorsId
        });
    }

    function togglePublicSale(bool startPublicSale) external onlyOwner {
        hasPublicSaleStarted = startPublicSale;
    }

    function toggleHonorsActive(bool _honorsActive) external onlyOwner {
        isHonorsActive = _honorsActive;
    }

    function toggleWLactive(bool _isWLactive) external onlyOwner {
        isWLactive = _isWLactive;
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disbale
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function random(
        address origin,
        bytes32 blockies,
        bytes32 sauce,
        uint16 seed,
        uint256 blockTime
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(origin, blockies, blockTime, sauce, seed)
                )
            );
    }

    function setImperialGuildTreasury(address payable _ImperialGuildTreasury)
        external
        onlyOwner
    {
        ImperialGuildTreasury = _ImperialGuildTreasury;
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(ImperialGuildTreasury).transfer(address(this).balance);
    }
}
