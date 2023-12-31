// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {IBaseTypes, ChainId, Blocknumber} from "IBaseTypes.sol";
import {Version} from "IVersionType.sol";
import {IVersionable} from "IVersionable.sol";

import {IStaking} from "IStaking.sol";

import {IChainNft, NftId} from "IChainNft.sol";
import {IInstanceServiceFacade} from "IInstanceServiceFacade.sol";

type ObjectType is uint8;

using {
    eqObjectType as ==,
    neObjectType as !=
}
    for ObjectType global;

function eqObjectType(ObjectType a, ObjectType b) pure returns(bool isSame) { return ObjectType.unwrap(a) == ObjectType.unwrap(b); }
function neObjectType(ObjectType a, ObjectType b) pure returns(bool isDifferent) { return ObjectType.unwrap(a) != ObjectType.unwrap(b); }


interface IChainRegistry is 
    IBaseTypes,
    IVersionable
{

    enum ObjectState {
        Undefined,
        Proposed,
        Approved,
        Suspended,
        Archived,
        Burned
    }


    struct NftInfo {
        NftId id;
        ChainId chain;
        ObjectType objectType;
        ObjectState state;
        string uri;
        bytes data;
        Blocknumber mintedIn;
        Blocknumber updatedIn;
        Version version;
    }


    event LogChainRegistryObjectRegistered(NftId id, ChainId chain, ObjectType objectType, ObjectState state, address to);
    event LogChainRegistryObjectStateSet(NftId id, ObjectState stateNew, ObjectState stateOld, address setBy);
    event LogChainRegistryObjectDataUpdated(NftId id, address updatedBy);

    //--- state changing functions ------------------//

    function registerChain(ChainId chain, string memory uri) external returns(NftId id);
    function registerRegistry(ChainId chain, address registry, string memory uri) external returns(NftId id);
    function registerToken(ChainId chain,address token, string memory uri) external returns(NftId id);       


    function registerStake(
        NftId target, 
        address staker
    )
        external
        returns(NftId id);


    function registerInstance(
        address instanceRegistry,
        string memory displayName,
        string memory uri
    )
        external
        returns(NftId id);


    function registerComponent(
        bytes32 instanceId,
        uint256 componentId,
        string memory uri
    )
        external
        returns(NftId id);


    function registerBundle(
        bytes32 instanceId,
        uint256 riskpoolId,
        uint256 bundleId,
        string memory displayName,
        uint256 expiryAt
    )
        external
        returns(NftId id);


    function extendBundleLifetime(NftId id, uint256 lifetimeExtension) external;


    function setObjectState(NftId id, ObjectState state) external;


    //--- view and pure functions ------------------//

    function getNft() external view returns(IChainNft);
    function getStaking() external view returns(IStaking);

    function exists(NftId id) external view returns(bool);

    // generic accessors
    function objects(ChainId chain, ObjectType t) external view returns(uint256 numberOfObjects);
    function getNftId(ChainId chain, ObjectType t, uint256 idx) external view returns(NftId id);
    function getNftInfo(NftId id) external view returns(NftInfo memory);
    function ownerOf(NftId id) external view returns(address nftOwner);

    // chain specific accessors
    function chains() external view returns(uint256 numberOfChains);
    function getChainId(uint256 idx) external view returns(ChainId chain);
    function getChainNftId(ChainId chain) external view returns(NftId id);

    // type specific accessors
    function getRegistryNftId(ChainId chain) external view returns(NftId id);
    function getTokenNftId(ChainId chain, address token) external view returns(NftId id);
    function getInstanceNftId(bytes32 instanceId) external view returns(NftId id);
    function getComponentNftId(bytes32 instanceId, uint256 componentId) external view returns(NftId id);
    function getBundleNftId(bytes32 instanceId, uint256 componentId) external view returns(NftId id);


    function decodeRegistryData(NftId id)
        external
        view
        returns(address registry);


    function decodeTokenData(NftId id)
        external
        view
        returns(address token);


    function decodeInstanceData(NftId id)
        external
        view
        returns(
            bytes32 instanceId,
            address registry,
            string memory displayName);


    function decodeComponentData(NftId id)
        external
        view
        returns(
            bytes32 instanceId,
            uint256 componentId,
            address token);


    function decodeBundleData(NftId id)
        external
        view
        returns(
            bytes32 instanceId,
            uint256 riskpoolId,
            uint256 bundleId,
            address token,
            string memory displayName,
            uint256 expiryAt);


    function decodeStakeData(NftId id)
        external
        view
        returns(
            NftId target,
            ObjectType targetType);


    function toChain(uint256 chainId) 
        external
        pure
        returns(ChainId);

    // only same chain: utility to get reference to instance service for specified instance id
    function getInstanceServiceFacade(bytes32 instanceId) 
        external
        view
        returns(IInstanceServiceFacade instanceService);

    // only same chain:  utilitiv function to probe an instance given its registry address
    function probeInstance(address registry)
        external 
        view 
        returns(
            bool isContract, 
            uint256 contractSize, 
            ChainId chain,
            bytes32 istanceId, 
            bool isValidId, 
            IInstanceServiceFacade instanceService);

    function implementsIChainRegistry() external pure returns(bool);
}
