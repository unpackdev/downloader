// SPDX-License-Identifier: MIT
// Creator: twitter.com/runo_dev

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface MoonTurtlez {
    function owner() external view returns (address);

    function mintToAddress(address to, uint256 amount) external;

    function transferOwnership(address newOwner) external;
}

contract MoonTurtlezMinter is Ownable, ReentrancyGuard {
    uint256 private _maxMintPerTx = 2;
    uint256 private _maxMintPerWallet = 2;
    bool private _mintStatus = false;

    MoonTurtlez private _moonTurtlez;
    mapping(address => uint256) private _mints;

    constructor(address turtlezAddress) {
        _moonTurtlez = MoonTurtlez(turtlezAddress);
    }

    function isMintingActive() external view returns (bool) {
        return _mintStatus;
    }

    function getMintsOfAccount(address account)
        external
        view
        returns (uint256)
    {
        return _mints[account];
    }

    function mint(uint256 amount) external turtleOwnerIsMinter nonReentrant {
        if (!_mintStatus) revert("Minting has not started yet.");
        if (amount == 0) revert("The amount must be greater than 0.");
        if (amount > _maxMintPerTx)
            revert("The amount exceeds the limit per tx.");
        if (_mints[msg.sender] + amount > _maxMintPerWallet)
            revert("The amount exceeds the limit per wallet.");
        _moonTurtlez.mintToAddress(msg.sender, amount);
        _mints[msg.sender] += amount;
    }

    function setMaxMintPerTx(uint256 newValue) external onlyOwner {
        _maxMintPerTx = newValue;
    }

    function setMaxMintPerWallet(uint256 newValue) external onlyOwner {
        _maxMintPerWallet = newValue;
    }

    function toggleMintStatus() external onlyOwner {
        _mintStatus = !_mintStatus;
    }

    function setTurtlezContract(address turtlezAddress) external onlyOwner {
        _moonTurtlez = MoonTurtlez(turtlezAddress);
    }

    function reclaimOwnership() external turtleOwnerIsMinter onlyOwner {
        _moonTurtlez.transferOwnership(msg.sender);
    }

    modifier turtleOwnerIsMinter() {
        if (_moonTurtlez.owner() != address(this))
            revert(
                "The owner of MoonTurtlez's contract must be this contract."
            );
        _;
    }
}
