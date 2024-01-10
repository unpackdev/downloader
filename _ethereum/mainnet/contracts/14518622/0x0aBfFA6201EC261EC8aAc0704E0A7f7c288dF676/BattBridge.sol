// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./Ownable.sol";

interface IBatt {
    function mint(address _to, uint _amount) external;
}

contract BattBridge is Ownable {

    address public admin;
    IBatt public batt;

    string public constant CONTRACT_NAME = "Batt Bridge Contract";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant CLAIM_TYPEHASH = keccak256("Claim(address to,uint256 amount)");

    event TokenClaimed(address to, uint256 amount, uint256 timestamp);

    constructor() {}

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function setBatt(address _batt) external onlyOwner {
        batt = IBatt(_batt);
    }

    function claim(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, to, amount));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        batt.mint(to, amount);
        emit TokenClaimed(to, amount, block.timestamp);
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
