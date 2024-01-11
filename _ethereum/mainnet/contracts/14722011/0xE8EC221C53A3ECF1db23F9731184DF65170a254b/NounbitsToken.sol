// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Strings.sol";
import "./INounsDescriptor.sol";
import "./INounsSeeder.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";

contract NounbitsToken is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant MINT_LIMIT = 20;
    uint256 public constant PRICE = 0.035 ether;

    // Number of mints per wallet
    mapping(address => uint256) public mints;

    // The internal Nounbit ID tracker
    uint256 private _currentNounId;

    // Pseudorandom hash used for randomization; removing seed storage from mint to lower gas
    bytes32 public pseudorandomHash;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // Whether the pseudorandom hash can be updated
    bool public isPseudorandomLocked;

    // The Nouns token URI descriptor
    INounsDescriptor public descriptor;

    // The Nouns token seeder
    INounsSeeder public seeder;

    // Mint status
    bool public mintActive = false;

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    /**
     * @notice Require that the pseudorandom hash has not been locked.
     */
    modifier whenPseudorandomNotLocked() {
        require(!isPseudorandomLocked, 'Pseudorandom hash is locked');
        _;
    }

    constructor(
        INounsDescriptor _descriptor,
        INounsSeeder _seeder
    ) ERC721A('Nounbits', 'nb') {
        descriptor = _descriptor;
        seeder = _seeder;
    }

    function mint(uint256 mintAmount) public payable {
        require(mintActive, 'mint not active');
        require(_currentNounId + mintAmount <= MAX_TOKENS, 'request exceeds supply');
        require(mints[msg.sender] + mintAmount <= MINT_LIMIT, 'address total mint limit exceeded');
        require(PRICE * mintAmount <= msg.value, 'ether value for mint is not correct');

        _safeMint(msg.sender, mintAmount);
        mints[msg.sender] += mintAmount;
        _currentNounId += mintAmount;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), 'URI query for nonexistent token');

        // derived seeds require descriptor parts to be locked
        INounsSeeder.Seed memory seed = seeder.generateSeed(tokenId, descriptor, pseudorandomHash);
        return descriptor.dataURI(tokenId, seed);
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(INounsDescriptor _descriptor) external onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(INounsSeeder _seeder) external onlyOwner whenSeederNotLocked {
        seeder = _seeder;
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external onlyOwner whenSeederNotLocked {
        isSeederLocked = true;
    }

    function setPseudorandomHash() external onlyOwner whenPseudorandomNotLocked {
        pseudorandomHash = blockhash(block.number - 1);
    }

    /**
     * @notice Lock the pseudorandom hash. On chain reveal!
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockPseudorandom() external onlyOwner whenPseudorandomNotLocked {
        isPseudorandomLocked = true;
    }

    function toggleMintStatus() external onlyOwner {
        mintActive = !mintActive;
    }

    // Nouns DAO treasury
    address private constant nounsAddress = 0x0BC3807Ec262cB779b38D65b38158acC3bfedE10;

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(msg.sender), balance * 2 / 5);
        Address.sendValue(payable(nounsAddress), balance * 3 / 5);
    }
}