// SPDX-License-Identifier: MIT

// ██╗░░░██╗░█████╗░██╗░░░░░░█████╗░██████╗░██╗███████╗███████╗
// ██║░░░██║██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║╚════██║██╔════╝
// ╚██╗░██╔╝███████║██║░░░░░██║░░██║██████╔╝██║░░███╔═╝█████╗░░
// ░╚████╔╝░██╔══██║██║░░░░░██║░░██║██╔══██╗██║██╔══╝░░██╔══╝░░
// ░░╚██╔╝░░██║░░██║███████╗╚█████╔╝██║░░██║██║███████╗███████╗
// ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝░╚════╝░╚═╝░░╚═╝╚═╝╚══════╝╚══════╝

// ██████╗░███████╗██████╗░██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░
// ██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗
// ██║░░██║█████╗░░██████╔╝██║░░░░░██║░░██║░╚████╔╝░█████╗░░██████╔╝
// ██║░░██║██╔══╝░░██╔═══╝░██║░░░░░██║░░██║░░╚██╔╝░░██╔══╝░░██╔══██╗
// ██████╔╝███████╗██║░░░░░███████╗╚█████╔╝░░░██║░░░███████╗██║░░██║
// ╚═════╝░╚══════╝╚═╝░░░░░╚══════╝░╚════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

pragma solidity 0.8.14;
import "./AccessControl.sol";

contract Deployer is AccessControl{
    struct DeployedContractInfo {
        address deploymentAddress;
        string  contractType;
    }
    struct ContractDeployParameters {
        bytes32 byteCodeHash;
        uint    price;
    }
    mapping(string => ContractDeployParameters) contractParamsByKey;
    mapping(address => DeployedContractInfo[])  contractsDeloyedByEOA;

    event ByteCodeUploaded(string key, uint price, bytes32 byteCodeHash);
    event PriceUpdated(string key, uint newPrice);
    event ContractDiscontinued(string key);
    event ContractDeployed(address contractAddress, string contractType, uint paid);

    /*
     * @dev Deploys a contract and returns the address of the deployed contract
     * @param _admin The address that can call the admin functions
     * @return The address of the deployed contract
     */
    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /*
     * @dev Deploys a contract and returns the address of the deployed contract
     * @param contractType The key to get the bytecode of the contract
     * @param bytecode     The bytecode of the contract to deploy
     * @param params       Bytecode of the constructor parameters (if any) of the contract to deploy
     * @param salt         Salt to be used to generate the hash of the contract bytecode 
     *                     (used to generate a deterministic address)
     */
    function deployContract(
        string calldata contractType,
        bytes calldata bytecode,
        bytes calldata params,
        bytes32 salt
    ) external payable {
        (bool success, ContractDeployParameters memory c) = getContractByteCodeHash(contractType);
        if (!success || c.byteCodeHash != keccak256(bytecode)) {
            revert("Contract is unregistered or discontinued");
        }
        require(
            msg.value >= c.price,
            "Insufficient payment to deploy"
        );
        if(salt == 0x0) {
            salt = keccak256(abi.encode(getDeployed(msg.sender).length));
        }
        bytes memory code = abi.encodePacked(
            bytecode,
            params
        );
        address contractAddress;
        assembly {
            contractAddress := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(contractAddress)) {
                revert(0, "Error deploying contract")
            }
        }
        DeployedContractInfo memory ci = DeployedContractInfo(contractAddress, contractType);
        contractsDeloyedByEOA[msg.sender].push(ci);
        emit ContractDeployed(contractAddress, contractType, msg.value);
    }

    /*
     * @dev Returns contract info deployed by the given address
     * @param deployer address to lookup
     * @return array of contracts deployed by deployer
     */
    function getDeployed(address deployer)
        public
        view
        returns (DeployedContractInfo[] memory contractsDeployed)
    {
        contractsDeployed = contractsDeloyedByEOA[deployer];
    }

    /*
     * @dev Gets the bytecode of a contract by name
     * @param contractKey The key used to reference the contract
     * @returns boolean flag and the contract info
     */
    function getContractByteCodeHash(string calldata contractKey)
        public
        view
        returns (bool success, ContractDeployParameters memory contractParams)
    {
        contractParams = contractParamsByKey[contractKey];
        if(contractParams.byteCodeHash.length == 0) {
            return (false, contractParams);
        }
        return (true, contractParams);
    }

    /*
     * @dev Sets the bytecode of a contract by name
     * @param contractKey The key which must be used to access the bytecode
     * @param bytecode The bytecode to store
     * @param contractDeployPrice The price (in wei) that users must pay to deploy a contract
     */
    function setContractByteCode(
        string calldata contractKey,
        bytes calldata byteCode,
        uint contractDeployPrice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (contractParamsByKey[contractKey].byteCodeHash == 0x0) {
            contractParamsByKey[contractKey] = ContractDeployParameters(
                keccak256(byteCode), 
                contractDeployPrice
            );
            emit ByteCodeUploaded(contractKey, contractDeployPrice, keccak256(byteCode));
        } else {
            revert("Contract already deployed");
        }
    }

    /*
     * @dev Updates the price of a contract
     * @param contractKey The key used to reference the contract
     * @param newPrice The new price (in wei) that users must pay to deploy the contract
     */
    function updateContractPrice(
        string calldata contractKey,
        uint newPrice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ContractDeployParameters memory contractParams = contractParamsByKey[contractKey];
        if (contractParams.byteCodeHash != 0x0) {
            contractParamsByKey[contractKey] = ContractDeployParameters(contractParams.byteCodeHash, newPrice);
            emit PriceUpdated(contractKey, newPrice);
        } else {
            revert("Contract not registered");
        }
    }

    /*
     * @dev Makes a contract undeployable
     * @param contractKey The key used to reference the contract
     */
    function discontinueContract(
        string calldata contractKey
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ContractDeployParameters memory contractParams = contractParamsByKey[contractKey];
        if (contractParams.byteCodeHash != 0x0) {
            contractParamsByKey[contractKey] = ContractDeployParameters(0x0, 0x0);
            emit ContractDiscontinued(contractKey);
        } else {
            revert("Contract not registered");
        }
    }


    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(address(msg.sender)).transfer(address(this).balance);
    }
}
