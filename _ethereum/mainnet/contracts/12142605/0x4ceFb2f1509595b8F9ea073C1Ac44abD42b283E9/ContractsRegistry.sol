// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./TransparentUpgradeableProxy.sol";

import "./IContractsRegistry.sol";

contract ContractsRegistry is IContractsRegistry, AccessControl {
    address constant public PROXY_ADMIN = 0x56fEB55FFD9365D42D0a5321a3a029C4640Bd8DC;

    mapping (bytes32 => address) private _contracts;

    bytes32 constant public REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");
    
    bytes32 constant public UNISWAP_BMI_TO_ETH_PAIR_NAME = keccak256("UNI_BMI_ETH_PAIR");    

    bytes32 constant public BMI_STAKING_NAME = keccak256("BMI_STAKING_NAME");
    
    bytes32 constant public BMI_NAME = keccak256("BMI");    
    bytes32 constant public STKBMI_NAME = keccak256("STK_BMI");    

    bytes32 constant public LIQUIDITY_MINING_STAKING_NAME = keccak256("LIQ_MINING_STAKING");

    modifier onlyAdmin() {
        require(hasRole(REGISTRY_ADMIN_ROLE, msg.sender), "ContractsRegistry: Caller is not an admin");
        _;
    }

    constructor() {
        _setupRole(REGISTRY_ADMIN_ROLE, msg.sender);        
        _setRoleAdmin(REGISTRY_ADMIN_ROLE, REGISTRY_ADMIN_ROLE);
    }        

    function getUniswapBMIToETHPairContract() external view override returns (address) {
        return getContract(UNISWAP_BMI_TO_ETH_PAIR_NAME);
    }

    function getBMIContract() external view override returns (address) {
        return getContract(BMI_NAME);
    }

    function getBMIStakingContract() external view override returns (address) {
        return getContract(BMI_STAKING_NAME);
    }

    function getSTKBMIContract() external view override returns (address) {
        return getContract(STKBMI_NAME);
    }

    function getLiquidityMiningStakingContract() external override view returns (address) {
        return getContract(LIQUIDITY_MINING_STAKING_NAME);
    }    

    function getContract(bytes32 name) public view returns (address) {
        require(_contracts[name] != address(0), "ContractsRegistry: This mapping doesn't exist");

        return _contracts[name];
    }    

    function addContract(bytes32 name, address contractAddress) external onlyAdmin {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");        

        _contracts[name] = contractAddress;
    }

    function addProxyContract(bytes32 name, address contractAddress) external onlyAdmin {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");        

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            contractAddress, PROXY_ADMIN, ""
        );

        _contracts[name] = address(proxy);        
    }

    function deleteContract(bytes32 name) external onlyAdmin {
        require(_contracts[name] != address(0), "ContractsRegistry: This mapping doesn't exist");
        
        delete _contracts[name];
    }
}