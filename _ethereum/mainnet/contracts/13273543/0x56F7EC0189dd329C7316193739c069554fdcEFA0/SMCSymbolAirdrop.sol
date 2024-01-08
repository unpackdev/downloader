// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./Context.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

import "./console.sol";

interface IToken {
    function mint(address, uint256) external;

    function exists(uint256) external view returns (bool);
}

contract SMCSymbolAirdrop is Pausable, AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Airdrop {
        address tokenContract;
        uint256 idFrom;
        uint256 idTo;
        uint32 since;
        uint32 until;
        uint32 stock;
        bool enabled;
    }

    mapping(uint256 => Airdrop) public airdrops;
    mapping(uint256 => uint32) public claimedNum;
    mapping(uint256 => mapping(address => bool)) public claimedAddress;

    constructor() {
        _setRoleAdmin(OPERATOR_ROLE, OPERATOR_ROLE);
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function setAirdrop(uint256 airdropId, Airdrop memory airdrop)
        external
        onlyRole(OPERATOR_ROLE)
    {
        airdrops[airdropId] = airdrop;
    }

    function revokeAirdrop(uint256 airdropId) external onlyRole(OPERATOR_ROLE) {
        airdrops[airdropId].enabled = false;
    }

    function isClaimable(uint256 airdropId, uint256 tokenId)
        public
        view
        returns (bool)
    {
        Airdrop memory airdrop = airdrops[airdropId];

        if (IToken(airdrop.tokenContract).exists(tokenId)) {
            return false;
        }

        uint32 timestamp = uint32(block.timestamp);
        if (timestamp < airdrop.since || airdrop.until < timestamp) {
            return false;
        }

        if (tokenId < airdrop.idFrom || airdrop.idTo < tokenId) {
            return false;
        }

        if (getStock(airdropId) == 0) {
            return false;
        }

        return true;
    }

    function getStock(uint256 airdropId) public view returns (uint256) {
        Airdrop memory airdrop = airdrops[airdropId];
        return airdrop.stock - claimedNum[airdropId];
    }

    function claim(uint256 airdropId, uint256 tokenId) external whenNotPaused {
        require(
            !claimedAddress[airdropId][_msgSender()],
            "Airdrop: already claimed"
        );
        Airdrop memory airdrop = airdrops[airdropId];
        require(airdrop.enabled, "Airdrop: airdrop disabled");

        uint32 timestamp = uint32(block.timestamp);
        require(
            airdrop.since <= timestamp && timestamp <= airdrop.until,
            "Airdrop: outside of airdrop period"
        );

        require(
            airdrop.idFrom <= tokenId && tokenId <= airdrop.idTo,
            "Airdrop: out of token id range"
        );

        require(getStock(airdropId) > 0, "Airdrop: out of stock");

        IToken(airdrop.tokenContract).mint(_msgSender(), tokenId);
        claimedNum[airdropId]++;
        claimedAddress[airdropId][_msgSender()] = true;
    }

    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }
}
