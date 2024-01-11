// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";

contract FeeCollector is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    event FeeCollected(
        uint256 indexed badgeId,
        address indexed from,
        uint256 weiAmount
    );
    event Withdrawn(address indexed to, uint256 weiAmount);

    uint256 public totalCollectedFee;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function collect(
        uint256 badgeId,
        address from
    ) 
        public payable 
        onlyRole(MINTER_ROLE) 
    {
        totalCollectedFee = totalCollectedFee.add(msg.value);
        emit FeeCollected(badgeId, from, msg.value);
    }

    function withdraw(address to, uint256 amount) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(getBalance() >= amount, "withdraw: insufficient balance");
        AddressUpgradeable.sendValue(payable(to), amount);
        emit Withdrawn(to, amount);
    }

    function setMinter(address account) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _grantRole(MINTER_ROLE, account);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalCollectedFee()
        public
        view
        returns (uint256)
    {
        return totalCollectedFee;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
