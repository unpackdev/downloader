// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IMochiEngine.sol";

contract MinterV0 is IMinter {
    IMochiEngine public immutable engine;

    address public immutable pauser;

    mapping(address => bool) public isMinter;

    bool public paused;

    constructor(address _engine, address _pauser) {
        require(_engine != address(0), "engine cannot be zero address");
        engine = IMochiEngine(_engine);
        pauser = _pauser;
    }

    modifier onlyPermission() {
        require(hasPermission(msg.sender), "!permission");
        _;
    }

    modifier onlyGov() {
        require(msg.sender == engine.governance(), "!gov");
        _;
    }

    modifier onlyPauser() {
        require(msg.sender == pauser, "!pauser");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    function addMinter(address _minter) external onlyGov {
        isMinter[_minter] = true;
    }

    function removeMinter(address _minter) external onlyGov {
        isMinter[_minter] = false;
    }

    function pause() external override onlyPauser {
        paused = true;
    }

    function unpause() external override onlyPauser {
        paused = false;
    }

    function mint(address _to, uint256 _amount)
        external
        override
        whenNotPaused
        onlyPermission
    {
        engine.usdm().mint(_to, _amount);
    }

    function hasPermission(address _user) public view override returns (bool) {
        return isMinter[_user] || isVault(_user);
    }

    function isVault(address _vault) public view override returns (bool) {
        return
            address(
                engine.vaultFactory().getVault(
                    address(IMochiVault(_vault).asset())
                )
            ) == _vault;
    }
}
