// SPDX-License-Identifier: Unlicensed
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, hagen@token-forge.io

pragma solidity >=0.8.0 <0.9.0;

import "./AccessControlEnumerable.sol";
import "./Counters.sol";
import "./Context.sol";

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Whitelist.sol";
import "./Blacklist.sol";

contract OPUS is Context, AccessControlEnumerable, ERC20Burnable, WhiteList, BlackList {
    struct ContractParameters {
        string isin;
        string issuerName;
        string denomination;
        string recordKeeping;
        bool mixedRecordKeeping;
        string terms;
        string transferRestrictions;
        string thirdPartyRights;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    bytes32 public constant PROP_ISIN = keccak256("ISIN");
    bytes32 public constant PROP_ISSUER_NAME = keccak256("ISSUER_NAME");
    bytes32 public constant PROP_TERMS = keccak256("TERMS");
    bytes32 public constant PROP_DENOMINATION = keccak256("DENOMINATION");
    bytes32 public constant PROP_RECORD_KEEPING = keccak256("RECORD_KEEPING");
    bytes32 public constant PROP_MIXED_RECORD_KEEPING = keccak256("MIXED_RECORD_KEEPING");
    bytes32 public constant PROP_TRANSFER_RESTRICTIONS = keccak256("TRANSFER_RESTRICTIONS");
    bytes32 public constant PROP_THIRD_PARTY_RIGHTS = keccak256("THIRD_PARTY_RIGHTS");

    event PropertyChanged(bytes32 propertyName, bytes oldValue, bytes newValue);

    mapping(bytes32 => string) private _properties;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNANCE_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function setParameters(ContractParameters memory params) public onlyRole(GOVERNANCE_ROLE) {
        _properties[PROP_ISIN] = params.isin;
        _properties[PROP_ISSUER_NAME] = params.issuerName;
        _properties[PROP_TERMS] = params.terms;
        _properties[PROP_DENOMINATION] = params.denomination;
        _properties[PROP_RECORD_KEEPING] = params.recordKeeping;
        _properties[PROP_MIXED_RECORD_KEEPING] = params.mixedRecordKeeping ? "1" : "0";
        _properties[PROP_THIRD_PARTY_RIGHTS] = params.thirdPartyRights;
        _properties[PROP_TRANSFER_RESTRICTIONS] = params.transferRestrictions;
    }

    /// ISIN

    function getProperty(bytes32 key) public view returns (string memory) {
        return _properties[key];
    }

    function setProperty(bytes32 key, string memory val_) external onlyRole(GOVERNANCE_ROLE) {
        string memory oldValue = _properties[key];

        if (keccak256(bytes(oldValue)) == keccak256(bytes(val_))) {
            revert("OPUS: new value is equal to old value");
        }

        _properties[key] = val_;

        emit PropertyChanged(key, bytes(oldValue), bytes(val_));
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "OPUS: must have minter role to mint");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        if (isBlacklisted(from)) {
            revert(
                string(abi.encodePacked("OPUS: account ", Strings.toHexString(uint160(from), 20), " is blacklisted"))
            );
        }

        if (isBlacklisted(to)) {
            revert(
                string(abi.encodePacked("OPUS: account ", Strings.toHexString(uint160(to), 20), " is blacklisted"))
            );
        }

        if (!isWhitelisted(to)) {
            revert(
                string(
                    abi.encodePacked("OPUS: account ", Strings.toHexString(uint160(to), 20), " is not whitelisted")
                )
            );
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}
