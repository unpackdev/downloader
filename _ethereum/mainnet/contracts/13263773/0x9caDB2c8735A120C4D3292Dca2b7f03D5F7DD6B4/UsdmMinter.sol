// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IMochiEngine.sol";

contract MinterV1 is IMinter {
    IMochiEngine public immutable engine;

    mapping(address => bool) public isMinter;

    address[] public factories;

    constructor(address _engine) {
        engine = IMochiEngine(_engine);
        factories.push(address(IMochiEngine(_engine).vaultFactory()));
    }

    modifier onlyPermission() {
        require(hasPermission(msg.sender), "!permission");
        _;
    }

    modifier onlyGov() {
        require(msg.sender == engine.governance(), "!gov");
        _;
    }

    function addMinter(address _minter) external onlyGov {
        isMinter[_minter] = true;
    }

    function removeMinter(address _minter) external onlyGov {
        isMinter[_minter] = false;
    }

    function addFactory(address _factory) external onlyGov {
        factories.push(_factory);
    }

    function removeFactory(address _factory) external onlyGov {
        for(uint256 i = 0; i<factories.length; i++) {
            if(factories[i] == _factory) {
                factories[i] = factories[factories.length - 1];
                factories.pop();
                return;
            }
        }
        revert("factory not found");
    }

    function mint(address _to, uint256 _amount)
        external
        override
        onlyPermission
    {
        engine.usdm().mint(_to, _amount);
    }

    function hasPermission(address _user) public view override returns (bool) {
        return isMinter[_user] || isVault(_user);
    }

    function isVault(address _vault) public view returns (bool) {
        for(uint256 i = 0; i<factories.length; i++) {
            if(address(IMochiVaultFactory(factories[i]).getVault(address(IMochiVault(_vault).asset()))) == _vault) {
                return true;
            }
        }
        return false;
    }
}
