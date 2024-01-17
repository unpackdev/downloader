//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./IERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";

error Vault__GivenHashIsNotEmpty();
error Vault__NoGiftByGivenHash(bytes32);
error Vault__CallerIsNotMarket();
error Vault__GivenTargetAddressToClaimIsIncorrect();

contract Cruzo1155Vault is
    Initializable,
    ContextUpgradeable,
    UUPSUpgradeable,
    ERC1155HolderUpgradeable,
    OwnableUpgradeable
{
    modifier isCallerMarket() {
        if (_msgSender() != marketAddress) {
            revert Vault__CallerIsNotMarket();
        }
        _;
    }
    modifier isGiftExists(string calldata secretKey) {
        if (
            vaultedTokens[keccak256(bytes(secretKey))].tokenAddress ==
            address(0)
        ) {
            revert Vault__NoGiftByGivenHash(keccak256(bytes(secretKey)));
        }
        _;
    }
    modifier isGivenHashEmpty(bytes32 _hash) {
        if (vaultedTokens[_hash].tokenAddress != address(0)) {
            revert Vault__GivenHashIsNotEmpty();
        }
        _;
    }
    modifier isGivenTargetAddressValid(address _addressToCheck) {
        if (
            _addressToCheck == address(0) ||
            _addressToCheck == marketAddress ||
            _addressToCheck == address(this)
        ) {
            revert Vault__GivenTargetAddressToClaimIsIncorrect();
        }
        _;
    }
    event GiftVaulted(
        bytes32 hash,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 indexed amount
    );
    event GiftClaimed(
        bytes32 hash,
        address indexed claimer,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount
    );
    struct TokenCredentials {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    address public marketAddress;

    mapping(bytes32 => TokenCredentials) vaultedTokens;

    constructor() {}

    function initialize(address _marketAddress) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Context_init();
        marketAddress = _marketAddress;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _claimGift(string calldata _secretKey, address _targetAddress)
        internal
        isGiftExists(_secretKey)
        isGivenTargetAddressValid(_targetAddress)
    {
        bytes32 _hash = keccak256(bytes(_secretKey));
        TokenCredentials memory token = vaultedTokens[_hash];
        IERC1155Upgradeable(token.tokenAddress).safeTransferFrom(
            address(this),
            _targetAddress,
            token.tokenId,
            token.amount,
            ""
        );
        delete vaultedTokens[_hash];
        emit GiftClaimed(
            _hash,
            _targetAddress,
            token.tokenAddress,
            token.tokenId,
            token.amount
        );
    }

    function claimGiftForMyself(string calldata _secretKey) external {
        _claimGift(_secretKey, _msgSender());
    }

    function claimGiftForAnotherPerson(
        string calldata _secretKey,
        address _targetAddress
    ) external {
        _claimGift(_secretKey, _targetAddress);
    }

    function holdGift(
        bytes32 _hash,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external isGivenHashEmpty(_hash) isCallerMarket {
        vaultedTokens[_hash] = TokenCredentials(
            _tokenAddress,
            _tokenId,
            _amount
        );
        emit GiftVaulted(_hash, _tokenAddress, _tokenId, _amount);
    }

    function setMarketAddress(address newAddress) external onlyOwner {
        marketAddress = newAddress;
    }
}
