// SPDX-License-Identifier: GPL-3.0

/// @title The BitstraySantas ERC-721 token

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@........................@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%.................................@@@@@@@@@@@@@
.......................@@@@@@@..............................
./@@@@@@@@@...................@@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@.......@@@@@.........@@@.........@@@@@.......@@@@@.
@%..@@.......................................@@.......@@@..@
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@...@@@@#  @@   @@   .........  ,@@  @@@  .......@@@@@@
@@@@@@.....@@#  @@@@@@@   .........  ,@@@@@@@  .......@@@@@@
@@@@@@.....@@@@@       @@%............       .........@@@@@@
@@@@@@@@@..../@@@@@@@@@.............................@@@@@@@@
@@@@@@@@@............                   ............@@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  .....@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721Checkpointable.sol";
import "./IBitstraysDescriptor.sol";
import "./IBitstraysSeeder.sol";
import "./IBitstraySantasToken.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./MerkleProof.sol";
import "./IProxyRegistry.sol";
import "./SafeMath.sol";

contract BitstraySantasToken is IBitstraySantasToken, Ownable, ERC721Checkpointable {
    // The bitstrays DAO address (creators org)
    address public bitstraysDAO;

    // The Bitstrays token URI descriptor
    IBitstraysDescriptor public descriptor;

    // The Bitstrays token seeder
    IBitstraysSeeder public seeder;

    // records number of public sale mint
    uint256 public MAX_TOKENS_MINTED_BY_ADDRESS = 1;
    mapping(address => uint256) private _tokensMintedByAddress;
    mapping(address => uint256) private _tokensGiftedByAddress;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // Whether the public mint is activte
    bool public override isMintActive = true;

    // max supply
    uint256 public constant MAX_BITSTRAYSANTAS = 500;

    // max reserved
    uint256 public reserved = 10;

    // max reserved
    uint256 public reserveMinted = 0;


    // The bitstray seeds
    mapping(uint256 => IBitstraysSeeder.Seed) public seeds;

    // The internal bitstray ID tracker
    uint256 private _currentBitstraySantaId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash = 'QmcHocXwe49LivpWgoqDH4gushrkPcrKXTQmhUCaRR28Zf';

    // Wallets
    address private dev_wallet = 0x3F0580f99cD9672CB69911afEF46365134Ab51e9;
    address private null_address = 0x0000000000000000000000000000000000000000;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

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
     * @notice Require that the sender is the bitstrays DAO.
     */
    modifier onlyBitstraysDAO() {
        require(msg.sender == bitstraysDAO, 'Sender is not the bitstrays DAO');
        _;
    }

    constructor(
        address _bitstraysDAO,
        IBitstraysDescriptor _descriptor,
        IBitstraysSeeder _seeder,
        IProxyRegistry _proxyRegistry
    ) ERC721('BitstraySantas', 'BITSTRAY-SANTA') {
        bitstraysDAO = _bitstraysDAO;
        descriptor = _descriptor;
        seeder = _seeder;
        proxyRegistry = _proxyRegistry;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Toggle a boolean for public sale
     * @dev This can only be called by the owner.
     */
    function toggleIsMintActive() external override onlyOwner {
        bool enabled = !isMintActive;

        isMintActive = enabled;
        emit PublicMintActive(enabled);
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice calculate the remaining reserved bitstrays
     */
    function remainingReserve() public view returns (uint256) {
        return SafeMath.sub(reserved, reserveMinted);
    }


    /**
     @notice Mint a Bitstray to the msg.sender in amount quanity
     @dev check for ether price and max supply limitations
     */
    function publicMint() external override returns (uint256) {
        require(isMintActive, "Error: Mint state must be active to mint a Bitstray Santa");
        require(_tokensMintedByAddress[msg.sender] + 1 <= MAX_TOKENS_MINTED_BY_ADDRESS, 'Error: Address already minted Bitstrays Santa');
        require(SafeMath.add(totalSupply(), 1) <= MAX_BITSTRAYSANTAS - remainingReserve(), "Error: Your mint would exceed max supply of Bitstrays Santas");
    
        if (totalSupply() < MAX_BITSTRAYSANTAS - remainingReserve()) {
            uint256 id  =  _mintTo(msg.sender, _currentBitstraySantaId++);
            _tokensMintedByAddress[msg.sender] += 1;
            return id;
        }
        revert("Error: Your mint would exceed max supply of Bitstrays Santas");
    }

    /**
     * @notice Mint a Bitstray Santa to the Owner address if project reserve is
     * not 0, Planned reserve is 75
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyOwner returns (uint256) {
        require(totalSupply() < MAX_BITSTRAYSANTAS, "Mint would exceed max supply of Bitstray Santas");
        require(remainingReserve() > 0, "Project reserved mint exceeded");

        if (totalSupply() < MAX_BITSTRAYSANTAS) {
           reserveMinted++;
           return _mintTo(msg.sender, _currentBitstraySantaId++);
        }
        revert("Error: Your mint would exceed max supply of Bitstrays Santas");
    }

    /**
     * @notice Mint a Bitstray Santa to provided address if project reserve is
     * not 0, Used to distriute reserve
     * @dev Call _mintTo with the to address(es).
     */
    function mintTo(address to) public override returns (uint256) {
        require(totalSupply() < MAX_BITSTRAYSANTAS, "Mint would exceed max supply of Bitstray Santas");
        require(remainingReserve() > 0, "Project reserved mint exceeded");

        if (totalSupply() < MAX_BITSTRAYSANTAS) {
           reserveMinted++;
           return _mintTo(to, _currentBitstraySantaId++);
        }
        revert("Error: Your mint would exceed max supply of Bitstrays Santas");
    }

    /**
     * @notice Mint a Bitstray Santa to provided address if project reserve is
     * not 0, Used to distriute reserve
     * @dev Call _mintTo with the to address(es).
     */
    function giftTo(address to) public override returns (uint256) {
        require(isMintActive, "Error: Mint state must be active to mint a Bitstrays Santa");
        require(to!= null_address, "Null Address is not allowed for gifting use burn");
        require(_tokensMintedByAddress[to] + 1 <= MAX_TOKENS_MINTED_BY_ADDRESS, 'Error: Address already minted 1 Bitstrays Santa');
        require(_tokensGiftedByAddress[msg.sender] + 1 <= MAX_TOKENS_MINTED_BY_ADDRESS, 'Error: Address has already gifted 1 Bitstrays Santa');
        require(SafeMath.add(totalSupply(), 1) <= MAX_BITSTRAYSANTAS - remainingReserve(), "Error: Your mint would exceed max supply of Bitstrays Santas");

        if (totalSupply() < MAX_BITSTRAYSANTAS - remainingReserve()) {
           uint256 id  = _mintTo(to, _currentBitstraySantaId++);
           _tokensMintedByAddress[to] += 1;
           _tokensGiftedByAddress[msg.sender] += 1;
           return id;
        }
        revert("Error: Your mint would exceed max supply of Bitstrays Santas");
    }

    /**
     * @notice Burn a Bitstray Santa.
     */
    function burn(uint256 bitstrayId) public override onlyOwner {
        _burn(bitstrayId);
        emit BitstraySantaBurned(bitstrayId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'BitstraySantasToken: URI query for nonexistent token');
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'BitstraySantasToken: URI query for nonexistent token');
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set the bitstrays DAO.
     * @dev Only callable by the bitstrays DAO when not locked.
     */
    function setBitstraysDAO(address _bitstraysDAO) external override onlyBitstraysDAO {
        bitstraysDAO = _bitstraysDAO;

        emit BitstraysDAOUpdated(_bitstraysDAO);
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(IBitstraysDescriptor _descriptor) external override onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(IBitstraysSeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Mint a Bitstray Stanta with `bitstrayId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 bitstrayId) internal returns (uint256) {
        IBitstraysSeeder.Seed memory seed = seeds[bitstrayId] = seeder.generateSeed(bitstrayId, descriptor);

        _mint(to, bitstrayId);
        emit BitstraySantaCreated(bitstrayId, seed);

        return bitstrayId;
    }

    /**
     * @notice withdraw any funds which might be deposited
     */
    function withdraw() public payable onlyOwner {

		uint256 _dev = address(this).balance;
		//payable(bitstraysDAO).transfer(_dao);
        payable(dev_wallet).transfer(_dev);
    }
}
