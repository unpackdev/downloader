// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";

import "./IRandom.sol";

contract Random is IRandom, Ownable {
    mapping(uint256 => bytes32) private hashes;
    mapping(uint256 => uint256) private nonces;

    mapping(address => bool) public controllers;

    modifier onlyControllers() {
        require(controllers[_msgSender()], "ONLY_CONTROLLERS_ALLOWED");
        _;
    }

    constructor() {}

    function submitHash(address sender, uint256 tokenId)
        external
        override
        onlyControllers
    {
        require(hashes[tokenId].length == 0, "ALREADY_SUBMITED");
        bytes32 newHash = keccak256(
            abi.encodePacked(
                sender,
                tokenId,
                nonces[tokenId],
                "bb",
                gasleft(),
                blockhash(block.number - 1),
                block.timestamp
            )
        );
        hashes[tokenId] = newHash;
        nonces[tokenId] += 1;
    }

    function getRandomNumber(uint256 tokenId)
        external
        override
        onlyControllers
        returns (uint256)
    {
        bytes32 _hash = hashes[tokenId];
        require(_hash.length > 0, "NO_HASH");
        delete hashes[tokenId];
        return uint256(_hash);
    }

    /// @notice add a controller that will be able to call functions in this contract
    /// @param controller the address that will be authorized
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /// @notice remove a controller so it won't be able to call functions in this contract anymore
    /// @param controller the address that will be unauthorized
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}
