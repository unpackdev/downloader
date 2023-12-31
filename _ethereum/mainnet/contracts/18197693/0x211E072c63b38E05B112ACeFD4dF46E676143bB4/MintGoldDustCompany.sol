// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC165.sol";

/// @title A contract responsible by Mint Gold Dust management.
/// @notice Contains functions for access levels management.
/// @author Mint Gold Dust LLC
/// @custom:contact klvh@mintgolddust.io
contract MintGoldDustCompany is Initializable, IERC165, OwnableUpgradeable {
    /**
     * @dev all attributes are public to be accessible by the other contracts
     * that are composed by this one
     */
    uint256 public primarySaleFeePercent;
    uint256 public secondarySaleFeePercent;
    uint256 public collectorFee;
    uint256 public maxRoyalty;
    uint256 public auctionDuration;
    uint256 public auctionFinalMinutes;
    address public publicKey;
    bytes4 private constant ERC165_ID = 0x01ffc9a7; //ERC165
    mapping(address => bool) public isArtistApproved;
    mapping(address => bool) public isAddressValidator;

    event ArtistWhitelisted(address indexed artistAddress, bool state);

    event ValidatorAdded(address indexed validatorAddress, bool state);

    error Unauthorized();

    /// @notice that this modifier is used to check if the address is a validator or the owner
    modifier isValidatorOrOwner() {
        if (isAddressValidator[msg.sender] || msg.sender == owner()) {
            _;
        } else {
            revert Unauthorized();
        }
    }

    /// @notice that this modifier is used to check if the address is not zero address
    modifier isZeroAddress(address _address) {
        require(_address != address(0), "address is zero address");
        _;
    }

    /**
     *
     * @param _owner is the address that should be the owner of the contract.
     * @param _primarySaleFeePercent is the fee setted for primary sales (15%)
     * @param _secondarySaleFeePercent is the fee setted for secondary sales (5%)
     * @param _collectorFee is the fee paid by collectors setted for primary sales (3%)
     * @param _maxRoyalty is the maximum percetange that an artist can set to its artwork (20%)
     * @param _auctionDurationInMinutes is the duration of the auction in minutes (86400)
     * @param _auctionFinalMinutes is the duration of the final minutes of the auction (300)
     */
    function initialize(
        address _owner,
        uint256 _primarySaleFeePercent,
        uint256 _secondarySaleFeePercent,
        uint256 _collectorFee,
        uint256 _maxRoyalty,
        uint256 _auctionDurationInMinutes,
        uint256 _auctionFinalMinutes
    ) external initializer isZeroAddress(_owner) {
        __Ownable_init();
        _transferOwnership(_owner);
        primarySaleFeePercent = _primarySaleFeePercent;
        secondarySaleFeePercent = _secondarySaleFeePercent;
        collectorFee = _collectorFee;
        maxRoyalty = _maxRoyalty;
        auctionDuration = _auctionDurationInMinutes * 1 seconds;
        auctionFinalMinutes = _auctionFinalMinutes * 1 seconds;
    }

    /// @notice Set the public key to be used by the Mint Gold Dust Company
    /// @param _mintGoldDustPublicKey is the public key to be used by the Mint Gold Dust Company
    function setPublicKey(
        address _mintGoldDustPublicKey
    ) external onlyOwner isZeroAddress(_mintGoldDustPublicKey) {
        publicKey = _mintGoldDustPublicKey;
    }

    /// @notice Add new validators to Mint Gold Dust Company
    function setValidator(
        address _address,
        bool _state
    ) external onlyOwner isZeroAddress(_address) {
        isAddressValidator[_address] = _state;
        emit ValidatorAdded(_address, _state);
    }

    /// @notice Whitelist/Blacklist artist
    function whitelist(
        address _address,
        bool _state
    ) external isValidatorOrOwner isZeroAddress(_address) {
        isArtistApproved[_address] = _state;
        emit ArtistWhitelisted(_address, _state);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == ERC165_ID;
    }
}
