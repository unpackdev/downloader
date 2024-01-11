// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IVesting.sol";
import "./IBondsRegistry.sol";
import "./Position.sol";
import "./Constants.sol";

/// @title ERC721 Vesting contract
/// @notice Vesting positions contract
/// @dev Each non fungible position is represented in this contract by a tokenId
/// using the ERC721 standard, which can be freely transferred to a new address if desired,
/// and allows more flexibility of integrations such as revenue distributions, bonds
/// and DeFi composability in general.
/// @dev This contract used for ILV tokens can be extended/modified for supporting different
/// underlying ERC20 tokens in Illuvium protocol in the future.
/// @author Pedro Bergamini | 0xpedro.eth
contract Vesting is IVesting, UUPSUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    /* ======== LIBRARIES ======== */
    using Position for Position.Data;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /* ======== STATE VARIABLES ======== */
    /// @dev Underlying ERC20 token address (ILV token)
    IERC20Upgradeable public underlying;
    /// @dev Revenue distributions vault contract address
    address public vault;
    /// @dev Bonds contract address
    IBondsRegistry public bondsRegistry;
    /// @dev Tracks token id to be used for the next minted token
    CountersUpgradeable.Counter public tokenIdTracker;
    /// @dev Revenue distribution allocated per token, used to calculate
    /// revdis rewards for locked positions
    uint256 public revDisPerToken;
    /// @dev Total amount of underlying tokens in positions
    uint256 public underlyingSupplied;
    /// @dev Whether ERC721 transfers should be allowed. Needs to be set to true in order
    /// to allow ERC721 transfers.
    bool public isTransferAllowed;
    /// @dev Value used to store baseURI returned in {ERC721Upgradeable._baseURI}
    string internal baseURI_;
    /// @dev Locked token holders vesting positions
    mapping(uint256 => Position.Data) public positions;

    /* ======== EVENTS ======== */
    event LogSetTransferState(bool shouldAllow);
    event LogSetBaseURI(string oldBaseURI, string newBaseURI);
    event LogSetBonds(address oldBonds, address newBonds);
    event LogSetVault(address oldVault, address newVault);
    event LogSetPositions(address[] holders, Position.InitParams[] _positions, uint256 totalUnderlying);
    event LogUnlock(address indexed caller, uint256 indexed tokenId, uint256 value);
    event LogClaimRevenueDistribution(address indexed caller, uint256 indexed tokenId, uint256 value);
    event LogReceiveVaultRewards(address indexed vault, uint256 reward);

    /* ======== MODIFIERS ======== */
    modifier onlyBondsRegistry() {
        require(msg.sender == address(bondsRegistry), "only bonds registry allowed");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "only vault allowed");
        _;
    }

    modifier onlyApprovedOrOwner(address _caller, uint256 _tokenId) {
        require(_isApprovedOrOwner(_caller, _tokenId), "invalid _caller");
        _;
    }

    modifier updateRevDis(uint256 _tokenId) {
        Position.Data storage position = positions[_tokenId];
        position.pendingRevDis = position.earnedRevDis(revDisPerToken).toUint128();
        position.revDisPerTokenPaid = revDisPerToken;
        _;
    }

    /// @dev Disables initializer functions in the implementation contract when deployed.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev UUPSUpgradeable initializer
    function initialize(
        string memory _name,
        string memory _symbol,
        IERC20Upgradeable _underlying,
        address _vault
    ) external initializer {
        require(
            bytes(_name).length != 0 &&
                bytes(_symbol).length != 0 &&
                address(_underlying) != address(0) &&
                _vault != address(0),
            "invalid inputs"
        );
        underlying = _underlying;
        vault = _vault;

        __UUPSUpgradeable_init();
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __Pausable_init();
    }

    /// @inheritdoc IVesting
    function vestedUnderlyingFor(uint256 _tokenId) external view virtual returns (uint256 vestedUnderlying) {
        vestedUnderlying = positions[_tokenId].vestedUnderlying();
    }

    /// @inheritdoc IVesting
    function availableUnderlyingFor(uint256 _tokenId) public view virtual returns (uint256 availableUnderlying) {
        uint256 vestedUnderlying = positions[_tokenId].vestedUnderlying();
        uint256 positionAvailableBalance = positions[_tokenId].balance;
        availableUnderlying = vestedUnderlying > positionAvailableBalance ? positionAvailableBalance : vestedUnderlying;
    }

    /// @inheritdoc IVesting
    function pendingRevDisFor(uint256 _tokenId) external view virtual returns (uint256) {
        return positions[_tokenId].earnedRevDis(revDisPerToken);
    }

    /// @inheritdoc IVesting
    function poolTokenReserve() external view virtual returns (uint256) {
        return underlyingSupplied;
    }

    /// @inheritdoc IVesting
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view virtual returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    /// @inheritdoc IVesting
    function setPauseState(bool _shouldPause) external virtual onlyOwner {
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @inheritdoc IVesting
    function setTransferState(bool _shouldAllow) external virtual onlyOwner {
        emit LogSetTransferState(_shouldAllow);
        isTransferAllowed = _shouldAllow;
    }

    /// @inheritdoc IVesting
    function setBaseURI(string memory _newBaseURI) external virtual onlyOwner {
        emit LogSetBaseURI(baseURI_, _newBaseURI);
        baseURI_ = _newBaseURI;
    }

    /// @inheritdoc IVesting
    function setBondsContract(IBondsRegistry _bondsRegistry) external virtual onlyOwner {
        require(address(_bondsRegistry) != address(0), "invalid _bondsRegistry");
        emit LogSetBonds(address(bondsRegistry), address(_bondsRegistry));
        bondsRegistry = _bondsRegistry;
    }

    /// @inheritdoc IVesting
    function setVaultContract(address _vault) external virtual onlyOwner {
        require(_vault != address(0), "invalid _vault");
        emit LogSetVault(vault, _vault);
        vault = _vault;
    }

    /// @inheritdoc IVesting
    function setPositions(address[] calldata _holders, Position.InitParams[] calldata _positions)
        external
        virtual
        override
        onlyOwner
    {
        require(_holders.length == _positions.length, "array length mismatch");
        uint256 totalUnderlying;
        for (uint256 i = 0; i < _holders.length; i++) {
            require(
                _positions[i].end > _positions[i].start && _positions[i].start > 0 && _positions[i].balance > 0,
                "invalid position input"
            );
            totalUnderlying += _positions[i].balance;
            tokenIdTracker.increment();
            uint256 currentTokenId = tokenIdTracker.current();
            _mint(_holders[i], currentTokenId);
            Position.Data memory _position = Position.Data({
                balance: _positions[i].balance,
                unlocked: 0,
                start: _positions[i].start,
                end: _positions[i].end,
                rate: uint256(_positions[i].balance / (_positions[i].end - _positions[i].start)).toUint128(),
                pendingRevDis: 0,
                revDisPerTokenPaid: revDisPerToken
            });
            positions[currentTokenId] = _position;
        }
        underlyingSupplied += totalUnderlying;

        emit LogSetPositions(_holders, _positions, totalUnderlying);
    }

    /// @inheritdoc IVesting
    function unlock(uint256 _tokenId)
        external
        virtual
        whenNotPaused
        onlyApprovedOrOwner(msg.sender, _tokenId)
        updateRevDis(_tokenId)
    {
        address tokenOwner = ownerOf(_tokenId);
        Position.Data storage position = positions[_tokenId];
        uint256 valueToUnlock = availableUnderlyingFor(_tokenId);
        require(valueToUnlock > 0, "zero value to unlock");
        position.balance -= valueToUnlock.toUint128();
        position.unlocked += valueToUnlock.toUint128();
        uint256 currentUnderlyingSupplied = underlyingSupplied;
        if (valueToUnlock > currentUnderlyingSupplied) {
            valueToUnlock = currentUnderlyingSupplied;
        }
        // we assume valueToUnlock is valid if position.balance didn't underflow
        unchecked {
            underlyingSupplied = currentUnderlyingSupplied - valueToUnlock;
        }

        underlying.safeTransfer(tokenOwner, valueToUnlock);
        emit LogUnlock(msg.sender, _tokenId, valueToUnlock);
    }

    /// @inheritdoc IVesting
    function claimRevenueDistribution(uint256 _tokenId)
        external
        virtual
        whenNotPaused
        onlyApprovedOrOwner(msg.sender, _tokenId)
        updateRevDis(_tokenId)
    {
        address tokenOwner = ownerOf(_tokenId);
        Position.Data storage position = positions[_tokenId];
        uint256 pendingRevDis = position.pendingRevDis;
        position.pendingRevDis = 0;

        require(pendingRevDis > 0, "0 pending revdis");
        underlying.safeTransfer(tokenOwner, pendingRevDis);
        emit LogClaimRevenueDistribution(msg.sender, _tokenId, pendingRevDis);
    }

    /// @inheritdoc IVesting
    function afterUnderlyingOffer(
        address _caller,
        uint256 _tokenId,
        uint256 _value
    ) external virtual whenNotPaused onlyBondsRegistry onlyApprovedOrOwner(_caller, _tokenId) updateRevDis(_tokenId) {
        require(_value > 0, "zero underlying");
        positions[_tokenId].balance -= _value.toUint128();
        underlyingSupplied -= _value;

        underlying.safeTransfer(msg.sender, _value);
    }

    /// @inheritdoc IVesting
    function afterOfferResignation(
        address _caller,
        uint256 _tokenId,
        uint256 _value
    ) external virtual whenNotPaused onlyBondsRegistry onlyApprovedOrOwner(_caller, _tokenId) updateRevDis(_tokenId) {
        require(_value > 0, "zero underlying");
        positions[_tokenId].balance += _value.toUint128();
        underlyingSupplied += _value;
    }

    /// @inheritdoc IVesting
    function receiveVaultRewards(uint256 _reward) external virtual whenNotPaused onlyVault {
        require(underlyingSupplied > 0 && _reward > 0, "invalid state or input");

        revDisPerToken += (_reward * Constants.BASE_MULTIPLIER) / underlyingSupplied;
        underlying.safeTransferFrom(msg.sender, address(this), _reward);

        emit LogReceiveVaultRewards(msg.sender, _reward);
    }

    /// @inheritdoc ERC721Upgradeable
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_;
    }

    /// @inheritdoc ERC721Upgradeable
    /// @dev Blocks ERC721 transfers after all positions are setup.
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        require(msg.sender == owner() || isTransferAllowed, "ERC721 transfers not allowed");
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    /// @dev UUPSUpgradeable storage gap
    uint256[41] private __gap;
}
