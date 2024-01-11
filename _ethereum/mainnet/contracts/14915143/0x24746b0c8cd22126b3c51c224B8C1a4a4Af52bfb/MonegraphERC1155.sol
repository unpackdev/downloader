// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./ERC1155Upgradeable.sol";

import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155PausableUpgradeable.sol";

import "./AccessControlUpgradeable.sol";

import "./ContextUpgradeable.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./ECDSAUpgradeable.sol";

contract MonegraphERC1155 is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155PausableUpgradeable,
    UUPSUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    event NFTAttributes(uint256 tokenId, Attributes attributes, string uri);
    event WithdrawlFallback(uint256 amount, address to);
    event PublicMintCreated(string id, string metadata);
    event PublicMintUpdated(string id, string metadata);

    struct PublicMint {
        uint256 tokenId;
        address to;
        uint256 amount;
        string uri;
        Attributes attributes;
        bytes signature;
        uint256 expires;
        Beneficiary[] beneficiaries;
    }

    struct Mint {
        uint256 tokenId;
        address to;
        uint256 amount;
        string uri;
        Attributes attributes;
    }

    struct Attributes {
        string language;
        string artist;
        string year;
        string royalty;
        string title;
    }

    struct Beneficiary {
        uint16 percentage;
        address payable wallet;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string public name;
    string public symbol;

    mapping(uint256 => string) private _tokenURIs;

    function initialize(
        string memory _name,
        string memory _symbol,
        address admin,
        bytes memory data
    ) public virtual initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __ERC1155_init_unchained("");
        __ERC1155Burnable_init_unchained();
        __ERC1155Pausable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
        _setupRole(PAUSER_ROLE, admin);

        name = _name;
        symbol = _symbol;
    }

    modifier publicMinter(
        uint256 tokenId,
        address to,
        uint256 amount,
        string memory _uri,
        Attributes memory attributes,
        bytes memory signature,
        uint256 expires,
        Beneficiary[] memory beneficiaries
    ) {
        bytes32 hash = getMinterFromSignature(
            to,
            amount,
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
            "MonegraphERC1155: signature validation failed"
        );

        require(
            expires > block.timestamp,
            "MonegraphERC1155: validation has expired"
        );

        _;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(
            bytes(_tokenURIs[tokenId]).length != 0,
            "MonegraphERC1155: URI set of nonexistent token"
        );

        return _tokenURIs[tokenId];
    }

    function getMinterFromSignature(
        address to,
        uint256 editions,
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
                    editions,
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
            "MonegraphERC1155: Beneficiary allocation must equal 100%"
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

    function mint(Mint[] memory contexts) external virtual {
        for (uint256 i = 0; i < contexts.length; i++) {
            mint(contexts[i]);
        }
    }

    function mint(Mint memory context) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "MonegraphERC1155: must have minter role to mint"
        );

        doMint(context.tokenId, context.to, context.amount, context.uri);

        emit NFTAttributes(context.tokenId, context.attributes, context.uri);
    }

    function mint(PublicMint memory context)
        external
        payable
        virtual
        publicMinter(
            context.tokenId,
            context.to,
            context.amount,
            context.uri,
            context.attributes,
            context.signature,
            context.expires,
            context.beneficiaries
        )
    {
        doMint(context.tokenId, context.to, context.amount, context.uri);

        emit NFTAttributes(context.tokenId, context.attributes, context.uri);

        if (msg.value > 0) {
            checkBeneficiaries(context.beneficiaries);

            disperse(msg.value, context.beneficiaries);
        }
    }

    function doMint(
        uint256 tokenId,
        address to,
        uint256 amount,
        string memory _uri
    ) internal virtual {
        require(
            bytes(_uri).length > 0,
            "MonegraphERC1155: TokenUri can not be empty"
        );

        require(
            bytes(_tokenURIs[tokenId]).length == 0,
            "MonegraphERC1155: token id already exists"
        );

        _mint(to, tokenId, amount, "");

        _tokenURIs[tokenId] = _uri;
    }

    function pause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "MonegraphERC1155: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "MonegraphERC1155: must have pauser role to unpause"
        );
        _unpause();
    }

    function batchGrantMinters(address[] memory addresses)
        external
        onlyRole(getRoleAdmin(MINTER_ROLE))
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            grantRole(MINTER_ROLE, addresses[i]);
        }
    }

    function _burn(
        address account,
        uint256 id,
        uint256 value
    ) internal override {
        super._burn(account, id, value);

        if (bytes(_tokenURIs[id]).length != 0) {
            delete _tokenURIs[id];
        }
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            if (bytes(_tokenURIs[id]).length != 0) {
                delete _tokenURIs[id];
            }
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155Upgradeable, ERC1155PausableUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlUpgradeable)
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
