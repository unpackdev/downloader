pragma solidity >=0.6.0 <0.7.0;

import "./Context.sol";


/**
 * @title Initializable allows to create initializable contracts
 * so that only deployer can initialize contract and only once
 */
contract Initializable is Context {
    bool private _isContractInitialized;
    address private _deployer;

    constructor() public {
        _deployer = _msgSender();
    }

    modifier initializer {
        require(_msgSender() == _deployer, "user not allowed to initialize");
        require(!_isContractInitialized, "contract already initialized");
        _;
        _isContractInitialized = true;
    }
}
