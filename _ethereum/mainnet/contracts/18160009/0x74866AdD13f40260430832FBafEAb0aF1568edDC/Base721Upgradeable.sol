// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721WithPermitUpgradable.sol";

import "./BaseUpgradeable.sol";
import "./BaseTypeCollectionUpgradeable.sol";
import "./PaymenProcessingUpgradeable.sol";
import "./AccountRegistryUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Helper.sol";
import "./Constants.sol";

import "./IBase721Upgradeable.sol";
import "./IERC6551Registry.sol";

contract Base721Upgradeable is
    IBase721Upgradeable,
    BaseUpgradeable,
    BaseTypeCollectionUpgradeable,
    PaymenProcessingUpgradeable,
    AccountRegistryUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721WithPermitUpgradable
{
    using Helper for *;

    uint256 private _idCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        address roleManager_,
        IERC6551Registry registry_,
        address implementation_,
        uint256[] calldata types_,
        TypeInfo[] calldata typeInfos_
    ) external initializer {
        __ReentrancyGuard_init_unchained();
        __BaseUpgradeable_init_unchained(roleManager_);
        __ERC721WithPermitUpgradable_init(name_, symbol_);
        __AccountRegistryUpgradeable_init_unchained(registry_, implementation_);
        __BaseTypeCollection_init_unchained(types_, typeInfos_);
        _updateFee(FeeInfo(0x2feD6a87f4b73dfD9E0EE5EfEaFc6bF3F9a9Abff, 8700));
        systemAddress = 0x00ff70a41458628e85CE139b533884aae9078C60;
        affiliatePercentageInBps = 300;
        _idCounter = 1;
    }

    function buy(
        uint256 typeNFT_,
        uint256 quantity_,
        address recipient_,
        address referrer_
    ) external payable override nonReentrant {
        TypeInfo memory typeInfo = _typeInfo[typeNFT_];
        uint256 total = typeInfo.price * quantity_;
        uint256 referralBonus;

        if (total == 0) revert NFT__InvalidType();

        (, referralBonus, ) = _processPayment(typeInfo.paymentToken, total, _msgSender(), referrer_);
        _setSold(typeNFT_, quantity_);
        uint256 tokenId = _idCounter;
        emit Registered(recipient_, typeNFT_, tokenId, quantity_, _sold[typeNFT_]);
        emit ReferralBonus(
            address(this),
            tokenId,
            recipient_,
            quantity_,
            typeInfo.paymentToken,
            referrer_,
            referralBonus
        );
        _batchProcess(recipient_, tokenId, quantity_, typeNFT_, typeInfo.executeOperation, typeInfo.operation);
    }

    function batchMint(address recipient_, uint256 typeNFT_, uint256 quantity_) external onlyRole(MINTER_ROLE) {
        _setSold(typeNFT_, quantity_);
        uint256 tokenId = _idCounter;
        emit Registered(recipient_, typeNFT_, tokenId, quantity_, _sold[typeNFT_]);
        _batchProcess(
            recipient_,
            tokenId,
            quantity_,
            typeNFT_,
            _typeInfo[typeNFT_].executeOperation,
            _typeInfo[typeNFT_].operation
        );
    }

    function _batchProcess(
        address account_,
        uint256 tokenId_,
        uint256 totalMint_,
        uint256 typeNFT_,
        bool executeOperation_,
        Operation memory operation_
    ) internal {
        for (uint256 i = 0; i < totalMint_; ) {
            _safeMint(account_, tokenId_);

            if (executeOperation_) {
                address tba = _registry.createAccount(
                    _implementation,
                    block.chainid,
                    address(this),
                    tokenId_,
                    0,
                    abi.encodeWithSignature("initialize()")
                );

                if (operation_.to != address(0)) {
                    bytes memory callData = operation_.data;
                    assembly {
                        mstore(add(callData, 0x24), tba)
                        mstore(add(callData, 0x44), typeNFT_)
                    }
                    operation_.data = callData;

                    _call(operation_);
                }
            }

            unchecked {
                ++tokenId_;
                ++i;
            }
        }
        _idCounter = tokenId_;
    }

    // The following functions are overrides required by Solidity.

    function _baseURI() internal view override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
        return _baseUri;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 batchSize_
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from_, to_, tokenId_, batchSize_);
    }

    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal override(ERC721Upgradeable, ERC721WithPermitUpgradable) {
        super._transfer(from_, to_, tokenId_);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721WithPermitUpgradable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
