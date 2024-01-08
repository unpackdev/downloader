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

    mapping(address => address[]) private deployed;

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    address public monegraph;

    constructor(address implemenationAddress)
        UpgradeableBeacon(implemenationAddress)
    {
        address sender = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, sender);
        _setupRole(CREATOR_ROLE, sender);
    }

    modifier canDeploy(address addr) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, addr) || deployed[addr].length == 0,
            "Creators are permitted to deploy one contract"
        );
        _;
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

    function getContracts(address addr) public view returns (address[] memory) {
        return deployed[addr];
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
    ) public onlyRole(CREATOR_ROLE) returns (address) {
        address addr = _msgSender();
        address contractAddress;

        bytes memory data =
            abi.encodeWithSignature(
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

        deployed[addr].push(contractAddress);

        emit BeaconCreated(addr, contractAddress, managed);

        return contractAddress;
    }
}
