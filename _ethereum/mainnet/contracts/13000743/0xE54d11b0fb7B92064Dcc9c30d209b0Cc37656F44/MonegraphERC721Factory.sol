// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./ERC1967Proxy.sol";
import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";

import "./AccessControl.sol";

contract MonegraphERC721Factory is UpgradeableBeacon, AccessControl {
    event BeaconCreated(
        address indexed admin,
        address contractAddress,
        bool managed
    );

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    address public monegraph;
    address public controller;

    constructor(address implemenationAddress, address _controller)
        UpgradeableBeacon(implemenationAddress)
    {
        address sender = _msgSender();

        controller = _controller;

        _setupRole(DEFAULT_ADMIN_ROLE, sender);
        _setupRole(CREATOR_ROLE, sender);
    }

    modifier canDeploy() {
        address addr = _msgSender();
        bool canCreate = hasRole(DEFAULT_ADMIN_ROLE, addr) ||
            hasRole(CREATOR_ROLE, addr);

        if (false == canCreate && controller != address(0)) {
            (bool success, bytes memory result) = controller.call(
                abi.encodeWithSignature("canCreateCollections(address)", addr)
            );

            require(success, "Controller reverted");

            canCreate = abi.decode(result, (bool));
        }

        require(canCreate, "MonegraphERC721Factory: Permissions Failed");
        _;
    }

    function setController(address _controller)
        public
        onlyRole(getRoleAdmin(CREATOR_ROLE))
    {
        controller = _controller;
    }

    function batchGrantCreators(address[] memory addresses)
        public
        virtual
        onlyRole(getRoleAdmin(CREATOR_ROLE))
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            grantRole(CREATOR_ROLE, addresses[i]);
        }
    }

    function createMonegraph(string memory name, string memory symbol)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address)
    {
        require(
            monegraph == address(0),
            "Monegraph contract has already been created"
        );

        monegraph = createContract(name, symbol, true);

        return monegraph;
    }

    function createContract(
        string memory name,
        string memory symbol,
        bool managed
    ) public canDeploy returns (address) {
        address addr = _msgSender();
        address contractAddress;

        bytes memory data = abi.encodeWithSignature(
            "initialize(string,string,address)",
            name,
            symbol,
            addr
        );

        if (managed == true) {
            BeaconProxy proxy = new BeaconProxy(address(this), data);
            contractAddress = address(proxy);
        } else {
            ERC1967Proxy proxy = new ERC1967Proxy(implementation(), data);
            contractAddress = address(proxy);
        }

        emit BeaconCreated(addr, contractAddress, managed);

        return contractAddress;
    }
}
