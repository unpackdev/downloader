// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./WrappedToken.sol";

contract BridgeFactory {


    event WrappedTokenDeployed(address indexed wrappedToken, address indexed wrappedTokenOwner);
    event CustomTokenDeployed(address indexed wrappedToken, address indexed wrappedTokenOwner);

    constructor() {}


    function deploy(string memory _name, string memory _symbol, uint256 dec, address owner, address bridge) external returns(address addr) {
        addr = address(new WrappedToken(_name, _symbol, dec, owner, bridge));
        require(addr!=address(0), "NULL_CONTRACT_ADDRESS_CREATED");
        
        // IBridge(bridge).setMintableToken(addr, true);

        emit WrappedTokenDeployed(addr, owner);
        
        return addr;
    }

    function deployCustomToken(uint256 salt, bytes memory init, address tokenOwner) external returns(address addr) {
        
        assembly {
            let encoded_data := add(0x20, init) // load initialization code.
            let encoded_size := mload(init)     // load init code's length.
            addr := create2(0, encoded_data, encoded_size, salt)
        }
        require(addr!=address(0), "NULL_CONTRACT_ADDRESS_CREATED");

        // IBridge(bridge).setMintableToken(addr, true);

        emit CustomTokenDeployed(addr, tokenOwner);
        
        return addr;
    }
    
}
