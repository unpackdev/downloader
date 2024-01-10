// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ClonesUpgradeable.sol";
import "./IBaseCollection.sol";
import "./INiftyKit.sol";

contract NiftyKit is Initializable, OwnableUpgradeable, INiftyKit {
    struct Entry {
        uint256 value;
        bool isValue;
    }

    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 private constant _rate = 500; // parts per 10,000

    address private _treasury;
    EnumerableSetUpgradeable.AddressSet _collections;

    mapping(address => Entry) private _rateOverride;

    mapping(address => uint256) private _fees;
    mapping(address => uint256) private _feesClaimed;

    mapping(address => Entry) private _partners;
    mapping(address => address) private _referrals;

    uint256 private _partnersBalance;
    mapping(address => uint256) private _partnerFees;
    mapping(address => uint256) private _partnerFeesClaimed;

    address private _implementation;
    address private _dropImplementation;
    address private _tokenImplementation;
    address private _trustedForwarder;

    function initialize(
        address dropImplementation,
        address tokenImplementation,
        address trustedForwarder
    ) public initializer {
        __Ownable_init();
        _treasury = _msgSender();
        _dropImplementation = dropImplementation;
        _tokenImplementation = tokenImplementation;
        _trustedForwarder = trustedForwarder;
    }

    function createDropCollection(
        string memory name,
        string memory symbol,
        address affiliate
    ) external {
        address deployed = _createCollection(
            _dropImplementation,
            name,
            symbol,
            affiliate
        );
        _collections.add(deployed);
        emit CollectionCreated(deployed);
    }

    function createTokenCollection(
        string memory name,
        string memory symbol,
        address affiliate
    ) external {
        address deployed = _createCollection(
            _tokenImplementation,
            name,
            symbol,
            affiliate
        );
        _collections.add(deployed);
        emit CollectionCreated(deployed);
    }

    function setTreasury(address treasury) public onlyOwner {
        _treasury = treasury;
    }

    function setDropImplementation(address implementation) public onlyOwner {
        _dropImplementation = implementation;
    }

    function setTokenImplementation(address implementation) public onlyOwner {
        _tokenImplementation = implementation;
    }

    function addCollection(address collection) public onlyOwner {
        _collections.add(collection);
    }

    function removeCollection(address collection) public onlyOwner {
        _collections.remove(collection);
    }

    function setTrustedForwarder(address trustedForwarder) public onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    function setPartner(address account, uint256 rate) public onlyOwner {
        _partners[account].isValue = true;
        _partners[account].value = rate;
    }

    function setRateOverride(address account, uint256 rate) public onlyOwner {
        _rateOverride[account].isValue = true;
        _rateOverride[account].value = rate;
    }

    function withdraw(uint256 amount) external {
        require(
            address(this).balance - _partnersBalance >= amount,
            "Not enough to withdraw"
        );

        AddressUpgradeable.sendValue(payable(_treasury), amount);
    }

    function disburse(address account) external {
        require(_partners[account].isValue, "Invalid Partner");
        uint256 amount = _partnerFees[account] - _partnerFeesClaimed[account];

        AddressUpgradeable.sendValue(payable(account), amount);

        _partnerFeesClaimed[account] = _partnerFeesClaimed[account].add(amount);
        _partnersBalance = _partnersBalance.sub(amount);
    }

    function addFees(uint256 amount) external override {
        require(_collections.contains(_msgSender()), "Invalid Collection");

        _fees[_msgSender()] = _fees[_msgSender()].add(commission(amount));
    }

    function addFeesClaimed(uint256 amount) external override {
        require(_collections.contains(_msgSender()), "Invalid Collection");

        if (_partners[_referrals[_msgSender()]].isValue) {
            address partner = _referrals[_msgSender()];
            uint256 partnerFee = _partition(_partners[partner].value, amount);
            _partnerFees[partner] = _partnerFees[partner].add(partnerFee);
            _partnersBalance = _partnersBalance.add(partnerFee);
        }

        _feesClaimed[_msgSender()] = _feesClaimed[_msgSender()].add(amount);
    }

    function commission(uint256 amount) public view override returns (uint256) {
        uint256 rate = _rateOverride[_msgSender()].isValue
            ? _rateOverride[_msgSender()].value
            : _rate;

        return _partition(rate, amount);
    }

    function getFees(address account) external view override returns (uint256) {
        return _fees[account] - _feesClaimed[account];
    }

    receive() external payable {}

    function _createCollection(
        address implementation,
        string memory name,
        string memory symbol,
        address affiliate
    ) private returns (address) {
        address deployed = ClonesUpgradeable.clone(implementation);
        IBaseCollection dropCollection = IBaseCollection(deployed);
        dropCollection.initialize(
            name,
            symbol,
            _msgSender(),
            _trustedForwarder
        );
        dropCollection.transferOwnership(_msgSender());

        if (affiliate != address(0) && _partners[affiliate].isValue) {
            _referrals[deployed] = affiliate;
        }

        return deployed;
    }

    function _partition(uint256 rate, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return ((rate * amount) / 10000);
    }
}
