// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Version, toVersion, toVersionPart} from "IVersionType.sol";
import {IVersionable} from "IVersionable.sol";
import {Versionable} from "Versionable.sol";
import {VersionedOwnable} from "VersionedOwnable.sol";

import {ChainId} from "IBaseTypes.sol";

import {ChainRegistryV01} from "ChainRegistryV01.sol";
import {IInstanceServiceFacade, IComponent} from "IInstanceServiceFacade.sol";
import {NftId} from "IChainNft.sol";

contract ChainRegistryV02 is
    ChainRegistryV01
{

    // IMPORTANT 1. version needed for upgradable versions
    // _activate is using this to check if this is a new version
    // and if this version is higher than the last activated version
    function version()
        public 
        virtual override
        pure
        returns(Version)
    {
        return toVersion(
            toVersionPart(1),
            toVersionPart(1),
            toVersionPart(0));
    }

    // IMPORTANT 2. activate implementation needed
    // is used by proxy admin in its upgrade function
    function activate(address implementation, address activatedBy)
        external 
        virtual override(IVersionable, VersionedOwnable)
    { 
        // keep track of version history
        // do some upgrade checks
        _activate(implementation, activatedBy);

        // upgrade version
        _version = version();
    }


    function extendBundleLifetime(NftId id, uint256 lifetimeExtension)
        external
        virtual override
    {
        // check id exists and refers to bundle
        NftInfo memory info = _info[id];
        require(info.objectType == BUNDLE, "ERROR:CRG-400:NOT_BUNDLE");

        // check that call is made from associated riskpool
        (
            bytes32 instanceId,
            uint256 riskpoolId,
            uint256 bundleId,
            address token,
            string memory displayName,
            uint256 expiryAt
        ) = _decodeBundleData(info.data);

        IInstanceServiceFacade instanceService = getInstanceServiceFacade(instanceId);
        IComponent component = instanceService.getComponent(riskpoolId);
        require(msg.sender == address(component), "ERROR:CRG-401:CALLER_NOT_RISKPOOL");

        uint256 newExpiryAt = expiryAt + lifetimeExtension;
        bytes memory newData = _encodeBundleData(
            instanceId, 
            riskpoolId, 
            bundleId, 
            token, 
            displayName, 
            newExpiryAt);

        _updateObjectData(id, newData);
    }


    function _updateObjectData(NftId id, bytes memory newData)
        internal
        virtual
    {
        NftInfo storage info = _info[id];
        info.data = newData;
        info.updatedIn = blockNumber();

        emit LogChainRegistryObjectDataUpdated(id, msg.sender);
    }
}