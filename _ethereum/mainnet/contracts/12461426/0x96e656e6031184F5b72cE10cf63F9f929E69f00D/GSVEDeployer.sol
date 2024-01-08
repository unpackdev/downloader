// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IFreeFromUpTo.sol";


/**
* @dev the gsve deployer has two purposes
* it deploys gsve smart wrappers, keeping track of the owners
* it allows users to deploy smart contracts using create and create2
*/
contract GSVEDeployer is Ownable{
    mapping(address => uint256) private _compatibleGasTokens;
    mapping(address => uint256) private _freeUpValue;

  constructor (address wchi, address wgst2, address wgst1) public {
    _compatibleGasTokens[wchi] = 1;
    _freeUpValue[wchi] = 30053;

    _compatibleGasTokens[wgst2] = 1;
    _freeUpValue[wgst2] = 30870;

    _compatibleGasTokens[wgst1] = 1;
    _freeUpValue[wgst1] = 20046;
  }

    /**
    * @dev add support for trusted gas tokens - those we wrapped
    */
    function addGasToken(address gasToken, uint256 freeUpValue) public onlyOwner{
        _compatibleGasTokens[gasToken] = 1;
        _freeUpValue[gasToken] = freeUpValue;
    }
    
    /**
    * @dev function to check if a gas token is supported by the deployer
    */
    function compatibleGasToken(address gasToken) public view returns(uint256){
        return _compatibleGasTokens[gasToken];
    }

    /**
    * @dev GSVE moddifier that burns supported gas tokens around a function that uses gas
    * the function calculates the optimal number of tokens to burn, based on the token specified
    */
    modifier discountGas(address gasToken) {
        if(gasToken != address(0)){
            require(_compatibleGasTokens[gasToken] == 1, "GSVE: incompatible token");
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            IFreeFromUpTo(gasToken).freeFromUpTo(msg.sender,  (gasSpent + 16000) / _freeUpValue[gasToken]);
        }
        else{
            _;
        }
    }

    /**
    * @dev deploys a smart contract using the create function
    * if the contract is ownable, the contract ownership is passed to the message sender
    * the gas token passed in as argument is burned by the moddifier
    */
    function GsveDeploy(bytes memory data, address gasToken) public discountGas(gasToken) returns(address contractAddress) {
        assembly {
            contractAddress := create(0, add(data, 32), mload(data))
        }
        try Ownable(contractAddress).transferOwnership(msg.sender){
            emit ContractDeployed(msg.sender, contractAddress);
        }
        catch{
            emit ContractDeployed(msg.sender, contractAddress);
        }
    }

    /**
    * @dev deploys a smart contract using the create2 function and a user provided salt
    * if the contract is ownable, the contract ownership is passed to the message sender
    * the gas token passed in as argument is burned by the moddifier
    */
    function GsveDeploy2(uint256 salt, bytes memory data, address gasToken) public discountGas(gasToken) returns(address contractAddress) {
        assembly {
            contractAddress := create2(0, add(data, 32), mload(data), salt)
        }

        try Ownable(contractAddress).transferOwnership(msg.sender){
            emit ContractDeployed(msg.sender, contractAddress);
        }
        catch{
            emit ContractDeployed(msg.sender, contractAddress);
        }
    }
    
    event ContractDeployed(address indexed creator, address deploymentAddress);
}