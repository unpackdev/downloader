// SPDX-License-Identifier: GPL-3.0

/// @title The Bitstrays ERC-721 token

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
import "./IBitstraysToken.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./MerkleProof.sol";
import "./IProxyRegistry.sol";
import "./SafeMath.sol";

contract BitstraysToken is IBitstraysToken, Ownable, ERC721Checkpointable {
    // The bitstrays DAO address (creators org)
    address public bitstraysDAO;

    // The Bitstrays token URI descriptor
    IBitstraysDescriptor public descriptor;

    // The Bitstrays token seeder
    IBitstraysSeeder public seeder;

    bytes32 public root = 0xf36c82ca1f91c011de946302a0c7534f2300a9fbe6cf2d4bb959322206cc1692;

    // records number of presales mint
    uint256 private constant MAX_TOKENS_MINTED_BY_ADDRESS_PRESALE = 3;
    mapping(address => uint256) private _tokensMintedByAddressAtPresale;

    // records number of public sale mint
    uint256 public MAX_TOKENS_MINTED_BY_ADDRESS = 10;
    mapping(address => uint256) private _tokensMintedByAddress;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // Whether the presale mint is activte
    bool public override isPresaleActive = false;

    // Whether the public mint is activte
    bool public override isSaleActive = false;

    // max supply
    uint256 public constant MAX_BITSTRAYS = 10000;

    // max reserved
    uint256 public reserved = 75;

    // max reserved
    uint256 public reserveMinted = 0;

    // initial mint price
    uint256 public constant bitstrayPrice = 50000000000000000; // 0.05 ETH

    // The bitstray seeds
    mapping(uint256 => IBitstraysSeeder.Seed) public seeds;

    // The internal bitstray ID tracker
    uint256 private _currentBitstrayId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash = 'QmQxRbLqGfrzQosFe9Ku3FKWVFGC74EPQHv35jWEWoaMjm';

    // Wallets
    address private dev_wallet = 0x3F0580f99cD9672CB69911afEF46365134Ab51e9;

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
    ) ERC721('Bitstrays', 'BITSTRAY') {
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
     * @notice Amount of token minted during pre-sale a single address.
     */
    function getTokensMintedAtPresale(address account) external view override returns(uint256) {
        return _tokensMintedByAddressAtPresale[account];
    }

    /**
     * @notice Toggle a boolean for public sale
     * @dev This can only be called by the owner.
     */
    function toggleIsSaleActive() external override onlyOwner {
        bool enabled = !isSaleActive;

        isSaleActive = enabled;
        emit PublicSaleActive(enabled);
    }


    /**
     * @notice Toggle a boolean for public pre-sale
     * @dev This can only be called by the owner.
     */
    function toggleIsPresaleActive() external override onlyOwner {
        bool enabled = !isPresaleActive;

        isPresaleActive = enabled;
        emit PublicPresaleActive(enabled);
    }

    /**
     * @notice set merkel root for pre-sales whitelist.
     */
    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
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
    function publicMint(uint amount, bytes32[] memory proof) external override payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (isPresaleActive == true && isSaleActive == false) {
            require(_tokensMintedByAddressAtPresale[msg.sender] + amount <= MAX_TOKENS_MINTED_BY_ADDRESS_PRESALE, 'Error: You can only mint a total of 3 Bitstrays during pre-sales');
            require(MerkleProof.verify(proof, root, leaf), "Error: Wallet not whitelisted: Invalid merkle proof");
        } else {
            require(isSaleActive, "Error: Sale/Presale state must be active to mint a Bitstrays");
            require(_tokensMintedByAddress[msg.sender] + amount <= MAX_TOKENS_MINTED_BY_ADDRESS, 'Error: Already minted Bitstrays during sale + requested amount of new Bitstrays exceeds limit of 10');
        }
        
        require(SafeMath.add(totalSupply(),amount) <= MAX_BITSTRAYS - remainingReserve(), "Error: Your purchase would exceed max supply of Bitstrays");
        require(msg.value >= SafeMath.mul(bitstrayPrice, amount), "Error: Incorrect ether amount provided for selected quantity");
        for(uint i = 0; i < amount; i++) {
            if (totalSupply() < MAX_BITSTRAYS - remainingReserve()) {
                _mintTo(msg.sender, _currentBitstrayId++);
            }
        }
        // Post minting.
        if (isPresaleActive == true && isSaleActive == false) {
            _tokensMintedByAddressAtPresale[msg.sender] += amount;
        } else {
            _tokensMintedByAddress[msg.sender] += amount;
        }
    }

    /**
     * @notice Mint a Bitstray to the Owner address if project reserve is
     * not 0, Planned reserve is 75
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyOwner returns (uint256) {
        require(totalSupply() < MAX_BITSTRAYS, "Mint would exceed max supply of Bitstrays");
        require(remainingReserve() > 0, "Project reserved mint exceeded");

        if (totalSupply() < MAX_BITSTRAYS) {
           reserveMinted++;
           return _mintTo(msg.sender, _currentBitstrayId++);
        }
        revert();
    }

    /**
     * @notice Mint a Bitstray to provided address if project reserve is
     * not 0, Used to distriute reserve
     * @dev Call _mintTo with the to address(es).
     */
    function mintTo(address to) public override onlyOwner returns (uint256) {
        require(totalSupply() < MAX_BITSTRAYS, "Mint would exceed max supply of Bitstrays");
        require(remainingReserve() > 0, "Project reserved mint exceeded");

        if (totalSupply() < MAX_BITSTRAYS) {
           reserveMinted++;
           return _mintTo(to, _currentBitstrayId++);
        }
        revert();
    }

    /**
     * @notice Burn a bitstray.
     */
    function burn(uint256 bitstrayId) public override onlyOwner {
        _burn(bitstrayId);
        emit BitstrayBurned(bitstrayId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'BitstraysToken: URI query for nonexistent token');
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'BitstraysToken: URI query for nonexistent token');
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
     * @notice Mint a Bitstray with `bitstrayId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 bitstrayId) internal returns (uint256) {
        IBitstraysSeeder.Seed memory seed = seeds[bitstrayId] = seeder.generateSeed(bitstrayId, descriptor);

        _mint(to, bitstrayId);
        emit BitstrayCreated(bitstrayId, seed);

        return bitstrayId;
    }

    function withdraw() public payable onlyOwner {

        //uint256 _dao = (address(this).balance * 20) / 100;
        // Calculated from the rest of the balance
		uint256 _dev = address(this).balance;
		//payable(bitstraysDAO).transfer(_dao);
        payable(dev_wallet).transfer(_dev);
    }
}
