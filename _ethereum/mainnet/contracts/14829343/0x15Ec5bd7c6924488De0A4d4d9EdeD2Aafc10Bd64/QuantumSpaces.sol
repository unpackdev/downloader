//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721QUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./BitMapsUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC2981V3.sol";
import "./TokenId.sol";
import "./ManageableUpgradeable.sol";

error VariantAndMintAmountMismatch();
error InvalidVariantForDrop();
error MintExceedsDropSupply();
error InvalidAuthorizationSignature();
error NotValidYet(uint256 validFrom, uint256 blockTimestamp);
error AuthorizationExpired(uint256 expiredAt, uint256 blockTimestamp);
error IncorrectFees(uint256 expectedFee, uint256 suppliedMsgValue);

contract QuantumSpaces is
    ERC2981,
    OwnableUpgradeable,
    ManageableUpgradeable,
    ERC721QUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;
    using TokenId for uint256;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    /// >>>>>>>>>>>>>>>>>>>>>>>  EVENTS  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    event DropMint(
        address indexed to,
        uint256 indexed dropId,
        uint256 indexed variant,
        uint256 id
    );

    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    struct MintAuthorization {
        uint256 id;
        address to;
        uint128 dropId;
        uint128 amount;
        uint256 fee;
        bytes32 r;
        bytes32 s;
        uint256 validFrom;
        uint256 validPeriod;
        uint8 v;
        uint8 freezePeriod;
        uint256[] variants;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(uint128 => string) internal _dropCID;
    mapping(uint128 => uint128) internal _dropMaxSupply;
    mapping(uint256 => uint256) internal _tokenVariant;
    BitMapsUpgradeable.BitMap private _isDropUnpaused;

    string private _ipfsURI;
    address private _authorizer;
    address payable private _quantumTreasury;

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///

    function initialize(
        address admin,
        address payable quantumTreasury,
        address authorizer
    ) public virtual initializer {
        __QuantumSpaces_init(admin, quantumTreasury, authorizer);
    }

    function __QuantumSpaces_init(
        address admin,
        address payable quantumTreasury,
        address authorizer
    ) internal onlyInitializing {
        __ERC721Q_init("QuantumSpaces", "QSPACE");
        __Ownable_init();
        __Manageable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __QuantumSpaces_init_unchained(admin, quantumTreasury, authorizer);
    }

    function __QuantumSpaces_init_unchained(
        address admin,
        address payable quantumTreasury,
        address authorizer
    ) internal onlyInitializing {
        _baseURI = "https://core-api.quantum.art/v1/metadata/spaces/";
        _ipfsURI = "ipfs://";
        _quantumTreasury = quantumTreasury;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MANAGER_ROLE, admin);
        _authorizer = authorizer;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  RESTRICTED  <<<<<<<<<<<<<<<<<<<<<< ///

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice set address of the minter
    /// @param owner The address of the new owner
    function setOwner(address owner) public onlyOwner {
        transferOwnership(owner);
    }

    /// @notice set address of the minter
    /// @param minter The address of the minter - should be wallet proxy or sales platform
    function setMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, minter);
    }

    /// @notice remove address of the minter
    /// @param minter The address of the minter - should be wallet proxy or sales platform
    function unsetMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, minter);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function setManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function unsetManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }

    /// @notice set address of the authorizer wallet
    /// @param authorizer The address of the authorizer - should be wallet proxy or sales platform
    function setAuthorizer(address authorizer)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _authorizer = authorizer;
    }

    /// @notice set address of the treasury wallet
    /// @param treasury The address of the treasury
    function setTreasury(address payable treasury)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _quantumTreasury = treasury;
    }

    /// @notice set the baseURI
    /// @param baseURI new base
    function setBaseURI(string calldata baseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseURI = baseURI;
    }

    /// @notice set the base ipfs URI
    /// @param ipfsURI new base
    function setIpfsURI(string calldata ipfsURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _ipfsURI = ipfsURI;
    }

    /// @notice set the IPFS CID
    /// @param dropId The drop id
    /// @param cid cid
    function setCID(uint128 dropId, string calldata cid)
        public
        onlyRole(MANAGER_ROLE)
    {
        _dropCID[dropId] = cid;
    }

    /// @notice configure a drop
    /// @param dropId The drop id
    /// @param maxSupply maximum items in the drop
    /// @param numOfVariants number of expected variants in drop (zero if normal drop)
    function setDrop(
        uint128 dropId,
        uint128 maxSupply,
        uint256 numOfVariants
    ) public onlyRole(MANAGER_ROLE) {
        _dropMaxSupply[dropId] = maxSupply;
        _dropNumOfVariants[dropId] = numOfVariants;
    }

    /// @notice sets the recipient of the royalties
    /// @param recipient address of the recipient
    function setRoyaltyRecipient(address recipient)
        public
        onlyRole(MANAGER_ROLE)
    {
        _royaltyRecipient = recipient;
    }

    /// @notice sets the fee of royalties
    /// @dev The fee denominator is 10000 in BPS.
    /// @param fee fee
    /*
        Example

        This would set the fee at 5%
        ```
        KeyUnlocks.setRoyaltyFee(500)
        ```
    */
    function setRoyaltyFee(uint256 fee) public onlyRole(MANAGER_ROLE) {
        _royaltyFee = fee;
    }

    function setDropRoyalties(
        uint128 dropId,
        address recipient,
        uint256 fee
    ) public onlyRole(MANAGER_ROLE) {
        _dropRoyaltyRecipient[dropId] = recipient;
        _dropRoyaltyFee[dropId] = fee;
    }

    /// @notice Mints new tokens via a presigned authorization voucher
    /// @dev there is no check regarding limiting supply
    /// @param mintAuth preauthorization voucher
    function authorizedMint(MintAuthorization calldata mintAuth)
        public
        payable
    {
        // require(msg.sender == owner || msg.sender == _minter, "NOT_AUTHORIZED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        mintAuth.id,
                        mintAuth.to,
                        mintAuth.dropId,
                        mintAuth.amount,
                        mintAuth.fee,
                        mintAuth.validFrom,
                        mintAuth.validPeriod,
                        mintAuth.freezePeriod,
                        mintAuth.variants
                    )
                )
            )
        );
        address signer = ecrecover(digest, mintAuth.v, mintAuth.r, mintAuth.s);
        if (signer != _authorizer) revert InvalidAuthorizationSignature();
        if (msg.value != mintAuth.fee)
            revert IncorrectFees(mintAuth.fee, msg.value);
        if (block.timestamp < mintAuth.validFrom)
            revert NotValidYet(mintAuth.validFrom, block.timestamp);
        if (
            mintAuth.validPeriod > 0 &&
            block.timestamp > mintAuth.validFrom + mintAuth.validPeriod
        )
            revert AuthorizationExpired(
                mintAuth.validFrom + mintAuth.validPeriod,
                block.timestamp
            );

        _mint(
            mintAuth.to,
            mintAuth.dropId,
            mintAuth.amount,
            mintAuth.variants,
            mintAuth.freezePeriod
        );
        AddressUpgradeable.sendValue(_quantumTreasury, mintAuth.fee);
    }

    /// @notice Mints new tokens
    /// @dev there is no check regarding limiting supply
    /// @param to recipient of newly minted tokens
    /// @param dropId id of the key
    /// @param amount amount of tokens to mint
    /// @param variants use variants/episodes for token - zero for unique drops
    function mint(
        address to,
        uint128 dropId,
        uint128 amount,
        uint256[] calldata variants,
        uint8 freezePeriod
    ) public onlyRole(MINTER_ROLE) {
        // require(msg.sender == owner || msg.sender == _minter, "NOT_AUTHORIZED");
        _mint(to, dropId, amount, variants, freezePeriod);
    }

    function _mint(
        address to,
        uint128 dropId,
        uint128 amount,
        uint256[] calldata variants,
        uint8 freezePeriod
    ) internal {
        if (_minted[dropId] == 0) _minted[dropId] = 1; //If drop is not preallocated
        uint256 numOfVariants = variants.length;
        if (
            _dropMaxSupply[dropId] == 0 ||
            (_minted[dropId] - 1) + amount > _dropMaxSupply[dropId]
        ) revert MintExceedsDropSupply();
        if (numOfVariants != 0 && amount != numOfVariants)
            revert VariantAndMintAmountMismatch();

        uint256 currentVariant;
        if (numOfVariants > 0) {
            //Check each variant isn't outside range
            do {
                if (
                    variants[currentVariant] < 1 ||
                    variants[currentVariant] > _dropNumOfVariants[dropId]
                ) revert InvalidVariantForDrop();
            } while (currentVariant < numOfVariants);
        }
        currentVariant = 0;

        uint256 startTokenId = TokenId.from(
            dropId,
            uint128(_minted[dropId] - 1)
        );
        _safeMint(to, dropId, amount, freezePeriod, "");
        if (numOfVariants > 0) {
            do {
                emit DropMint(
                    to,
                    dropId,
                    variants[currentVariant],
                    startTokenId + currentVariant
                );
                _tokenVariant[startTokenId + currentVariant] = variants[
                    currentVariant++
                ];
            } while (currentVariant < numOfVariants);
        } else {
            uint256 endTokenId = startTokenId + amount;
            do {
                emit DropMint(to, dropId, 0, startTokenId++);
            } while (startTokenId <= endTokenId);
        }
    }

    /// @notice Pre-allocate storage slots upfront for a drop
    /// @dev Sales platform only
    /// @param dropId dropId to preload with gas
    /// @param quantity amount of tokens to preallocate storage space for
    function preAllocateTokens(uint128 dropId, uint128 quantity)
        public
        onlyRole(MINTER_ROLE)
    {
        _preAllocateTokens(dropId, quantity);
    }

    /// @notice Pre-allocate storage slots for known customers
    /// @dev Sales platform only
    /// @param addresses list of addresses to register
    function preAllocateAddress(address[] calldata addresses)
        public
        onlyRole(MINTER_ROLE)
    {
        _preAllocateAddresses(addresses);
    }

    /// @notice Burns token that has been redeemed for something else
    /// @dev Sales platform only
    /// @param tokenId id of the tokens
    function redeemBurn(uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _burn(tokenId, false);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  VIEW  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Returns the URI of the token
    /// @param tokenId id of the token
    /// @return URI for the token ; expected to be ipfs://<cid>
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        (uint128 dropId, uint128 sequenceNumber) = tokenId.split();
        uint256 actualSequence = _tokenVariant[tokenId] > 0
            ? _tokenVariant[tokenId]
            : sequenceNumber;
        if (bytes(_dropCID[dropId]).length > 0)
            return
                string(
                    abi.encodePacked(
                        _ipfsURI,
                        _dropCID[dropId],
                        "/",
                        actualSequence.toString()
                    )
                );
        else
            return
                string(
                    abi.encodePacked(
                        _baseURI,
                        uint256(dropId).toString(),
                        "/",
                        actualSequence.toString()
                    )
                );
    }

    // /// @notice Returns the URI of the token
    // /// @param dropId id of the drop to check supply on
    // /// @return uint128 maximum number that can be minted in drop
    // function getMaxDropSupply(uint128 dropId) public view returns (uint128) {
    //     return _dropMaxSupply[dropId];
    // }

    // /// @notice Returns the URI of the token
    // /// @param dropId id of the drop to check supply on
    // /// @return uint128 maximum number that can be minted in drop
    // function getSupply(uint128 dropId) public view returns (uint128) {
    //     return _dropMaxSupply[dropId];
    // }

    /// @notice Returns the URI of the token
    /// @param dropId id of the drop to check supply on
    /// @return circulating number of minted tokens from drop
    /// @return max The maximum supply of tokens in the drop
    /// @return exists Whether the drop exists
    /// @return paused Whether the drop is paused
    function drops(uint128 dropId)
        public
        view
        returns (
            uint128 circulating,
            uint128 max,
            bool exists,
            bool paused
        )
    {
        circulating = _dropMaxSupply[dropId] - _mintedInDrop(dropId);
        max = _dropMaxSupply[dropId];
        exists = max != 0;
        paused = !_isDropUnpaused.get(dropId);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  EXTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Burns token
    /// @dev Can be called by the owner or approved operator
    /// @param tokenId id of the tokens
    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721QUpgradeable,
            ERC2981,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return
            ERC721QUpgradeable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  HOOKS  <<<<<<<<<<<<<<<<<<<<<< ///

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        require(!paused(), "Token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
    // ******* V2 Additions ******* //
    mapping(uint128 => uint256) internal _dropNumOfVariants;

    // **************************** //
}
