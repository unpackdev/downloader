//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlMixin.sol";
import "./BaseRelayRecipient.sol";

import "./ERC20BurnableUpgradeable.sol";

// May be need modify buyBox() function from burnFrom() to transferFrom() to accept more token, and burn or withdraw after
contract GoldFeverMaskBoxStore is
    Initializable,
    AccessControlMixin,
    BaseRelayRecipient,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    mapping(address => bool) public acceptedTokens;
    mapping(address => uint256) public prices;

    event MaskBoxBought(
        address indexed buyer,
        address indexed token,
        uint256 amount
    );
    event PriceSet(address indexed token, uint256 price);
    event AcceptedTokenAdded(address indexed token);
    event AcceptedTokenRemoved(address indexed token);
    event ForwarderContractUpdated(address forwarder_);

    function initialize() public initializer {
        __GoldFeverMaskBoxStore_init();
    }

    function __GoldFeverMaskBoxStore_init() internal onlyInitializing {
        __GoldFeverMaskBoxStore_init_unchained();
        __ReentrancyGuard_init();
        _setupContractId("GoldFeverMaskBoxStore");
        __UUPSUpgradeable_init();
    }

    function __GoldFeverMaskBoxStore_init_unchained()
        internal
        onlyInitializing
    {
        _setupContractId("GoldFeverMerchantRight");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setPrice(
        address token,
        uint256 price
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            acceptedTokens[token],
            "GoldFeverMaskBoxStore: payment token not accepted"
        );
        prices[token] = price;
        emit PriceSet(token, price);
    }

    function addAcceptedToken(
        address token,
        uint256 price
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        acceptedTokens[token] = true;
        emit AcceptedTokenAdded(token);

        prices[token] = price;
        emit PriceSet(token, price);
    }

    function removeAcceptedToken(
        address token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        acceptedTokens[token] = false;
        emit AcceptedTokenRemoved(token);

        prices[token] = 0;
        emit PriceSet(token, 0);
    }

    function buyBox(uint256 amount, address token) external nonReentrant {
        require(
            acceptedTokens[token],
            "GoldFeverMaskBoxStore: payment token not accepted"
        );
        ERC20BurnableUpgradeable(token).burnFrom(
            _msgSender(),
            amount * prices[token]
        );
        emit MaskBoxBought(_msgSender(), token, amount);
    }

    function buyBoxFor(
        uint256 amount,
        address token,
        address buyer
    ) external nonReentrant {
        require(
            acceptedTokens[token],
            "GoldFeverMaskBoxStore: payment token not accepted"
        );

        address nullAddress = 0x000000000000000000000000000000000000dEaD;
        ERC20BurnableUpgradeable(token).transferFrom(
            _msgSender(),
            nullAddress,
            amount * prices[token]
        );
        emit MaskBoxBought(buyer, token, amount);
    }

    // Both AccessControlMixin and BaseRelayRecipient defined _msgSender() _msgData()
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, BaseRelayRecipient)
        returns (address sender)
    {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, BaseRelayRecipient)
        returns (bytes calldata)
    {
        return BaseRelayRecipient._msgData();
    }

    function setForwarderContract(
        address forwarder_
    ) external only(DEFAULT_ADMIN_ROLE) {
        _setTrustedForwarder(forwarder_);
        emit ForwarderContractUpdated(forwarder_);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function versionRecipient()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return "2.2.5";
    }
}
