// SPDX-License-Identifier: WTFPL

pragma solidity 0.8.13;

import "./IERC20.sol";
import "./SafeERC20.sol";

interface ENS {
    function owner(bytes32 node) external view returns (address);

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);
}

interface PublicResolver {
    function setAddr(bytes32 node, address a) external;
}

contract SubdomainsRegistry {
    using SafeERC20 for IERC20;

    address public immutable owner;
    address public immutable token;
    address public immutable ens;
    bytes32 public immutable node;
    address public immutable resolver;

    mapping(address => Registration) public registrations;

    struct Registration {
        uint64 deadline;
        bool paid;
        bool withdrawn;
    }

    event Register(string domain, bytes32 indexed label, address indexed to, bool indexed paid);
    event Withdraw(address indexed to);

    constructor(
        address _token,
        address _ens,
        bytes32 _node,
        address _resolver
    ) {
        owner = msg.sender;
        token = _token;
        ens = _ens;
        node = _node;
        resolver = _resolver;
    }

    function register(string memory domain, address to) external {
        require(registrations[msg.sender].deadline == 0, "LEVX: ONE_DOMAIN_ALLOWED");

        uint256 length = bytes(domain).length;
        require(length >= 3, "LEVX: DOMAIN_TOO_SHORT");

        bytes32 label = keccak256(abi.encodePacked(domain));
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        require(ENS(ens).owner(subnode) == address(0), "LEVX: DUPLICATE");

        ENS(ens).setSubnodeRecord(node, label, address(this), resolver, 0);

        PublicResolver(resolver).setAddr(subnode, to);
        ENS(ens).setSubnodeOwner(node, label, to);

        bool paid = length <= 7;
        registrations[msg.sender] = Registration(uint64(block.timestamp + 2 weeks), paid, false);
        emit Register(domain, label, to, paid);
        if (paid) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), 1e18);
        }
    }

    function withdraw(address to) external {
        Registration storage registration = registrations[msg.sender];
        (uint64 deadline, bool paid, bool withdrawn) = (
            registration.deadline,
            registration.paid,
            registration.withdrawn
        );
        require(paid, "LEVX: NON_PAID");
        require(deadline > 0, "LEVX: NON_EXISTENT");
        require(deadline <= block.timestamp, "LEVX: TOO_EARLY");
        require(!withdrawn, "LEVX: WITHDRAWN");

        registration.withdrawn = true;
        emit Withdraw(to);
        IERC20(token).safeTransfer(to, 1e18);
    }
}
