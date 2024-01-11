// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./Clones.sol";
import "./PublicResolver.sol";
import "./ENSRegistry.sol";
import "./GnosisSafeProxyFactory.sol";
import "./ERC721Holder.sol";

import "./ERC20Singleton.sol";
import "./IClearingHouse.sol";
import "./IGovernor.sol";
import "./IENSRegistrar.sol";

contract Governor is IGovernor, Ownable, ERC721Holder {
    PublicResolver public override ensResolver;
    ENSRegistry public override ensRegistry;
    IENSRegistrar public override ensRegistrar;
    GnosisSafeProxyFactory public override gnosisFactory;
    address public override gnosisSafeSingleton;
    address public override erc20Singleton;
    uint256 public override ensDomainNFTId;
    IClearingHouse public clearingHouse;

    constructor(ConstructorParams memory _params) {
        require(
            address(_params.ensResolver) != address(0),
            "invalid resolver address"
        );
        require(
            address(_params.ensRegistry) != address(0),
            "invalid registry address"
        );
        require(
            address(_params.ensRegistrar) != address(0),
            "invalid registrar address"
        );
        require(
            address(_params.gnosisFactory) != address(0),
            "invalid factory address"
        );
        require(
            _params.gnosisSafeSingleton != address(0),
            "invalid safe singleton address"
        );
        require(
            _params.erc20Singleton != address(0),
            "invalid token singleton address"
        );
        require(_params.parentDao != address(0), "invalid owner");
        require(
            address(_params.clearingHouse) != address(0),
            "invalid clearing house address"
        );

        ensResolver = _params.ensResolver;
        ensRegistry = _params.ensRegistry;
        ensRegistrar = _params.ensRegistrar;
        gnosisFactory = _params.gnosisFactory;
        gnosisSafeSingleton = _params.gnosisSafeSingleton;
        erc20Singleton = _params.erc20Singleton;
        clearingHouse = _params.clearingHouse;

        transferOwnership(_params.parentDao);
    }

    function addENSDomain(uint256 _domainNFTId) external override onlyOwner {
        require(ensDomainNFTId == 0, "ens domain already set");
        ensDomainNFTId = _domainNFTId;
        ensRegistrar.safeTransferFrom(
            address(msg.sender),
            address(this),
            _domainNFTId
        );

        ensRegistrar.reclaim(_domainNFTId, address(this));
    }

    function withdrawENSDomain(address _destination)
        external
        override
        onlyOwner
    {
        require(ensDomainNFTId > 0, "ens domain not set");
        uint256 _domainNFTId = ensDomainNFTId;
        delete ensDomainNFTId;
        ensRegistrar.safeTransferFrom(
            address(this),
            _destination,
            _domainNFTId
        );
    }

    function createChildDAO(
        Token calldata _tokenData,
        Safe calldata _safeData,
        Subdomain calldata _subdomain
    ) external override onlyOwner {
        require(ensDomainNFTId > 0, "ENS domain unavailable");

        /// Gnosis multi sig
        address safe = _createGnosisSafe(
            _safeData.initializer,
            uint256(
                keccak256(abi.encodePacked(_subdomain.subdomain, address(this)))
            )
        );

        /// Token
        address token = _createERC20Clone(
            _tokenData.tokenName,
            _tokenData.tokenSymbol
        );

        /// Register the token in the clearing house contract
        clearingHouse.registerChildDao(ERC20Singleton(token));

        // /// ENS Subdomain + Snapshot text record
        bytes32 node = _createENSSubdomain(
            safe,
            _subdomain.subdomain,
            _subdomain.snapshotKey,
            _subdomain.snapshotValue
        );

        emit ChildDaoCreated(safe, token, node);
    }

    function _createGnosisSafe(bytes memory _initializer, uint256 _salt)
        internal
        returns (address safe)
    {
        safe = address(
            gnosisFactory.createProxyWithNonce(
                gnosisSafeSingleton,
                _initializer,
                _salt
            )
        );
    }

    function _createERC20Clone(bytes memory _name, bytes memory _symbol)
        internal
        returns (address token)
    {
        token = Clones.cloneDeterministic(
            erc20Singleton,
            keccak256(abi.encodePacked(_name, _symbol))
        );
        ERC20Singleton(token).initialize(
            _name,
            _symbol,
            address(clearingHouse)
        );
    }

    function _calculateENSNode(bytes32 baseNode, bytes32 childNode)
        internal
        pure
        returns (bytes32 ensNode)
    {
        ensNode = keccak256(abi.encodePacked(baseNode, childNode));
    }

    function _createENSSubdomain(
        address _owner,
        bytes memory _name,
        bytes memory _key,
        bytes memory _value
    ) internal returns (bytes32 childNode) {
        bytes32 labelHash = keccak256(_name);

        bytes32 ensBaseNode = ensRegistrar.baseNode();
        bytes32 parentNode = _calculateENSNode(
            ensBaseNode,
            bytes32(ensDomainNFTId)
        );
        childNode = _calculateENSNode(parentNode, labelHash);

        ensRegistry.setSubnodeRecord(
            parentNode,
            labelHash,
            address(this),
            address(ensResolver),
            3600
        );

        ensResolver.setAddr(childNode, _owner);

        ensResolver.setText(childNode, string(_key), string(_value));
    }
}
