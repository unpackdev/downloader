// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./AccessControl.sol";
import "./Initializable.sol";
import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";

import "./ERC2981.sol";
import "./Base64.sol";

contract SecretSeshCollection is ERC721, ERC2981, AccessControl, Initializable {
    using Address for address payable;
    using Strings for uint256;

    /// Fixed at deployment time
    struct DeploymentConfig {
        /// Name of the NFT contract.
        string name;

        /// Symbol of the NFT contract.
        string symbol;

        /// The contract owner address. If you wish to own the contract, then set it as your wallet address.
        /// This is also the wallet that can manage the contract on NFT marketplaces. Use `transferOwnership()`
        /// to update the contract owner.
        address owner;

        /// The maximum number of tokens that can be minted in this collection.
        uint256 maxSupply;

        /// Minting price per token.
        uint256 mintPrice;

        /// Special presale minting price.
        uint256 specialMintPrice;

        /// The maximum number of tokens that OG whitelisted can mint in this collection.
        uint256 ogTokensPerMint;

        /// The maximum number of tokens that Normal whitelisted can mint in this collection.
        uint256 wlTokensPerMint;

        /// A very special presale count
        uint256 specialPresaleCount;

        /// The maximum number of tokens the user can mint per transaction.
        uint256 tokensPerMint;

        /// Treasury address is the address where minting fees can be withdrawn to.
        /// Use `withdrawFees()` to transfer the entire contract balance to the treasury address.
        address payable treasuryAddress;
    }

    /// Updatable by admins and owner
    struct RuntimeConfig {
        /// Metadata base URI for tokens, NFTs minted in this contract will have metadata URI of `baseURI` + `tokenID`.
        /// Set this to reveal token metadata.
        string baseURI;

        /// If true, the base URI of the NFTs minted in the specified contract can be updated after minting (token URIs
        /// are not frozen on the contract level). This is useful for revealing NFTs after the drop. If false, all the
        /// NFTs minted in this contract are frozen by default which means token URIs are non-updatable.
        bool metadataUpdatable;

        /// Starting timestamp for public minting.
        uint256 publicMintStart;

        /// Starting timestamp for whitelisted/presale minting.
        uint256 presaleMintStart;

        /// Pre-reveal token URI for placholder metadata. This will be returned for all token IDs until a `baseURI`
        /// has been set.
        string prerevealTokenURI;

        /// Root of the Merkle tree of whitelisted addresses. This is used to check if a wallet has been whitelisted
        /// for presale minting.
        bytes32 presaleMerkleRoot;

        /// Root of the Merkle tree of whitelisted addresses. This is used to check if a wallet has been whitelisted
        bytes32 ogPresaleMerkleRoot;

        /// Secondary market royalties in basis points (100 bps = 1%)
        uint256 royaltiesBps;

        /// Address for royalties
        address royaltiesAddress;

        /// Metadata file extension
        string metadataExtension;
    }

    struct ContractInfo {
        uint256 version;
        DeploymentConfig deploymentConfig;
        RuntimeConfig runtimeConfig;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /*************
     * Constants *
     *************/

    /// Contract version, semver-style uint X_YY_ZZ
    uint256 public constant VERSION = 1_01_00;

    /// Admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// Owner role
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Basis for calculating royalties.
    // This has to be 10k for royaltiesBps to be in basis points.
    uint16 constant ROYALTIES_BASIS = 10000;

    /********************
     * Public variables *
     ********************/

    /// The number of currently minted tokens
    /// @dev Managed by the contract
    uint256 public totalSupply;

    /***************************
     * Contract initialization *
     ***************************/
    constructor() ERC721("", "") {

    }

    /// Contract initializer
    function initialize(
        DeploymentConfig memory deploymentConfig,
        RuntimeConfig memory runtimeConfig
    ) public initializer {
        _validateDeploymentConfig(deploymentConfig);

        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, deploymentConfig.owner);
        _grantRole(DEFAULT_ADMIN_ROLE, deploymentConfig.owner);
        _grantRole(OWNER_ROLE, deploymentConfig.owner);

        _deploymentConfig = deploymentConfig;
        _runtimeConfig = runtimeConfig;
    }

    /****************
     * User actions *
     ****************/

    /// Mint tokens
    function mint(uint256 amount) external payable {
        require(mintingActive(), "Minting has not started yet");
        require(
            amount <= _deploymentConfig.tokensPerMint,
            "Amount too large"
        );

        _mintTokens(msg.sender, amount, _deploymentConfig.mintPrice);
    }

    /// Mint tokens if the wallet has been whitelisted
    function presaleMint(uint256 amount, bytes32[] calldata proof)
    external
    payable
    {
        require(presaleActive(), "Presale has not started yet");
//        require(!_presaleMinted[msg.sender], "Already minted");
        require(
            isWhitelisted(msg.sender, proof) || isOGWhitelisted(msg.sender, proof),
            "Not whitelisted for presale"
        );

        uint256 totalAmount = _deploymentConfig.wlTokensPerMint;
        if (isOGWhitelisted(msg.sender, proof)) {
            totalAmount = _deploymentConfig.ogTokensPerMint;
        }
        require(
            amount <= totalAmount,
            "Amount too large"
        );

        uint256 _mintPrice = _deploymentConfig.specialMintPrice;

        _presaleMinted[msg.sender] = true;
        _mintTokens(msg.sender, amount, _mintPrice);
    }

    function specialMint(uint256 amount)
        external
        payable
        onlyRole(ADMIN_ROLE)
    {
        uint256 newSupply = totalSupply + amount;
        require(
            newSupply <= _deploymentConfig.maxSupply,
            "Maximum supply reached"
        );

        // Update totalSupply only once with the total minted amount
        totalSupply = newSupply;
        for (uint256 i = 0; i < amount; i++) {
            _mint(_deploymentConfig.owner, totalSupply - i);
        }
    }

    /******************
     * View functions *
     ******************/

    /// Check if public minting is active
    function mintingActive() public view returns (bool) {
        return block.timestamp > _runtimeConfig.publicMintStart;
    }

    /// Check if presale minting is active
    function presaleActive() public view returns (bool) {
        return block.timestamp > _runtimeConfig.presaleMintStart;
    }

    /// Check if the wallet is whitelisted for the presale
    function isWhitelisted(address wallet, bytes32[] calldata proof)
    public
    view
    returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(proof, _runtimeConfig.presaleMerkleRoot, leaf);
    }

    function isOGWhitelisted(address wallet, bytes32[] calldata proof)
    public
    view
    returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(proof, _runtimeConfig.ogPresaleMerkleRoot, leaf);
    }

    /// Contract owner address
    /// @dev Required for easy integration with OpenSea
    function owner() public view returns (address) {
        return _deploymentConfig.owner;
    }

    function getAssetsByOwner(address _owner) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(_owner);
        uint256[] memory assets = new uint256[](balance);

        uint256 j = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (ownerOf(i) == _owner) {
                assets[j] = i;
                j++;
                if (j == balance) {
                    break;
                }
            }
        }

        return assets;
    }

    /*******************
     * Access controls *
     *******************/

    /// Transfer contract ownership
    function transferOwnership(address newOwner)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newOwner != _deploymentConfig.owner, "Already the owner");

        _revokeRole(ADMIN_ROLE, _deploymentConfig.owner);
        _revokeRole(DEFAULT_ADMIN_ROLE, _deploymentConfig.owner);

        address previousOwner = _deploymentConfig.owner;
        _deploymentConfig.owner = newOwner;

        _grantRole(ADMIN_ROLE, _deploymentConfig.owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _deploymentConfig.owner);

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /// Transfer contract ownership
    function transferAdminRights(address to) external onlyRole(ADMIN_ROLE) {
        require(!hasRole(ADMIN_ROLE, to), "Already an admin");
        require(msg.sender != _deploymentConfig.owner, "Use transferOwnership");

        _revokeRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, to);
    }

    /*****************
     * Admin actions *
     *****************/

    /// Get full contract information
    /// @dev Convenience helper
    function getInfo() external view returns (ContractInfo memory info) {
        info.version = VERSION;
        info.deploymentConfig = _deploymentConfig;
        info.runtimeConfig = _runtimeConfig;
    }

    /// Update contract configuration
    /// @dev Callable by admin roles only
    function updateConfig(RuntimeConfig calldata newConfig)
    external
    onlyRole(ADMIN_ROLE)
    {
        _validateRuntimeConfig(newConfig);
        _runtimeConfig = newConfig;
    }

    /// Withdraw minting fees to the treasury address
    /// @dev Callable by admin roles only
    function withdrawFees() external onlyRole(ADMIN_ROLE) {
        _deploymentConfig.treasuryAddress.sendValue(address(this).balance);
    }

    /*************
     * Internals *
     *************/

    /// Contract configuration
    RuntimeConfig internal _runtimeConfig;
    DeploymentConfig internal _deploymentConfig;

    /// Mapping for tracking presale mint status
    mapping(address => bool) internal _presaleMinted;

    /// Mapping for tracking presale mint status
    mapping(address => uint256) internal _presaleOGAmounts;
    mapping(address => uint256) internal _presaleWLAmounts;

    /// @dev Internal function for performing token mints
    function _mintTokens(address to, uint256 amount, uint256 _mintPrice) internal {
        require(
            msg.value >= amount * _mintPrice,
            "Payment too small"
        );

        uint256 newSupply = totalSupply + amount;
        require(
            newSupply <= _deploymentConfig.maxSupply,
            "Maximum supply reached"
        );

        // Update totalSupply only once with the total minted amount
        totalSupply = newSupply;

        // Mint the required amount of tokens,
        // starting with the highest token ID
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalSupply - i);
        }
    }

    /// Validate deployment config
    function _validateDeploymentConfig(DeploymentConfig memory config)
    internal
    pure
    {
        require(config.maxSupply > 0, "Maximum supply must be non-zero");
        require(config.tokensPerMint > 0, "Tokens per mint must be non-zero");
        require(
            config.treasuryAddress != address(0),
            "Treasury address cannot be the null address"
        );
        require(config.owner != address(0), "Contract must have an owner");
    }

    /// Validate a runtime configuration change
    function _validateRuntimeConfig(RuntimeConfig calldata config)
    internal
    view
    {
        // Can't set royalties to more than 100%
        require(config.royaltiesBps <= ROYALTIES_BASIS, "Royalties too high");

        // If metadata is updatable, we don't have any other limitations
        if (_runtimeConfig.metadataUpdatable) return;

        // If it isn't, has we can't allow the flag to change anymore
        require(
            _runtimeConfig.metadataUpdatable == config.metadataUpdatable,
            "Cannot unfreeze metadata"
        );

        // We also can't allow base URI to change
        require(
            keccak256(abi.encodePacked(_runtimeConfig.baseURI)) ==
            keccak256(abi.encodePacked(config.baseURI)),
            "Metadata is frozen"
        );
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, AccessControl, ERC2981)
    returns (bool)
    {
        return
        ERC721.supportsInterface(interfaceId) ||
        AccessControl.supportsInterface(interfaceId) ||
        ERC2981.supportsInterface(interfaceId);
    }

    /// Get the token metadata URI
    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        if (bytes(_runtimeConfig.baseURI).length > 0) {
            string memory filename = tokenId.toString();
            if (bytes(_runtimeConfig.metadataExtension).length > 0) {
                filename = string(abi.encodePacked(filename, _runtimeConfig.metadataExtension));
            }

            return string(abi.encodePacked(
                    _runtimeConfig.baseURI,
                    filename
                ));
        }

        return _runtimeConfig.prerevealTokenURI;
    }

    /// @dev Need name() to support setting it in the initializer instead of constructor
    function name() public view override returns (string memory) {
        return _deploymentConfig.name;
    }

    /// @dev Need symbol() to support setting it in the initializer instead of constructor
    function symbol() public view override returns (string memory) {
        return _deploymentConfig.symbol;
    }

    /// @dev ERC2981 token royalty info
    function royaltyInfo(uint256, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _runtimeConfig.royaltiesAddress;
        royaltyAmount =
        (_runtimeConfig.royaltiesBps * salePrice) /
        ROYALTIES_BASIS;
    }

    /// @dev OpenSea contract metadata
    function contractURI() external view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"seller_fee_basis_points": ',
                        _runtimeConfig.royaltiesBps.toString(),
                        ', "fee_recipient": "',
                        uint256(uint160(_runtimeConfig.royaltiesAddress))
                        .toHexString(20),
                        '"}'
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    /***********************
     * Convenience getters *
     ***********************/

    function maxSupply() public view returns (uint256) {
        return _deploymentConfig.maxSupply;
    }

    function mintPrice() public view returns (uint256) {
        return _deploymentConfig.mintPrice;
    }

    function tokensPerMint() public view returns (uint256) {
        return _deploymentConfig.tokensPerMint;
    }

    function treasuryAddress() public view returns (address) {
        return _deploymentConfig.treasuryAddress;
    }

    function publicMintStart() public view returns (uint256) {
        return _runtimeConfig.publicMintStart;
    }

    function presaleMintStart() public view returns (uint256) {
        return _runtimeConfig.presaleMintStart;
    }

    function presaleMerkleRoot() public view returns (bytes32) {
        return _runtimeConfig.presaleMerkleRoot;
    }

    function baseURI() public view returns (string memory) {
        return _runtimeConfig.baseURI;
    }

    function metadataUpdatable() public view returns (bool) {
        return _runtimeConfig.metadataUpdatable;
    }

    function prerevealTokenURI() public view returns (string memory) {
        return _runtimeConfig.prerevealTokenURI;
    }
}
