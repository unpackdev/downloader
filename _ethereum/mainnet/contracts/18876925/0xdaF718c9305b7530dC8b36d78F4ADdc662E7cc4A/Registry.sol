// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Allowlist.sol";
import "./Blocklist.sol";
import "./IRegistry.sol";

/**
 * A registry of allowlisted and blocklisted addresses and code hashes. This is intended to
 * be deployed as a shared oracle, and it would be wise to set the `adminAddress` to an entity
 * that's responsible (e.g. a smart contract that lets creators vote on which addresses/code
 * hashes to add/remove, and then calls the related functions on this contract).
 *
 * @author this contract is based of Yuga Labs' regisry contract (https://etherscan.io/address/0x4fC5Da4607934cC80A0C6257B1F36909C58dD622#code)
 */
contract Registry is
AccessControl,
Allowlist,
Blocklist,
IRegistry
{
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // blocklist from 2023-12-27
        super._addBlockedContractAddress(0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e);
        super._addBlockedContractAddress(0xFED24eC7E22f573c2e08AEF55aA6797Ca2b3A051);
        super._addBlockedContractAddress(0xD42638863462d2F21bb7D4275d7637eE5d5541eB);
        super._addBlockedContractAddress(0x08CE97807A81896E85841d74FB7E7B065ab3ef05);
        super._addBlockedContractAddress(0x92de3a1511EF22AbCf3526c302159882a4755B22);
        super._addBlockedContractAddress(0xCd80C916B1194beB48aBF007D0b79a7238436D56);
        super._addBlockedContractAddress(0xb16c1342E617A5B6E4b631EB114483FDB289c0A4);
        super._addBlockedContractAddress(0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d);
        super._addBlockedContractAddress(0x0000000000E655fAe4d56241588680F86E3b2377);
        super._addBlockedContractAddress(0x000000000060C4Ca14CfC4325359062ace33Fe3D);
        super._addBlockedContractAddress(0x00000000005228B791a99a61f36A130d50600106);
        super._addBlockedContractAddress(0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC);
        super._addBlockedContractAddress(0x000000000000Ad05Ccc4F10045630fb830B95127);
        super._addBlockedContractAddress(0x0000000000A39bb272e79075ade125fd351887Ac);
        super._addBlockedContractAddress(0x29469395eAf6f95920E59F858042f0e28D98a20B);
        super._addBlockedContractAddress(0x39da41747a83aeE658334415666f3EF92DD0D541);
        super._addBlockedContractAddress(0xb2ecfE4E4D61f8790bbb9DE2D1259B9e2410CEA5);
        super._addBlockedContractAddress(0xb2ecfE4E4D61f8790bbb9DE2D1259B9e2410CEA5);
        super._addBlockedContractAddress(0x2f18F339620a63e43f0839Eeb18D7de1e1Be4DfB);
        super._addBlockedContractAddress(0x1E0049783F008A0085193E00003D00cd54003c71);

        super._setIsAllowlistDisabled(true);
        super._setIsBlocklistDisabled(false);

    }

    /**
    * @notice Checks against the allowlist and blocklist (depending if either is enabled
    * or disabled) to see if the operator is allowed.
    * @dev This function checks the blocklist before checking the allowlist, causing the
    * blocklist to take precedent over the allowlist. Be aware that if an operator is on
    * the blocklist and allowlist, it will still be blocked.
    * @param operator Address of operator
    * @return Bool whether the operator is allowed on based off the registry
    */
    function isAllowedOperator(
        address operator
    )
    external
    view
    virtual
    returns (bool)
    {
        if (isBlocklistDisabled == false) {
            bool blocked = _isBlocked(operator);

            if (blocked) {
                return false;
            }
        }

        if (isAllowlistDisabled == false) {
            bool allowed = _isAllowed(operator);

            return allowed;
        }

        return true;
    }

    /**
    * @notice Global killswitch for the allowlist
    * @param disabled Enables or disables the allowlist
    */
    function setIsAllowlistDisabled(
        bool disabled
    )
    external
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._setIsAllowlistDisabled(disabled);
    }

    /**
    * @notice Global killswitch for the blocklist
    * @param disabled Enables or disables the blocklist
    */
    function setIsBlocklistDisabled(
        bool disabled
    )
    external
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._setIsBlocklistDisabled(disabled);
    }

    /**
    * @notice Checks if the operator is on the blocklist
    * @param operator Address of operator
    * @return Bool whether operator is blocked
    */
    function isBlocked(address operator)
    external
    view
    override(IRegistry, Blocklist)
    returns (bool)
    {
        return _isBlocked(operator);
    }

    /**
    * @notice Checks if the operator is on the allowlist
    * @param operator Address of operator
    * @return Bool whether operator is allowed
    */
    function isAllowed(address operator)
    external
    view
    override(IRegistry, Allowlist)
    returns (bool)
    {
        return _isAllowed(operator);
    }

    /**
    * @notice Adds a contract address to the allowlist
    * @param contractAddress Address of allowed operator
    */
    function addAllowedContractAddress(
        address contractAddress
    )
    external
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._addAllowedContractAddress(contractAddress);
    }

    /**
    * @notice Removes a contract address from the allowlist
    * @param contractAddress Address of allowed operator
    */
    function removeAllowedContractAddress(
        address contractAddress
    )
    external
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._removeAllowedContractAddress(contractAddress);
    }

    /**
    * @notice Adds a codehash to the allowlist
    * @param codeHash Code hash of allowed contract
    */
    function addAllowedCodeHash(
        bytes32 codeHash
    )
    external
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._addAllowedCodeHash(codeHash);
    }

    /**
    * @notice Removes a codehash from the allowlist
    * @param codeHash Code hash of allowed contract
    */
    function removeAllowedCodeHash(
        bytes32 codeHash
    )
    external
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._removeAllowedCodeHash(codeHash);
    }

    /**
    * @notice Adds a contract address to the blocklist
    * @param contractAddress Address of blocked operator
    */
    function addBlockedContractAddress(
        address contractAddress
    )
    external
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._addBlockedContractAddress(contractAddress);
    }

    /**
    * @notice Removes a contract address from the blocklist
    * @param contractAddress Address of blocked operator
    */
    function removeBlockedContractAddress(
        address contractAddress
    )
    external
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._removeBlockedContractAddress(contractAddress);
    }

    /**
    * @notice Adds a codehash to the blocklist
    * @param codeHash Code hash of blocked contract
    */
    function addBlockedCodeHash(
        bytes32 codeHash
    )
    external
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._addBlockedCodeHash(codeHash);
    }

    /**
    * @notice Removes a codehash from the blocklist
    * @param codeHash Code hash of blocked contract
    */
    function removeBlockedCodeHash(
        bytes32 codeHash
    )
    external
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._removeBlockedCodeHash(codeHash);
    }
}