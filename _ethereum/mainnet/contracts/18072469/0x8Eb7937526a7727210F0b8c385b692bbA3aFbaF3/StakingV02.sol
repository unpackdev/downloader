// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Version, toVersion, toVersionPart} from "IVersionType.sol";
import {IVersionable} from "IVersionable.sol";
import {Versionable} from "Versionable.sol";
import {VersionedOwnable} from "VersionedOwnable.sol";

import {NftId} from "IChainNft.sol";

import {StakingV01} from "StakingV01.sol";

contract StakingV02 is
    StakingV01
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
            toVersionPart(0),
            toVersionPart(1));
    }


    // IMPORTANT 2. activate implementation needed
    // is used by proxy admin in its upgrade function
    function activate(address implementation, address activatedBy)
        external 
        virtual override (IVersionable, VersionedOwnable)
    { 
        // keep track of version history
        // do some upgrade checks
        _activate(implementation, activatedBy);

        // upgrade version
        _version = version();
    }


    function claimRewards(NftId stakeId)
        external
        virtual override
        onlyStakeOwner(stakeId)
    {
        address user = msg.sender;
        StakeInfo storage info = _info[stakeId];

        _updateRewards(info);
        _claimRewards(user, info);
    }
}
