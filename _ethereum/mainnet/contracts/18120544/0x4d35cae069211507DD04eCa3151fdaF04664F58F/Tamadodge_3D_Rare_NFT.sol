// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./ERC2981Upgradeable.sol";

interface INFT {
    function upgradeMint(
        address to
    ) external;
}

error ZeroAddress();
error EmptyString();
error ArrayLengthMismatch();
error InvalidUser();
error InvalidUserNonce();
error InvalidSignature();
error CannotAcceptERC721();
error TokenAlreadyExists();
error TokenNotPresent();

contract Tamadodge_3D_Rare_NFT is
    Initializable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable,
    EIP712Upgradeable,
    ERC2981Upgradeable
{
    // State Variables
    using CountersUpgradeable for CountersUpgradeable.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    CountersUpgradeable.Counter public tokenIdCounter;

    /// @dev Storage variable for EIP-712 signatures.
    bytes32 private constant MINT_DETAILS =
        keccak256(
            (
                "MintDetails(address from,address to,uint256 userNonce,uint256 nftId)"
            )
        );

    /// @dev base uri
    string public currentBaseURI;
    /// @dev nft to be minted when current nft is upgraded.
    address public nextLevelNFT;

    /// @dev mapping of user address and their corresponding nonce for this contract.
    mapping(address => uint256) public userNonces;

    struct MintDetails {
        address from;
        address to;
        uint256 userNonce;
        uint256 nftId;
    }

    struct Admins {
        address admin;
        address minter;
        address upgrader;
        address signer;
        address royaltyReceiver;
    }

    event MintAndTransfer(
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 nftId
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract.
     * @param _name NFT name
     * @param _symbol NFT symbol
     * @param _admins Struct specifying the admin details
     * @param _nextLevelNFT address of nft to be used upon upgrading
     * @param _feeNumerator fee for royalty
     * @param _currentBaseURI base uri
     * @param _domainName domain name for EIP 712 Domain.
     * @param _version version for EIP 712 Domain.
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        Admins calldata _admins,
        address _nextLevelNFT,
        uint96 _feeNumerator,
        string memory _currentBaseURI,
        string calldata _domainName,
        string calldata _version
    ) public initializer {
        if (
            _admins.admin == address(0) ||
            _admins.minter == address(0) ||
            _admins.upgrader == address(0) ||
            _admins.signer == address(0) ||
            _admins.royaltyReceiver == address(0)
        ) revert ZeroAddress();
        if (
            !(bytes(_currentBaseURI).length >0 &&
            bytes(_name).length >0 &&
            bytes(_version).length >0)
        ) revert EmptyString();

        __ERC721_init(_name, _symbol);
        __ERC721Burnable_init();
        __AccessControl_init();
        __EIP712_init(_domainName, _version);
        __ERC2981_init();

        tokenIdCounter.increment();
        currentBaseURI = _currentBaseURI;
        nextLevelNFT = _nextLevelNFT;

        _setDefaultRoyalty(_admins.royaltyReceiver, _feeNumerator);

        _grantRole(DEFAULT_ADMIN_ROLE, _admins.admin);
        _grantRole(MINTER_ROLE, _admins.minter);
        _grantRole(UPGRADE_ROLE, _admins.upgrader);
        _grantRole(SIGNER_ROLE, _admins.signer);
    }

    /**
     * @dev Return the base uri
     */
    function _baseURI() internal view override returns (string memory) {
        return currentBaseURI;
    }

    /**
     * @dev Set Base URI.
     * @param _newBaseURI base uri to be updated.
     *
     * Requirement:
     * - Only default admin can access this function.
     *
     */
    function setBaseURI(
        string memory _newBaseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!(bytes(_newBaseURI).length > 0)) revert EmptyString();

        currentBaseURI = _newBaseURI;
    }

    /**
     * @dev Function to mint nft
     * @param _to Address to which nft has to be minted.
     *
     * Requiremnt:
     * - Only minter cn access this function.
     *
     */
    function mint(address _to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(_to, tokenId);
    }

    /**
     * @dev Batch Mint
     * @param _to address
     * @param _amount no of nfts to be minted.
     *
     * Requirement:
     * - Only minter can access this function.
     *
     */
    function batchMint(address _to, uint256 _amount) external {
        for (uint i = 1; i <= _amount; ) {
            mint(_to);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Batch transfer of NFTs.
     * @param _from Address from which transfer has to be made.
     * @param _to List of address to which NFT has to be transferred.
     * @param _ids List of ids.
     *
     * Requiremnet:
     * - Length of _to and _ids array shouldbe same.
     * _ msg.sender should be the owner or should have approved nfts, only then this can be called.
     */
    function batchTransfer(
        address _from,
        address[] calldata _to,
        uint256[] calldata _ids
    ) external {
        if (_to.length != _ids.length) revert ArrayLengthMismatch();

        for (uint i = 0; i < _ids.length; ) {
            safeTransferFrom(_from, _to[i], _ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Function used to upgrade and mint new NFT.
     * @param _user Address to which nft has to be minted.
     * @param _nftId id of the current nft.
     *
     * Requiremnts:
     * - Can only be called by the user with {UPGRADE_ROLE}.
     */
    function upgradeNFT(
        address _user,
        uint256 _nftId
    ) external onlyRole(UPGRADE_ROLE) {
        burn(_nftId);
        INFT(nextLevelNFT).upgradeMint(_user);
    }

    /**
     * @dev Mints NFT to given address
     * @param _to Address to which new NFT has to be minted.
     *
     * Requiremnets:
     * - Can only be called by minter.
     *
     * NOTE:
     * - This is called during upgrade.
     *
     */
    function upgradeMint(
        address _to
    ) external {
        mint(_to);
    }

    /**
     * @dev Function to mint and transfer NFT in a single go.
     * @param _data Struct specifying the details for minting.
     * @param _signature Signature of signer with mint details.
     *
     * Requirements:
     * - Caller should be the one making mint and transfer.
     * - Nonce of caller should be in consistent with the nonce of caller in the contract.
     * - Caller should provide a valid signature.
     * - Sender and Receiver cannot not be zero address.
     * - Receiver should be capable of accepting ERC721.
     */
    function mintAndTransfer(
        MintDetails calldata _data,
        bytes calldata _signature
    ) external {
        address from = _data.from;
        address to = _data.to;

        if (_data.from != msg.sender) revert InvalidUser();
        if (++userNonces[msg.sender] != _data.userNonce)
            revert InvalidUserNonce();
        if (!_verifySignature(_data, _signature)) revert InvalidSignature();
        if (from == address(0) || to == address(0)) revert ZeroAddress();

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _mintAndTransfer(from, to, tokenId, _data.nftId);

        if (!_checkOnERC721Received(address(0), to, tokenId, ""))
            revert CannotAcceptERC721();
    }

    /**
     * @dev Function to mint and transfer NFT - internal function
     * @param _from Address from where NFT has to be transfered.
     * @param _to Address to which NFT has to be transferred.
     * @param _tokenId Id of the token.
     *
     */
    function _mintAndTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _nftId
    ) internal {
        _beforeTokenTransfer(address(0), _to, _tokenId, 1);
        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        if (_exists(_tokenId)) revert TokenAlreadyExists();

        unchecked {
            _balances[_to] += 1;
        }

        _owners[_tokenId] = _to;
        emit Transfer(address(0), _from, _tokenId);
        if (_from != _to) emit Transfer(_from, _to, _tokenId);
        emit MintAndTransfer(_from, _to, _tokenId, _nftId);
        _afterTokenTransfer(address(0), _to, _tokenId, 1);
    }

    /**
     * @dev Function to set Royalty for a particular token.
     * @param _tokenId Token Id to which royalty is set.
     * @param _receiver Royalty receiver.
     * @param _feeNumerator Royalty fee percentage.
     *
     * Requiremnts:
     * - Can only be accessed by admin.
     * - cannot set Royalty for NFT that doesn't exists.
     *
     */
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_exists(_tokenId)) revert TokenNotPresent();
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            AccessControlUpgradeable,
            ERC2981Upgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    // ----------------------------EIP-712 functions.------------------------------------------------------------------

    /**
     * @dev Returns a bool on completing verification of signature.
     * @param _data  Data to be used for signature verification.
     * @param _signature Signature to be verified.
     *
     * NOTE:
     * - Message signer should have SIGNER_ROLE.
     */
    function _verifySignature(
        MintDetails calldata _data,
        bytes calldata _signature
    ) private view returns (bool) {
        bytes32 digest = _getDigest(_data);
        address signer = _getSigner(digest, _signature);
        return hasRole(SIGNER_ROLE, signer);
    }

    function _getDigest(
        MintDetails calldata _data
    ) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MINT_DETAILS,
                        _data.from,
                        _data.to,
                        _data.userNonce,
                        _data.nftId
                    )
                )
            );
    }

    /**
     * @dev Returns the signer address.
     */
    function _getSigner(
        bytes32 _digest,
        bytes calldata _signature
    ) private pure returns (address) {
        return ECDSAUpgradeable.recover(_digest, _signature);
    }
}
