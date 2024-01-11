// SPDX-License-Identifier: WTFPL

pragma solidity 0.8.13;

import "./ENS.sol";
import "./AddrResolver.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract SubdomainsRegistry {
    using SafeERC20 for IERC20;

    address immutable token;
    address immutable registry;
    bytes32 immutable node;
    address immutable resolver;
    uint256 immutable deadline;

    mapping(address => uint256) public amountLocked;

    event Register(string indexed domain, address indexed to);
    event Withdraw(uint256 amount, address indexed to);

    constructor(
        address _token,
        address _registry,
        bytes32 _node,
        address _resolver,
        uint256 _deadline
    ) {
        token = _token;
        registry = _registry;
        node = _node;
        resolver = _resolver;
        deadline = _deadline;
    }

    function register(string memory domain, address to) external {
        require(block.timestamp < deadline, "LEVX: EXPIRED");

        uint256 length = bytes(domain).length;
        require(length >= 3, "LEVX: DOMAIN_TOO_SHORT");

        bytes32 label = keccak256(abi.encodePacked(domain));
        ENS(registry).setSubnodeRecord(node, label, to, resolver, 0);

        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        bytes memory newAddress = abi.encodePacked(
            "0x00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000014",
            to,
            "0x000000000000000000000000"
        );
        AddrResolver(resolver).setAddr(subnode, 60, newAddress);

        uint256 amount;
        if (length == 3) {
            amount = 10e18;
        } else if (length == 4) {
            amount = 333e16;
        } else if (length <= 7) {
            amount = 1e18;
        }
        emit Register(domain, to);
        if (amount > 0) {
            amountLocked[msg.sender] += amount;
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function withdraw() external {
        require(block.timestamp >= deadline, "LEVX: TOO_EARLY");

        uint256 amount = amountLocked[msg.sender];
        require(amount > 0, "LEVX: NOTHING_TO_WITHDRAW");
        emit Withdraw(amount, msg.sender);
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
