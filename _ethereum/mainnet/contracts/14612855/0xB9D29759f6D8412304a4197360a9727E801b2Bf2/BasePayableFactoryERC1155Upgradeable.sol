// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./PullPaymentUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC165Upgradeable.sol";

import "./IPayableFactoryERC1155Upgradeable.sol";
import "./AestheticERC1155Upgradeable.sol";

import "./console.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract BasePayableFactoryERC1155Upgradeable is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC165Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    PullPaymentUpgradeable,
    PayableFactoryERC1155Upgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for string;

    address internal nftAddress;
    uint256 public override fixedPrice;
    address payable internal payeeAddress;

    function __BasePayableFactoryERC1155Upgradeable_init(
        address _nftAddress,
        uint256 _fixedPrice,
        address _payeeAddress
    ) internal onlyInitializing {
        __Context_init();
        __ReentrancyGuard_init();
        __ERC165_init();
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __PullPayment_init();

        __BasePayableFactoryERC1155Upgradeable_init_unchained(
            _nftAddress,
            _fixedPrice,
            _payeeAddress
        );
    }

    function __BasePayableFactoryERC1155Upgradeable_init_unchained(
        address _nftAddress,
        uint256 _fixedPrice,
        address _payeeAddress
    ) internal onlyInitializing {
        nftAddress = _nftAddress;
        fixedPrice = _fixedPrice;
        payeeAddress = payable(_payeeAddress);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(PayableFactoryERC1155Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawPayments(address payable payee)
        public
        virtual
        override
        onlyOwner
    {
        super.withdrawPayments(payee);
    }

    function setFixedPrice(uint256 _fixedPrice) external onlyOwner {
        fixedPrice = _fixedPrice;
    }

    function buy(
        address _toAddress,
        uint256 _amount,
        bytes calldata _data
    ) external payable override whenNotPaused {
        require(
            canMint(_amount),
            "PayableFactoryCounterERC1155Upgradeable#buy: CANNOT_MINT_MORE"
        );

        require(
            msg.value == fixedPrice * _amount,
            "PayableFactoryCounterERC1155Upgradeable#buy: Transaction value did not equal the mint price"
        );
        _mint(_toAddress, _amount, _data);

        _asyncTransfer(payeeAddress, msg.value);
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        AestheticERC1155Upgradeable nft = AestheticERC1155Upgradeable(
            nftAddress
        );
        return nft.exists(_tokenId);
    }

    /*
     * Note: make sure code that calls this is non-reentrant.
     * Note: this is the token _id *within* the ERC1155 contract, not the option
     *       id from this contract.
     */
    function _createOrMint(
        address _erc1155Address,
        address _toAddress,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) internal {
        console.log(
            "_createOrMint(_toAddress = %s, _tokenId = %s, _amount = %s)",
            _toAddress,
            _tokenId,
            _amount
        );

        AestheticERC1155Upgradeable nft = AestheticERC1155Upgradeable(
            _erc1155Address
        );

        require(!nft.exists(_tokenId), "token _tokenId already exists");
        nft.mint(_toAddress, _tokenId, _amount, _data);
    }

    function _mint(
        address _toAddress,
        uint256 _amount,
        bytes memory _data
    ) internal nonReentrant {
        console.log(
            "_mint(_toAddress = %s, _amount = %s)",
            _toAddress,
            _amount
        );
        if (_amount == 1) {
            uint256 _id = _nextId();
            console.log("_mint() -> _id = %s", _id);
            _createOrMint(nftAddress, _toAddress, _id, 1, _data);
        } else {
            uint256[] memory _ids = _nextIds(_amount);
            for (uint256 i = 0; i < _ids.length; i++) {
                uint256 _id = _ids[i];
                console.log("_mint() -> _ids[%s] = %s", i, _id);
                _createOrMint(nftAddress, _toAddress, _id, 1, _data);
            }
        }
    }

    function canMint(uint256 _amount) public view override returns (bool) {
        require(
            _amount > 0,
            "BasePayableFactoryERC1155Upgradeable#_canMint: amount must be at least 1"
        );
        return balanceOf(owner()) >= _amount;
    }

    function balanceOf(address _fromAddress)
        public
        view
        virtual
        override
        returns (uint256);

    function _nextId() internal virtual returns (uint256);

    function _nextIds(uint256 _amount)
        internal
        virtual
        returns (uint256[] memory);

    uint256[45] private __gap;
}
