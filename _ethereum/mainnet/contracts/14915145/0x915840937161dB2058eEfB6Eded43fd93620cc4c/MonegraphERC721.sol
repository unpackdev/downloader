// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Upgradeable.sol";

import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";

import "./AccessControlUpgradeable.sol";

import "./ContextUpgradeable.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./ECDSAUpgradeable.sol";

contract MonegraphERC721 is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721URIStorageUpgradeable,
    UUPSUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    event NFTAttributes(uint256 tokenId, Attributes attributes, string uri);
    event WithdrawlFallback(uint256 amount, address to);
    event PublicMintCreated(string id, string metadata);
    event PublicMintUpdated(string id, string metadata);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address public initializedBy;

    address payable monegraphAddress;

    struct Attributes {
        string language;
        string artist;
        string year;
        string royalty;
        string title;
    }

    struct Mint {
        uint256 tokenId;
        address to;
        string uri;
        Attributes attributes;
    }

    struct PublicMint {
        uint256 tokenId;
        address to;
        string uri;
        Attributes attributes;
        bytes signature;
        uint256 expires;
        Beneficiary[] beneficiaries;
    }

    struct Beneficiary {
        uint16 percentage;
        address payable wallet;
    }

    function initialize(
        string memory name,
        string memory symbol,
        address admin,
        bytes memory info
    ) public virtual initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC721URIStorage_init_unchained();
        __UUPSUpgradeable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
        _setupRole(PAUSER_ROLE, admin);

        initializedBy = admin;
    }

    modifier publicMinter(
        uint256 tokenId,
        address to,
        string memory _uri,
        Attributes memory attributes,
        bytes memory signature,
        uint256 expires,
        Beneficiary[] memory beneficiaries
    ) {
        bytes32 hash = getMinterFromSignature(
            to,
            expires,
            tokenId,
            _uri,
            attributes,
            beneficiaries
        );

        require(
            hasRole(
                MINTER_ROLE,
                hash.toEthSignedMessageHash().recover(signature)
            ),
            "MonegraphERC721: signature validation failed"
        );

        require(
            expires > block.timestamp,
            "MonegraphERC721: validation has expired"
        );

        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    function isNotEmptyString(string memory _string)
        internal
        pure
        returns (bool)
    {
        return bytes(_string).length > 0;
    }

    function getMinterFromSignature(
        address to,
        uint256 expires,
        uint256 tokenId,
        string memory _uri,
        Attributes memory attributes,
        Beneficiary[] memory beneficiaries
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    tokenId,
                    to,
                    msg.value,
                    expires,
                    _uri,
                    beneficiaries,
                    attributes
                )
            );
    }

    function checkBeneficiaries(Beneficiary[] memory beneficiaries)
        internal
        pure
    {
        uint16 total = 0;

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            address payable wallet = beneficiaries[i].wallet;

            require(
                wallet != address(0),
                "Black Hole wallet cannot be a beneficiary"
            );

            require(
                beneficiaries[i].percentage > 0,
                "Zero value beneficiary distribution"
            );

            total += beneficiaries[i].percentage;
        }

        require(
            total == 10000,
            "MonegraphERC721: Beneficiary allocation must equal 100%"
        );
    }

    function disperse(uint256 total, Beneficiary[] memory beneficiaries)
        internal
    {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            Beneficiary memory beneficiary = beneficiaries[i];

            uint256 amount = (total / 10000) * beneficiary.percentage;

            (bool success, ) = beneficiary.wallet.call{
                value: amount,
                gas: 20000
            }("");

            if (!success) {
                emit WithdrawlFallback(total, beneficiary.wallet);

                payable(0xF82d31541fE4F96dfeE2A2C306f70086D91d67c9).transfer(
                    amount
                );
            }
        }
    }

    function createPublicMint(string memory id, string memory metadata)
        external
        onlyRole(MINTER_ROLE)
    {
        emit PublicMintCreated(id, metadata);
    }

    function updatePublicMint(string memory id, string memory metadata)
        external
        onlyRole(MINTER_ROLE)
    {
        emit PublicMintUpdated(id, metadata);
    }

    function bulkMint(Mint[] memory contexts) external virtual {
        for (uint256 i = 0; i < contexts.length; i++) {
            mint(contexts[i]);
        }
    }

    function mint(Mint memory context) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "MonegraphERC721: must have minter role to mint"
        );

        doMint(context.tokenId, context.to, context.uri);

        emit NFTAttributes(
            context.tokenId,
            context.attributes,
            tokenURI(context.tokenId)
        );
    }

    function mint(PublicMint memory context)
        external
        payable
        virtual
        publicMinter(
            context.tokenId,
            context.to,
            context.uri,
            context.attributes,
            context.signature,
            context.expires,
            context.beneficiaries
        )
    {
        doMint(context.tokenId, context.to, context.uri);

        emit NFTAttributes(context.tokenId, context.attributes, context.uri);

        if (msg.value > 0) {
            checkBeneficiaries(context.beneficiaries);

            disperse(msg.value, context.beneficiaries);
        }
    }

    function doMint(
        uint256 tokenId,
        address to,
        string memory _uri
    ) internal virtual {
        require(
            isNotEmptyString(_uri),
            "MonegraphERC721: TokenUri can not be empty"
        );

        _mint(to, tokenId);
        _setTokenURI(tokenId, _uri);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        return super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function pause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "MonegraphERC721: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "MonegraphERC721: must have pauser role to unpause"
        );
        _unpause();
    }

    function batchGrantMinters(address[] memory addresses)
        external
        virtual
        onlyRole(getRoleAdmin(MINTER_ROLE))
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            grantRole(MINTER_ROLE, addresses[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721PausableUpgradeable
        )
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlUpgradeable,
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
