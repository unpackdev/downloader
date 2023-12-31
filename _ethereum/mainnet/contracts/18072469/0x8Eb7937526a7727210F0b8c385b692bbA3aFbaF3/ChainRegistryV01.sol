// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {StringsUpgradeable} from "StringsUpgradeable.sol";

import {ChainId, toChainId} from "IBaseTypes.sol";
import {Version, toVersion, toVersionPart, zeroVersion} from "IVersionType.sol";
import {IVersionable} from "IVersionable.sol";
import {Versionable} from "Versionable.sol";
import {VersionedOwnable} from "VersionedOwnable.sol";

import {IInstanceRegistryFacade} from "IInstanceRegistryFacade.sol";
import {IInstanceServiceFacade} from "IInstanceServiceFacade.sol";

import {IChainRegistry, IStaking, ObjectType} from "IChainRegistry.sol";
import {IChainNft, NftId, toNftId} from "IChainNft.sol";

// registers dip relevant objects for this chain
contract ChainRegistryV01 is
    VersionedOwnable,
    IChainRegistry
{
    using StringsUpgradeable for uint;
    using StringsUpgradeable for address;

    string public constant BASE_DID = "did:nft:eip155:";
    
    // responsibility of dip foundation
    ObjectType public constant UNDEFINED = ObjectType.wrap(0); // detection of uninitialized variables
    ObjectType public constant PROTOCOL = ObjectType.wrap(1); // dip ecosystem overall
    ObjectType public constant CHAIN = ObjectType.wrap(2); // dip ecosystem reach: a registry per chain
    ObjectType public constant REGISTRY = ObjectType.wrap(3); // dip ecosystem reach: a registry per chain
    ObjectType public constant TOKEN = ObjectType.wrap(4); // dip ecosystem token whitelisting (premiums, risk capital)

    // involvement of dip holders
    ObjectType public constant STAKE = ObjectType.wrap(10);

    // responsibility of instance operators
    ObjectType public constant INSTANCE = ObjectType.wrap(20);
    ObjectType public constant PRODUCT = ObjectType.wrap(21);
    ObjectType public constant ORACLE = ObjectType.wrap(22);
    ObjectType public constant RISKPOOL = ObjectType.wrap(23);

    // responsibility of product owners
    ObjectType public constant POLICY = ObjectType.wrap(30);

    // responsibility of riskpool keepers
    ObjectType public constant BUNDLE = ObjectType.wrap(40);

    // keep trak of nft meta data
    mapping(NftId id => NftInfo info) internal _info;
    mapping(ObjectType t => bool isSupported) internal _typeSupported; // which nft types are currently supported for minting

    // keep track of chains and registries
    mapping(ChainId chain => NftId id) internal _chain;
    mapping(ChainId chain => NftId id) internal _registry;
    ChainId [] internal _chainIds;

    // keep track of objects per chain and type
    mapping(ChainId chain => mapping(ObjectType t => NftId [] ids)) internal _object; // which erc20 on which chains are currently supported for minting

    // keep track of objects with a contract address (tokens, instances)
    mapping(ChainId chain => mapping(address implementation => NftId id)) internal _contractObject; // which erc20 on which chains are currently supported for minting

    // keep track of instances, comonents and bundles
    mapping(bytes32 instanceId => NftId id) internal _instance; // which erc20 on which chains are currently supported for minting
    mapping(bytes32 instanceId => mapping(uint256 componentId => NftId id)) internal _component; // which erc20 on which chains are currently supported for minting
    mapping(bytes32 instanceId => mapping(uint256 bundleId => NftId id)) internal _bundle; // which erc20 on which chains are currently supported for minting

    // registy internal data
    IChainNft internal _nft;
    ChainId internal _chainId;
    IStaking internal _staking;
    Version internal _version;


    modifier onlyExisting(NftId id) {
        require(exists(id), "ERROR:CRG-001:TOKEN_ID_INVALID");
        _;
    }


    modifier onlyRegisteredToken(ChainId chain, address token) {
        NftId id = _contractObject[chain][token];
        require(NftId.unwrap(id) > 0, "ERROR:CRG-002:TOKEN_NOT_REGISTERED");
        require(_info[id].objectType == TOKEN, "ERROR:CRG-003:ADDRESS_NOT_TOKEN");
        _;
    }


    modifier onlyRegisteredInstance(bytes32 instanceId) {
        require(NftId.unwrap(_instance[instanceId]) > 0, "ERROR:CRG-005:INSTANCE_NOT_REGISTERED");
        _;
    }


    modifier onlyRegisteredComponent(bytes32 instanceId, uint256 componentId) {
        require(NftId.unwrap(_component[instanceId][componentId]) > 0, "ERROR:CRG-006:COMPONENT_NOT_REGISTERED");
        _;
    }


    modifier onlyActiveRiskpool(bytes32 instanceId, uint256 riskpoolId) {
        require(NftId.unwrap(_component[instanceId][riskpoolId]) > 0, "ERROR:CRG-010:RISKPOOL_NOT_REGISTERED");
        IInstanceServiceFacade instanceService = getInstanceServiceFacade(instanceId);
        IInstanceServiceFacade.ComponentType cType = instanceService.getComponentType(riskpoolId);
        require(cType == IInstanceServiceFacade.ComponentType.Riskpool, "ERROR:CRG-011:COMPONENT_NOT_RISKPOOL");
        IInstanceServiceFacade.ComponentState state = instanceService.getComponentState(riskpoolId);
        require(state == IInstanceServiceFacade.ComponentState.Active, "ERROR:CRG-012:RISKPOOL_NOT_ACTIVE");
        _;
    }


    modifier onlySameChain(bytes32 instanceId) {
        NftId id = _instance[instanceId];
        require(NftId.unwrap(id) > 0, "ERROR:CRG-020:INSTANCE_NOT_REGISTERED");
        require(block.chainid == toInt(_info[id].chain), "ERROR:CRG-021:DIFFERENT_CHAIN_NOT_SUPPORTED");
        _;
    }


    modifier onlyStaking() {
        require(msg.sender == address(_staking), "ERROR:CRG-030:SENDER_NOT_STAKING");
        _;
    }


    // IMPORTANT 1. version needed for upgradable versions
    // _activate is using this to check if this is a new version
    // and if this version is higher than the last activated version
    function version()
        public 
        virtual override(IVersionable, Versionable) 
        pure 
        returns(Version)
    {
        return toVersion(
            toVersionPart(1),
            toVersionPart(0),
            toVersionPart(0));
    }

    // IMPORTANT 2. activate implementation needed
    // is used by proxy admin in its upgrade function
    function activateAndSetOwner(
        address implementation,
        address newOwner,
        address activatedBy
    )
        external
        virtual override
        initializer
    {
        // ensure proper version history
        _activate(implementation, activatedBy);

        // initialize open zeppelin contracts
        __Ownable_init();

        // set main internal variables
        _version = version();
        _chainId = toChainId(block.chainid);

        // set types supported by this version
        _typeSupported[PROTOCOL] = true;
        _typeSupported[CHAIN] = true;
        _typeSupported[REGISTRY] = true;
        _typeSupported[TOKEN] = true;
        _typeSupported[INSTANCE] = true;
        _typeSupported[RISKPOOL] = true;
        _typeSupported[BUNDLE] = true;
        _typeSupported[STAKE] = true;

        transferOwnership(newOwner);
    }


    function setNftContract(
        address nft,
        address newOwner
    )
        external
        virtual
        onlyOwner
    {
        require(newOwner != address(0), "ERROR:CRG-040:NEW_OWNER_ZERO");

        require(address(_nft) == address(0), "ERROR:CRG-041:NFT_ALREADY_SET");
        require(nft != address(0), "ERROR:CRG-042:NFT_ADDRESS_ZERO");

        IChainNft nftContract = IChainNft(nft);
        require(nftContract.implementsIChainNft(), "ERROR:CRG-043:NFT_NOT_ICHAINNFT");

        _nft = nftContract;

        // register/mint dip protocol on mainnet and goerli
        if(toInt(_chainId) == 1 || toInt(_chainId) == 5) {
            _registerProtocol(newOwner);
        }
        // register current chain and this registry
        _registerChain(_chainId, newOwner, "");
        _registerRegistry(_chainId, address(this), newOwner, "");
    }


    function setStaking(address stakingAddress)
        external
        virtual
        onlyOwner
    {
        require(address(_staking) == address(0), "ERROR:CRG-050:STAKING_ALREADY_SET");
        require(stakingAddress != address(0), "ERROR:CRG-051:STAKING_ADDRESS_ZERO");
        IStaking stakingContract = IStaking(stakingAddress);

        require(stakingContract.implementsIStaking(), "ERROR:CRG-052:STAKING_NOT_ISTAKING");
        require(stakingContract.version() > zeroVersion(), "ERROR:CRG-053:STAKING_VERSION_ZERO");

        _staking = stakingContract;
    }


    function registerChain(ChainId chain, string memory uri)
        external
        virtual override
        onlyOwner
        returns(NftId id)
    {
        return _registerChain(chain, owner(), uri);
    }


    function registerRegistry(ChainId chain, address registry, string memory uri)
        external
        virtual override
        onlyOwner
        returns(NftId id)
    {
        return _registerRegistry(chain, registry, owner(), uri);
    }


    function registerToken(ChainId chain, address token, string memory uri)
        external
        virtual override
        onlyOwner
        returns(NftId id)
    {
        (bytes memory data) = _getTokenData(chain, token);

        // mint token for the new erc20 token
        id = _safeMintObject(
            owner(),
            chain,
            TOKEN,
            ObjectState.Approved,
            uri,
            data);
    }


    function registerInstance(
        address instanceRegistry,
        string memory displayName,
        string memory uri
    )
        external 
        virtual override
        onlyOwner
        returns(NftId id)
    {
        (
            ChainId chain,
            bytes memory data
        ) = _getInstanceData(instanceRegistry, displayName);

        // mint token for the new erc20 token
        id = _safeMintObject(
            owner(),
            chain,
            INSTANCE,
            ObjectState.Approved,
            uri,
            data);
    }


    function registerComponent(
        bytes32 instanceId, 
        uint256 componentId,
        string memory uri
    )
        external 
        virtual override
        onlyRegisteredInstance(instanceId)
        onlySameChain(instanceId)
        returns(NftId id)
    {
        (
            ChainId chain,
            ObjectType t,
            bytes memory data
        ) = _getComponentData(instanceId, componentId);

        // mint token for the new erc20 token
        id = _safeMintObject(
            owner(),
            chain,
            t,
            ObjectState.Approved,
            uri,
            data);
    }


    function registerBundle(
        bytes32 instanceId, 
        uint256 riskpoolId, 
        uint256 bundleId, 
        string memory displayName, 
        uint256 expiryAt
    )
        external
        virtual override
        onlyActiveRiskpool(instanceId, riskpoolId)
        onlySameChain(instanceId)
        returns(NftId id)
    {
        (ChainId chain, bytes memory data) 
        = _getBundleData(instanceId, riskpoolId, bundleId, displayName, expiryAt);

        // mint token for the new erc20 token
        id = _safeMintObject(
            owner(),
            chain,
            BUNDLE,
            ObjectState.Approved,
            "", // uri
            data);
    }


    function extendBundleLifetime(NftId, uint256)
        external
        virtual override
    { 
        require(false, "ERROR:CRG-054:NOT_IMPLEMENTED");
    }


    function registerStake(
        NftId target, 
        address staker
    )
        external
        virtual override
        onlyStaking()
        returns(NftId id)
    {
        require(staker != address(0), "ERROR:CRG-090:STAKER_WITH_ZERO_ADDRESS");
        (bytes memory data) = _getStakeData(
            target,
            _info[target].objectType);

        // mint new stake nft
        id = _safeMintObject(
            staker,
            _chainId,
            STAKE,
            ObjectState.Approved,
            "", // uri
            data);
    }


    function setObjectState(NftId id, ObjectState stateNew)
        external
        virtual override
        onlyOwner
    {
        _setObjectState(id, stateNew);
    }


    function probeInstance(
        address registryAddress
    )
        public
        virtual override
        view 
        returns(
            bool isContract, 
            uint256 contractSize, 
            ChainId chain,
            bytes32 instanceId,
            bool isValidId,
            IInstanceServiceFacade instanceService
        )
    {
        contractSize = _getContractSize(registryAddress);
        isContract = (contractSize > 0);

        isValidId = false;
        instanceId = bytes32(0);
        instanceService = IInstanceServiceFacade(address(0));

        if(isContract) {
            IInstanceRegistryFacade registry = IInstanceRegistryFacade(registryAddress);

            try registry.getContract("InstanceService") returns(address instanceServiceAddress) {
                instanceService = IInstanceServiceFacade(instanceServiceAddress);
                chain = toChainId(instanceService.getChainId());
                instanceId = instanceService.getInstanceId();
                isValidId = (instanceId == keccak256(abi.encodePacked(block.chainid, registry)));
            }
            // solhint-disable-next-line no-empty-blocks
            catch { }
        } 
    }


    function getNft()
        external
        virtual override
        view
        returns(IChainNft nft)
    {
        return _nft;
    }


    function getStaking()
        external
        virtual override
        view
        returns(IStaking staking)
    {
        return _staking;
    }


    function exists(NftId id) public virtual override view returns(bool) {
        return NftId.unwrap(_info[id].id) > 0;
    }


    function chains() external virtual override view returns(uint256 numberOfChains) {
        return _chainIds.length;
    }

    function getChainId(uint256 idx) external virtual override view returns(ChainId chain) {
        require(idx < _chainIds.length, "ERROR:CRG-100:INDEX_TOO_LARGE");
        return _chainIds[idx];
    }


    function objects(ChainId chain, ObjectType t) public view returns(uint256 numberOfObjects) {
        return _object[chain][t].length;
    }


    function getNftId(ChainId chain, ObjectType t, uint256 idx) external view returns(NftId id) {
        require(idx < _object[chain][t].length, "ERROR:CRG-110:INDEX_TOO_LARGE");
        return _object[chain][t][idx];
    }


    function getNftInfo(NftId id) external virtual override view returns(NftInfo memory) {
        require(exists(id), "ERROR:CRG-120:NFT_ID_INVALID");
        return _info[id];
    }


    function ownerOf(NftId id) external virtual override view returns(address nftOwner) {
        return _nft.ownerOf(NftId.unwrap(id));
    }



    function getChainNftId(ChainId chain) external virtual override view returns(NftId id) {
        id = _chain[chain];
        require(exists(id), "ERROR:CRG-130:CHAIN_NOT_REGISTERED");
    }


    function getRegistryNftId(ChainId chain) external virtual override view returns(NftId id) {
        id = _registry[chain];
        require(exists(id), "ERROR:CRG-131:REGISTRY_NOT_REGISTERED");
    }


    function getTokenNftId(
        ChainId chain,
        address token
    )
        external
        virtual override
        view
        returns(NftId id)
    {
        id = _contractObject[chain][token];
        require(exists(id), "ERROR:CRG-133:TOKEN_NOT_REGISTERED");
        require(_info[id].objectType == TOKEN, "ERROR:CRG-134:OBJECT_NOT_TOKEN");
    }


    function getInstanceNftId(bytes32 instanceId)
        external
        virtual override
        view
        returns(NftId id)
    {
        id = _instance[instanceId];
        require(exists(id), "ERROR:CRG-135:INSTANCE_NOT_REGISTERED");
    }


    function getComponentNftId(bytes32 instanceId, uint256 componentId)
        external
        virtual override
        view
        returns(NftId id)
    {
        id = _component[instanceId][componentId];
        require(exists(id), "ERROR:CRG-136:COMPONENT_NOT_REGISTERED");
    }


    function getBundleNftId(bytes32 instanceId, uint256 bundleId)
        external
        virtual override
        view
        returns(NftId id)
    {
        id = _bundle[instanceId][bundleId];
        require(exists(id), "ERROR:CRG-137:BUNDLE_NOT_REGISTERED");
    }


    function decodeRegistryData(NftId id)
        public
        virtual override
        view
        returns(address registry)
    {
        (registry) = _decodeRegistryData(_info[id].data);
    }


    function decodeTokenData(NftId id)
        public
        virtual override
        view
        returns(address token)
    {
        (token) = _decodeTokenData(_info[id].data);
    }


    function decodeInstanceData(NftId id)
        public
        virtual override
        view
        returns(
            bytes32 instanceId,
            address registry,
            string memory displayName
        )
    {
        return _decodeInstanceData(_info[id].data);
    }


    function decodeComponentData(NftId id)
        external
        virtual override
        view
        returns(
            bytes32 instanceId,
            uint256 componentId,
            address token
        )
    {
        return _decodeComponentData(_info[id].data);
    }


    function decodeBundleData(NftId id)
        external
        virtual override
        view
        returns(
            bytes32 instanceId,
            uint256 riskpoolId,
            uint256 bundleId,
            address token,
            string memory displayName,
            uint256 expiryAt
        )
    {
        return _decodeBundleData(_info[id].data);
    }


    function decodeStakeData(NftId id)
        external
        view
        virtual override
        returns(
            NftId target,
            ObjectType targetType
        )
    {
        return _decodeStakeData(_info[id].data);
    }


    function tokenDID(uint256 tokenId) 
        public 
        view 
        virtual 
        returns(string memory)
    {
        NftId id = toNftId(tokenId);
        require(exists(id), "ERROR:CRG-140:TOKEN_ID_INVALID");

        NftInfo memory info = _info[id];
        NftId registryId = _object[info.chain][REGISTRY][0];
        address registryAt = abi.decode(
            _info[registryId].data, 
            (address));

        return string(
            abi.encodePacked(
                BASE_DID, 
                toString(info.chain),
                "_erc721:",
                toString(registryAt),
                "_",
                toString(tokenId)));
    }

    function implementsIChainRegistry() external override pure returns(bool) {
        return true;
    }

    function toChain(uint256 chainId) public virtual override pure returns(ChainId) {
        return toChainId(chainId);
    }

    function toObjectType(uint256 t) public pure returns(ObjectType) { 
        return ObjectType.wrap(uint8(t));
    }

    function toString(uint256 i) public pure returns(string memory) {
        return StringsUpgradeable.toString(i);
    }

    function toString(ChainId chain) public pure returns(string memory) {
        return StringsUpgradeable.toString(uint40(ChainId.unwrap(chain)));
    }

    function toString(address account) public pure returns(string memory) {
        return StringsUpgradeable.toHexString(account);
    }


    function _registerProtocol(address protocolOwner)
        internal
        virtual
        returns(NftId id)
    {
        require(toInt(_chainId) == 1 || toInt(_chainId) == 5, "ERROR:CRG-200:NOT_ON_MAINNET");
        require(objects(_chainId, PROTOCOL) == 0, "ERROR:CRG-201:PROTOCOL_ALREADY_REGISTERED");

        // mint token for the new chain
        id = _safeMintObject(
            protocolOwner,
            _chainId,
            PROTOCOL,
            ObjectState.Approved,
            "", // uri
            ""); // data
        
        // only one protocol in dip ecosystem
        _typeSupported[PROTOCOL] = false;
    }


    function _registerChain(
        ChainId chain,
        address chainOwner,
        string memory uri
    )
        internal
        virtual
        returns(NftId id)
    {
        require(!exists(_chain[chain]), "ERROR:CRG-210:CHAIN_ALREADY_REGISTERED");

        // mint token for the new chain
        id = _safeMintObject(
            chainOwner,
            chain,
            CHAIN,
            ObjectState.Approved,
            uri,
            "");
    }


    function _registerRegistry(
        ChainId chain,
        address registry,
        address registryOwner,
        string memory uri
    )
        internal
        virtual
        returns(NftId id)
    {
        require(exists(_chain[chain]), "ERROR:CRG-220:CHAIN_NOT_SUPPORTED");
        require(objects(chain, REGISTRY) == 0, "ERROR:CRG-221:REGISTRY_ALREADY_REGISTERED");
        require(registry != address(0), "ERROR:CRG-222:REGISTRY_ADDRESS_ZERO");

        (bytes memory data) = _getRegistryData(chain, registry);

        // mint token for the new registry
        id = _safeMintObject(
            registryOwner,
            chain,
            REGISTRY,
            ObjectState.Approved,
            uri,
            data);
    }


    function _setObjectState(NftId id, ObjectState stateNew)
        internal
        virtual
        onlyExisting(id)
    {
        NftInfo storage info = _info[id];
        ObjectState stateOld = info.state;

        info.state = stateNew;
        info.updatedIn = blockNumber();

        emit LogChainRegistryObjectStateSet(id, stateOld, stateNew, msg.sender);
    }


    function _getRegistryData(ChainId chain, address registry)
        internal
        virtual
        view
        returns(bytes memory data)
    {
        require(exists(_chain[chain]), "ERROR:CRG-280:CHAIN_NOT_SUPPORTED");
        require(registry != address(0), "ERROR:CRG-281:REGISTRY_ADDRESS_ZERO");

        data = _encodeRegistryData(registry);
    }


    function _getTokenData(ChainId chain, address token)
        internal
        virtual
        view
        returns(bytes memory data)
    {
        require(exists(_chain[chain]), "ERROR:CRG-290:CHAIN_NOT_SUPPORTED");
        require(!exists(_contractObject[chain][token]), "ERROR:CRG-291:TOKEN_ALREADY_REGISTERED");
        require(token != address(0), "ERROR:CRG-292:TOKEN_ADDRESS_ZERO");

        data = _encodeTokenData(token);
    }


    function _getInstanceData(
        address instanceRegistry,
        string memory displayName
    )
        internal
        virtual
        view
        returns(
            ChainId chain,
            bytes memory data
        )
    {
        require(instanceRegistry != address(0), "ERROR:CRG-300:REGISTRY_ADDRESS_ZERO");

        // check instance via provided registry
        (
            bool isContract,
            , // don't care about contract size
            ChainId chainId,
            bytes32 instanceId,
            bool hasValidId,
            // don't care about instanceservice
        ) = probeInstance(instanceRegistry);

        require(isContract, "ERROR:CRG-301:REGISTRY_NOT_CONTRACT");
        require(hasValidId, "ERROR:CRG-302:INSTANCE_ID_INVALID");
        require(exists(_chain[chainId]), "ERROR:CRG-303:CHAIN_NOT_SUPPORTED");
        require(!exists(_contractObject[chainId][instanceRegistry]), "ERROR:CRG-304:INSTANCE_ALREADY_REGISTERED");

        chain = chainId;
        data = _encodeInstanceData(instanceId, instanceRegistry, displayName);
    }


    function _getComponentData(
        bytes32 instanceId,
        uint256 componentId
    )
        internal
        virtual
        view
        returns(
            ChainId chain,
            ObjectType t,
            bytes memory data
        )
    {
        require(!exists(_component[instanceId][componentId]), "ERROR:CRG-310:COMPONENT_ALREADY_REGISTERED");

        IInstanceServiceFacade instanceService = getInstanceServiceFacade(instanceId);
        IInstanceServiceFacade.ComponentType cType = instanceService.getComponentType(componentId);

        t = _toObjectType(cType);
        chain = toChainId(instanceService.getChainId());
        address token = address(instanceService.getComponentToken(componentId));
        require(exists(_contractObject[chain][token]), "ERROR:CRG-311:COMPONENT_TOKEN_NOT_REGISTERED");

        data = _encodeComponentData(instanceId, componentId, token);
    }


    function _getBundleData(
        bytes32 instanceId,
        uint256 riskpoolId,
        uint256 bundleId,
        string memory displayName,
        uint256 expiryAt
    )
        internal
        virtual
        view
        returns(
            ChainId chain,
            bytes memory data
        )
    {
        require(!exists(_bundle[instanceId][bundleId]), "ERROR:CRG-320:BUNDLE_ALREADY_REGISTERED");

        IInstanceServiceFacade instanceService = getInstanceServiceFacade(instanceId);
        IInstanceServiceFacade.Bundle memory bundle = instanceService.getBundle(bundleId);
        require(bundle.riskpoolId == riskpoolId, "ERROR:CRG-321:BUNDLE_RISKPOOL_MISMATCH");

        address token = address(instanceService.getComponentToken(riskpoolId));

        chain = toChainId(instanceService.getChainId());
        data = _encodeBundleData(instanceId, riskpoolId, bundleId, token, displayName, expiryAt);
    }


    function _getStakeData(NftId target, ObjectType targetType)
        internal
        virtual
        view
        returns(bytes memory data)
    {
        data = _encodeStakeData(target, targetType);
    }


    function _encodeRegistryData(address registry)
        internal
        virtual
        view
        returns(bytes memory data)
    {
        return abi.encode(registry);
    }


    function _decodeRegistryData(bytes memory data)
        internal
        virtual
        view
        returns(address registry)
    {
        return abi.decode(data, (address));
    }


    function _encodeTokenData(address token)
        internal
        virtual
        view
        returns(bytes memory data)
    {
        return abi.encode(token);
    }


    function _decodeTokenData(bytes memory data) 
        internal 
        virtual 
        view 
        returns(address token)
    {
        return abi.decode(data, (address));
    }


    function _encodeInstanceData(
        bytes32 instanceId,
        address registry,
        string memory displayName
    )
        internal
        virtual
        view
        returns(bytes memory data)
    {
        return abi.encode(instanceId, registry, displayName);
    }


    function _decodeInstanceData(bytes memory data) 
        internal
        virtual
        view
        returns(
            bytes32 instanceId,
            address registry,
            string memory displayName
        )
    {
        (instanceId, registry, displayName) 
            = abi.decode(data, (bytes32, address, string));
    }


    function _encodeComponentData(
        bytes32 instanceId,
        uint256 componentId,
        address token
    )
        internal 
        virtual
        pure 
        returns(bytes memory)
    {
        return abi.encode(instanceId, componentId, token);
    }


    function _decodeComponentData(bytes memory data) 
        internal 
        virtual 
        view 
        returns(
            bytes32 instanceId,
            uint256 componentId,
            address token
        )
    {
        (instanceId, componentId, token)
            = abi.decode(data, (bytes32, uint256, address));
    }


    function _encodeBundleData(
        bytes32 instanceId,
        uint256 riskpoolId,
        uint256 bundleId,
        address token,
        string memory displayName,
        uint256 expiryAt
    )
        internal 
        virtual
        pure 
        returns(bytes memory)
    {
        return abi.encode(instanceId, riskpoolId, bundleId, token, expiryAt, displayName);
    }


    function _decodeBundleData(bytes memory data) 
        internal 
        virtual 
        view 
        returns(
            bytes32 instanceId,
            uint256 riskpoolId,
            uint256 bundleId,
            address token,
            string memory displayName,
            uint256 expiryAt
        )
    {
        (instanceId, riskpoolId, bundleId, token, expiryAt, displayName) 
            = abi.decode(data, (bytes32, uint256, uint256, address, uint256, string));
    }


    function _encodeStakeData(NftId target, ObjectType targetType)
        internal 
        virtual
        pure 
        returns(bytes memory)
    {
        return abi.encode(target, targetType);
    }


    function _decodeStakeData(bytes memory data) 
        internal
        virtual
        view
        returns(
            NftId target,
            ObjectType targetType
        )
    {
        (target, targetType) 
            = abi.decode(data, (NftId, ObjectType));
    }


    function getInstanceServiceFacade(bytes32 instanceId) 
        public
        virtual override
        view
        returns(IInstanceServiceFacade instanceService)
    {
        NftId id = _instance[instanceId];
        (, address registry, ) = decodeInstanceData(id);
        (,,,,, instanceService) = probeInstance(registry);
    }


    function _toObjectType(IInstanceServiceFacade.ComponentType cType)
        internal 
        virtual
        pure
        returns(ObjectType t)
    {
        if(cType == IInstanceServiceFacade.ComponentType.Riskpool) {
            return RISKPOOL;
        }

        if(cType == IInstanceServiceFacade.ComponentType.Product) {
            return PRODUCT;
        }

        return ORACLE;
    }


    function _safeMintObject(
        address to,
        ChainId chain,
        ObjectType objectType,
        ObjectState state,
        string memory uri,
        bytes memory data
    )
        internal
        virtual
        returns(NftId id)
    {
        require(address(_nft) != address(0), "ERROR:CRG-350:NFT_NOT_SET");
        require(_typeSupported[objectType], "ERROR:CRG-351:OBJECT_TYPE_NOT_SUPPORTED");

        // mint nft
        id = toNftId(_nft.mint(to, uri));

        // store nft meta data
        NftInfo storage info = _info[id];
        info.id = id;
        info.chain = chain;
        info.objectType = objectType;
        info.mintedIn = blockNumber();
        info.version = version();

        _setObjectState(id, state);

        // store data if provided        
        if(data.length > 0) {
            info.data = data;
        }

        // general object book keeping
        _object[chain][objectType].push(id);

        // object type specific book keeping
        if(objectType == CHAIN) {
            _chain[chain] = id;
            _chainIds.push(chain);
        } else if(objectType == REGISTRY) {
            _registry[chain] = id;
        } else if(objectType == TOKEN) {
            (address token) = _decodeTokenData(data);
            _contractObject[chain][token] = id;
        } else if(objectType == INSTANCE) {
            (bytes32 instanceId, address registry, ) = _decodeInstanceData(data);
            _contractObject[chain][registry] = id;
            _instance[instanceId] = id;
        } else if(
            objectType == RISKPOOL
            || objectType == PRODUCT
            || objectType == ORACLE
        ) {
            (bytes32 instanceId, uint256 componentId, ) = _decodeComponentData(data);
            _component[instanceId][componentId] = id;
        } else if(objectType == BUNDLE) {
            (bytes32 instanceId, , uint256 bundleId, , , ) = _decodeBundleData(data);
            _bundle[instanceId][bundleId] = id;
        }

        emit LogChainRegistryObjectRegistered(id, chain, objectType, state, to);
    }


    function _getContractSize(address contractAddress)
        internal
        view
        returns(uint256 size)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(contractAddress)
        }
    }
}
