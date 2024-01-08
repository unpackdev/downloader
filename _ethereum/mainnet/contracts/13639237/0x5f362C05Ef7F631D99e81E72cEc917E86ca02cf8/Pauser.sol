// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IMochiVault.sol";
import "./IPauser.sol";

contract Pauser is IPauser{
    address public override caller;

    IMochiEngine public override engine;

    constructor(address _caller, address _engine) {
        caller = _caller;
        engine = IMochiEngine(_engine);
        emit CallerChanged(_caller);
    }

    function changeCaller(address _newCaller) external override {
        require(msg.sender == engine.governance(), "!gov");
        caller = _newCaller;
        emit CallerChanged(_newCaller);
    }

    function pauseMint() external override {
        require(msg.sender == caller, "!caller");
        engine.minter().pause();
    }

    function unpauseMint() external override {
        require(msg.sender == caller, "!caller");
        engine.minter().unpause();
    }

    function pause(address[] calldata _vaults) external override {
        require(msg.sender == caller, "!caller");
        for(uint256 i = 0; i<_vaults.length; i++) {
            IMochiVault(_vaults[i]).pause();
        }
    }
    
    function unpause(address[] calldata _vaults) external override{
        require(msg.sender == caller, "!caller");
        for(uint256 i = 0; i<_vaults.length; i++) {
            IMochiVault(_vaults[i]).unpause();
        }
    }
}
