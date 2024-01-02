// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import "./UUPSUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import {AccessControlDefaultAdminRulesUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import "./ITransferRestrictor.sol";
import "./ERC7281Min.sol";

/// @notice stablecoin
/// @author Dinari (https://github.com/dinaricrypto/usdplus-contracts/blob/main/src/UsdPlus.sol)
contract UsdPlus is UUPSUpgradeable, ERC20PermitUpgradeable, ERC7281Min, AccessControlDefaultAdminRulesUpgradeable {
    /// ------------------ Types ------------------

    event TreasurySet(address indexed treasury);
    event TransferRestrictorSet(ITransferRestrictor indexed transferRestrictor);

    /// ------------------ Storage ------------------

    struct UsdPlusStorage {
        // treasury for digital assets backing USD+
        address _treasury;
        // transfer restrictor
        ITransferRestrictor _transferRestrictor;
    }

    // keccak256(abi.encode(uint256(keccak256("dinaricrypto.storage.UsdPlus")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant USDPLUS_STORAGE_LOCATION =
        0x531780929781d75f94b208ae2c2a4530451c739f715a1a03bbbb934f354cbb00;

    function _getUsdPlusStorage() private pure returns (UsdPlusStorage storage $) {
        assembly {
            $.slot := USDPLUS_STORAGE_LOCATION
        }
    }

    /// ------------------ Initialization ------------------

    function initialize(address initialTreasury, ITransferRestrictor initialTransferRestrictor, address initialOwner)
        public
        initializer
    {
        __ERC20_init("USD+", "USD+");
        __ERC20Permit_init("USD+");
        __AccessControlDefaultAdminRules_init_unchained(0, initialOwner);

        UsdPlusStorage storage $ = _getUsdPlusStorage();
        $._treasury = initialTreasury;
        $._transferRestrictor = initialTransferRestrictor;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// ------------------ Getters ------------------

    /// @notice treasury for digital assets backing USD+
    function treasury() public view returns (address) {
        UsdPlusStorage storage $ = _getUsdPlusStorage();
        return $._treasury;
    }

    /// @notice transfer restrictor
    function transferRestrictor() public view returns (ITransferRestrictor) {
        UsdPlusStorage storage $ = _getUsdPlusStorage();
        return $._transferRestrictor;
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function checkTransferRestricted(address from, address to) public view {
        UsdPlusStorage storage $ = _getUsdPlusStorage();
        ITransferRestrictor _transferRestrictor = $._transferRestrictor;
        if (address(_transferRestrictor) != address(0)) {
            _transferRestrictor.requireNotRestricted(from, to);
        }
    }

    function isBlacklisted(address account) external view returns (bool) {
        UsdPlusStorage storage $ = _getUsdPlusStorage();
        ITransferRestrictor _transferRestrictor = $._transferRestrictor;
        if (address(_transferRestrictor) != address(0)) {
            return _transferRestrictor.isBlacklisted(account);
        }
        return false;
    }

    // ------------------ Admin ------------------

    /// @notice set treasury address
    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        UsdPlusStorage storage $ = _getUsdPlusStorage();
        $._treasury = newTreasury;
        emit TreasurySet(newTreasury);
    }

    /// @notice set transfer restrictor
    function setTransferRestrictor(ITransferRestrictor newTransferRestrictor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        UsdPlusStorage storage $ = _getUsdPlusStorage();
        $._transferRestrictor = newTransferRestrictor;
        emit TransferRestrictorSet(newTransferRestrictor);
    }

    function setIssuerLimits(address issuer, uint256 mintingLimit, uint256 burningLimit)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setIssuerLimits(issuer, mintingLimit, burningLimit);
    }

    // ------------------ Minting/Burning (ERC-7281) ------------------

    /// @notice mint USD+ to account
    function mint(address to, uint256 value) external {
        _useMintingLimits(_msgSender(), value);
        _mint(to, value);
    }

    /// @notice burn USD+ from msg.sender
    function burn(address from, uint256 value) external {
        address spender = _msgSender();
        if (from != spender) {
            _spendAllowance(from, spender, value);
        }
        _useBurningLimits(spender, value);
        _burn(from, value);
    }

    // ------------------ Transfer Restriction ------------------

    function _update(address from, address to, uint256 value) internal virtual override {
        checkTransferRestricted(from, to);

        super._update(from, to, value);
    }
}
