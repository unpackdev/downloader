// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Clones.sol";
import "./ERC2771Context.sol";
import "./Ownable.sol";
import "./Multicall.sol";

import "./IMMContract.sol";
import "./MMRegistry.sol";

contract MMFactory is ERC2771Context, Ownable, Multicall {
    MMRegistry public immutable registry;

    // emitted when a proxy is deployed.
    event ProxyDeployed(
        address indexed implementation,
        address proxy,
        address indexed deployer
    );

    // emitted when a new implementation address is added
    event ImplementationAdded(
        address implementation,
        bytes32 indexed contractType,
        uint256 version
    );

    // emitted when a implementation address is approved
    event ImplementationApproved(address implementation, bool isApproved);

    // mapping of implementation address to deployment approval
    mapping(address => bool) public approval;

    // mapping of proxy address to deployer address
    mapping(address => address) public deployer;

    // mapping of template type to its current version
    mapping(bytes32 => uint256) public currentVersion;

    // mapping of template type to its corresponding address
    mapping(bytes32 => mapping(uint256 => address)) public implementation;

    constructor(address _trustedForwarder, address _registry)
        ERC2771Context(_trustedForwarder)
    {
        registry = MMRegistry(_registry);
    }

    /***********************************************************************
                                DEPLOYMENT LOGIC
     *************************************************************************/
    // Deploys a proxy that points to the latest version of the given contract type.
    function deployProxy(bytes32 _type, bytes memory _data)
        public
        returns (address)
    {
        bytes32 salt = bytes32(registry.count(_msgSender()));
        return deployProxyDeterministic(_type, _data, salt);
    }

    /**
     * Deploys a proxy at a deterministic address by taking in `salt` as a parameter.
     *       Proxy points to the latest version of the given contract type.
     */
    function deployProxyDeterministic(
        bytes32 _type,
        bytes memory _data,
        bytes32 _salt
    ) public returns (address) {
        address _implementation = implementation[_type][currentVersion[_type]];
        return
            deployProxyByImplementation(_implementation, _type, _data, _salt);
    }

    // Deploys a proxy that points to the given implementation.
    function deployProxyByImplementation(
        address _implementation,
        bytes32 _type,
        bytes memory _data,
        bytes32 _salt
    ) public returns (address deployedProxy) {
        require(approval[_implementation], "Not approved for deployment");

        bytes32 saltHash = keccak256(abi.encodePacked(_msgSender(), _salt));
        deployedProxy = Clones.cloneDeterministic(_implementation, saltHash);

        // set deployer for the newly deployed proxy
        deployer[deployedProxy] = _msgSender();

        emit ProxyDeployed(_implementation, deployedProxy, _msgSender());

        // add deployment to registry
        registry.add(_msgSender(), deployedProxy, _type);

        if (_data.length > 0) {
            Address.functionCall(deployedProxy, _data);
        }
    }

    /***********************************************************************
                        IMPLEMENTATION ADDRESS FUNCTIONS
     *************************************************************************/
    // Lets a contract admin set the address of a contract type x version.
    function addImplementation(address _implementation) external onlyOwner {
        IMMContract template = IMMContract(_implementation);

        // get template type and check its validity
        bytes32 tempType = template.contractType();
        require(tempType.length > 0, "Invalid template");

        // get new version and check if it is the latest version
        uint8 version = template.contractVersion();
        uint8 previousVersion = uint8(currentVersion[tempType]);
        require(version >= previousVersion, "Wrong version");

        currentVersion[tempType] = version;
        implementation[tempType][version] = _implementation;
        approval[_implementation] = true;

        emit ImplementationAdded(_implementation, tempType, version);
    }

    // Lets a contract admin approve a specific contract for deployment.
    function approveImplementation(address _implementation, bool _approve)
        external
        onlyOwner
    {
        approval[_implementation] = _approve;

        emit ImplementationApproved(_implementation, _approve);
    }

    // Returns the implementation given a contract type and version.
    function getImplementation(bytes32 _type, uint8 _version)
        external
        view
        returns (address)
    {
        return implementation[_type][_version];
    }

    // Returns the latest implementation given a contract type.
    function getLastestImplementation(bytes32 _type)
        external
        view
        returns (address)
    {
        return implementation[_type][currentVersion[_type]];
    }

    function getDeterministicAddress(address _implementation)
        external
        view
        returns (address)
    {
        bytes32 salt = bytes32(registry.count(_msgSender()));
        bytes32 saltHash = keccak256(abi.encodePacked(_msgSender(), salt));
        return Clones.predictDeterministicAddress(_implementation, saltHash);
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}
