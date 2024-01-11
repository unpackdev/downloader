//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./IREMXCollection.sol";
import "./IRevenueSplitter.sol";
import "./FreezeableUpgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";

/**
 *
 *  _ __ ___ _ __ ___ __  __
 * | '__/ _ \ '_ ` _ \\ \/ /
 * | | |  __/ | | | | |>  <
 * |_|  \___|_| |_| |_/_/\_\
 *
 * The main REMX NFT smart contract based on the ERC 721 token standard with several
 * customizations:
 *
 * 1. support for EIP 2981 royalty info
 * 2. support for lazy minting by creating and assigning a token to the intended recipient
 *
 * Lazy minting allows the buyer to pay the gas for minting, while maintaining security by
 * allowing an account with MINTER_ROLE to produce a signature that can be verified
 * using EIP712 signatures.
 */
contract REMXCollection is
    FreezeableUpgradeable,
    ERC721Upgradeable,
    ERC721PausableUpgradeable,
    EIP712Upgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC2981Upgradeable,
    IREMXCollection
{
    using ERC165CheckerUpgradeable for address;
    using StringsUpgradeable for uint256;

    // the role of an account authorized to mint tokens by signing the vouchers
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // a connection to the revenue splitter where funds are sent for royalties
    IRevenueSplitter private _revenueSplitter;

    uint256 private _royalty;

    string private _uri;

    string private _contractURI;

    /**
     * @dev initialize the contract and set up for lazy minting
     */
    function initialize(
        address _admin,
        address _minter,
        address revenueSplitter,
        string memory name,
        string memory symbol,
        uint256 royalty,
        string memory baseURI
    ) external initializer {
        __ERC721_init(name, symbol);
        __EIP712_init(name, "1.0.0");
        __Freezeable_init();
        require(
            revenueSplitter.supportsInterface(
                type(IRevenueSplitter).interfaceId
            ),
            "RMX: Invalid deployer"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(PAUSER_ROLE, _admin);
        _setupRole(MINTER_ROLE, _minter);
        _revenueSplitter = IRevenueSplitter(revenueSplitter);
        _royalty = royalty;
        _uri = baseURI;
    }

    /**
     * @dev indicate that the contract conforms to our convention
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            AccessControlUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IREMXCollection).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev set the contract address
     */
    function setContractURI(string memory newContractURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _contractURI = newContractURI;
    }

    /**
     * @dev returns a URL for the storefront-level metadata for the contract
     */
    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        if (bytes(_contractURI).length > 0) {
            return _contractURI;
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "collection.json"))
                : "";
    }

    /**
     * @dev Change base URI for computing {tokenURI}.
     */
    function setBaseURI(string memory baseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _uri = baseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /***
     * @dev EIP 712 based Lazy Minting.  The account to which a token is being minted must
     * sign a message we provide, then they can redeem the signature for the token.
     *
     * Emits a {Transfer} event
     */
    function redeem(
        address account,
        uint256 tokenId,
        uint256 amount,
        uint256 expiryBlock,
        bytes calldata signature
    ) external payable override nonReentrant isNotFrozen(account) {
        require(
            _msgSender() == address(_revenueSplitter) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "RMX: invalid redeemer"
        );
        require(
            _verify(_hash(account, tokenId, amount, expiryBlock), signature),
            "RMX: Invalid signature"
        );
        require(block.number <= expiryBlock, "RMX: Signature has expired");
        _safeMint(account, tokenId);
    }

    /**
     * @dev internal function to compute the hash of input parameters for validation
     */
    function _hash(
        address account,
        uint256 tokenId,
        uint256 amount,
        uint256 expiryBlock
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFT(uint256 tokenId,address account,uint256 amount,uint256 expiryBlock)"
                        ),
                        tokenId,
                        account,
                        amount,
                        expiryBlock
                    )
                )
            );
    }

    /**
     * @dev internal function to verify a hash against a signature
     */
    function _verify(bytes32 digest, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return
            hasRole(MINTER_ROLE, ECDSAUpgradeable.recover(digest, signature));
    }

    /***
     * @dev implements EIP 2981 royaltyInfo by returning the royalty amount
     * and intended recipient for a given token and sale price. This contract
     * is the destination for royalties so it can be forwarded to the revenue
     * splitter correctly.
     */
    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    )
        external
        view
        override(IERC2981Upgradeable)
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);

        // This sets percentages by price * percentage / 100
        royaltyAmount = (_salePrice * _royalty) / 100;
    }

    /**
     * @dev receive royalties, which is forwarded to the revenue splitter
     */

    receive() external payable {
        _revenueSplitter.depositRoyalty{value: msg.value}(address(this));
    }

    /**
     * @dev overridden for Pausable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721PausableUpgradeable) {
        require(!frozen(from), "RMX: sender is frozen");
        require(!frozen(to), "RMX: recipient is frozen");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev pause the contract
     */
    function pause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "RMX: address cannot pause"
        );
        _pause();
    }

    /**
     * @dev pause the contract
     */
    function unpause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "RMX: address cannot unpause"
        );
        _unpause();
    }
}
