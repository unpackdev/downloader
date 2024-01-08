// SPDX-License-Identifier: AGPLV3
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Whitelist.sol";

/// @notice Registry for holding gro protocol contract information on chain
/// *****************************************************************************
/// The registry allows for external entities to verfiy what contracts are active
/// and at which point a contract was deactivated/activated. This will simplify
/// the tracking of statistics for bots etc. Additional meta data can be attached
/// to each contract.
/// *****************************************************************************
/// Contract storage:
///     Deployed contract addresses are stored in an array inside a mapping which
///     key is the name of the contract type, e.g.
///         "VaultAdapter" => ['0x...', '0x...', ...]
///     Each address is in turn mapped to a contract data struct that holds infromation 
///     regarding the contract, e.g.
///         '0x...' => {deployedBlock: x, startBlock: [x, y], endBlock: [z]...}
///
/// Contract data:
///     The following data fields are defined inside the contract data struct:
///        deployedBlock - Which block was deployed
///        startBlock - Array containing the blocks in which the contract was set to active
///        uint256[] endBlock - Array containing the blocks in which the contract was set to inactive
///        string abiVersion - Hash of commit used for the contract deployment
///        string tag - Inidication of what type of contract it is (core, strategy etc)
///        string metaData - additional data used by external actors, provided as a JSON string 
///        string tokens - token exposures if any (matches entries form the tokens array and tokenMap)
///        string protocols - protocol exposure if any (matches entries from the protocols array and protocolMap)
///        bool active - If this contract is the active one, there can only be one active contract per
///         contract group.
///
/// Additional data:
///     The contract contains data regarding exposures (protocols/tokens) that are used to assist 
///     external actors. This data is stored in arrays where the index of item in the array will be
///     used to reference the protocols/tokens in the meta data. The index of a protocol/token can
///     be retrieved by using the protocolMap/tokenMap, a return value of 0 indicates that its
///     not present in the registry.
contract Registry is Whitelist {

    struct contractData {
        uint256 deployedBlock;
        uint256[] startBlock;
        uint256[] endBlock;
        string abiVersion;
        string tag;
        string metaData;
        uint256[] tokens;
        uint256[] protocols;
        bool active;
    }

    mapping(string => address[]) contractMap;
    mapping(address => contractData ) contractInfo;

    mapping(string => bool) activeKey;
    mapping(string => uint256) protocolMap;
    mapping(address => uint256) tokenMap;

    string[] keys;
    string[] protocols;
    address[] tokens;

    event LogNewContract(string indexed contractName, address indexed contractAddress, bool contractTypeActivated);
    event LogNewProtocol(string indexed protocol, uint256 index);
    event LogNewToken(address indexed token, uint256 index);
    event LogAddTokenExposure(address indexed _contract, address[] token);
    event LogAddProtocolExposure(address indexed _contract, string[] protocol);
    event LogRemovedContract(string indexed contractName, address indexed contractAddress);
    event LogContractActivated(string indexed contractName, address indexed contractActivated, address contractDeactivated);
    event LogForceUpdate(address indexed contractAddress,  uint256 _deployed, uint256 _startBlock, uint256 _endBlock);
    event LogForceUpdateMeta(address contractAddress, string _abiVersion, string _tag, string _metaData);

    /// @notice returns a list of active Contract keys in the registry
    /// @dev if there are no deployed contracts associated with the key,
    ///     it wont be displayed but rather returned as an empty string
    function getKeys() external view returns (string[] memory) {
        uint256 keyLength = keys.length; 
        string[] memory _keys = new string[](keyLength);
        uint256 j;
        for (uint256 i; i < keyLength; i++) {
            if (contractMap[keys[i]].length != 0) {
                _keys[j] = keys[i];
                j++;
            }
        }
        return _keys;
    }

    function getProtocol(uint256 index) external view returns (string memory) {
        require(protocols.length > 1, 'getProtocol: No protocols added');
        require(index > 0, 'getProtocol: index = 0');
        return protocols[index - 1];
    }

    function getToken(uint256 index) external view returns (address) {
        require(tokens.length > 1, 'getToken: No tokens added');
        require(index > 0, 'getProtocol: index = 0');
        return tokens[index - 1];
    }

    /// @notice Add token exposures to contract
    /// @param contractAddress contract to add exposures to
    /// @param tokenAddresses addresses of tokens the contract is exposed to
    /// @dev providing an empty list removes all token exposures from the contract
    function addTokenExposures(address contractAddress, address[] calldata tokenAddresses) external onlyWhitelist {
        if (tokenAddresses.length > 0) {
            uint256[] memory indexes = convertToTokenIndexs(tokenAddresses);
            delete contractInfo[contractAddress].tokens;
            contractInfo[contractAddress].tokens = indexes;
        } else {
            delete contractInfo[contractAddress].tokens;
        }
        emit LogAddTokenExposure(contractAddress, tokenAddresses);
    }

    /// @notice Add protocol exposures to contract
    /// @param contractAddress contract to add exposures to
    /// @param protocolNames addresses of protocol the contract is exposed to
    /// @dev providing an empty list removes all protocol exposures from the contract
    function addProtocolExposures(address contractAddress, string[] calldata protocolNames) external onlyWhitelist {
        if (protocolNames.length > 0) {
            uint256[] memory indexes = convertToProtocolIndexs(protocolNames);
            delete contractInfo[contractAddress].protocols;
            contractInfo[contractAddress].protocols = indexes;  
        } else {
            delete contractInfo[contractAddress].protocols;
        }
        emit LogAddProtocolExposure(contractAddress, protocolNames);
    }

    function convertToTokenIndexs(address[] calldata tokenAddresses) public view returns(uint256[] memory) {
        uint256 length = tokenAddresses.length;
        uint256[] memory tokenIndexes = new uint256[](length);
        for(uint256 i; i < length; i++) {
            require(tokenMap[tokenAddresses[i]] != 0, 'convertToTokenIndexs: token not registred');
            tokenIndexes[i] = tokenMap[tokenAddresses[i]];
        }
        return tokenIndexes;
    }

    function convertToProtocolIndexs(string[] calldata protocolNames) public view returns(uint256[] memory) {
        uint256 length = protocolNames.length;
        uint256[] memory protocolIndexes = new uint256[](length);
        for(uint256 i; i < length; i++) {
            require(protocolMap[protocolNames[i]] != 0, 'convertToProtocolIndexs: protocol not registred');
            protocolIndexes[i] = protocolMap[protocolNames[i]];
        }
        return protocolIndexes;
    }

    /// @notice Add a new deployed contract to the registry
    /// @param contractName The Contract type (Controller, WithdrawHandler, DaiVaultAdapter etc)
    /// @param contractAddress Address of the deployed contract
    /// @param _deployed BlockNumber the contract was deployed
    /// @param _abiVersion Hash of commit used for contract deployment
    /// @param _tag Indicator of the contract type
    /// @dev New contractNames will be added to the keys list
    function newContract(string calldata contractName, address contractAddress, uint256 _deployed, string calldata _abiVersion, string calldata _tag) external onlyWhitelist {
        require(contractInfo[contractAddress].deployedBlock == 0, 'newContract: Already in registry');

        bool newContractType;
        contractMap[contractName].push(contractAddress);
        contractInfo[contractAddress].deployedBlock = _deployed;  
        contractInfo[contractAddress].abiVersion = _abiVersion;  
        contractInfo[contractAddress].tag = _tag;  
        contractInfo[contractAddress].active = false;  
        if (!activeKey[contractName]) {
            newContractType = true;
            activeKey[contractName] = true;
            keys.push(contractName);
        }
        emit LogNewContract(contractName, contractAddress, newContractType);
    }
    /// @notice Add a new protocol to the registry
    /// @param _protocol Protocol name
    function addProtocol(string calldata _protocol) external onlyWhitelist {
        require(protocolMap[_protocol] == 0, 'addProtocol: protocol already added');
        protocols.push(_protocol);
        uint256 position = protocols.length;
        protocolMap[_protocol] = position;
        emit LogNewProtocol(_protocol, position);
    }

    /// @notice Add a new token to the registry
    /// @param _token Token address
    function addToken(address _token) external onlyWhitelist {
        require(tokenMap[_token] == 0, 'addToken: token already added');
        tokens.push(_token);
        uint256 position = tokens.length;
        tokenMap[_token] = position;
        emit LogNewToken(_token, position);
    }

    /// @notice Pop last added contract from the contractMap array, removing all associated data
    function removeContract(string calldata contractName) external onlyWhitelist {
        address[] memory contracts = contractMap[contractName];
        require(contracts.length > 0, 'removeContract: No deployed contracts');
        address _contract = contracts[contracts.length - 1];
        contractMap[contractName].pop();
        contractInfo[_contract].deployedBlock = 0;  
        contractInfo[_contract].abiVersion = "";  
        contractInfo[_contract].tag = "";  
        contractInfo[_contract].metaData = "";
        contractInfo[_contract].active = false;
        delete contractInfo[_contract].tokens;
        delete contractInfo[_contract].protocols;

        emit LogRemovedContract(contractName, _contract);
    }

    /// @notice Force an update of contract information
    /// @param contractAddress Address of the deployed contract
    /// @param _deployed Block number the contract was deployed
    /// @param _startBlock Block number the contract was activated
    /// @param _endBlock block number the contract was deactivated
    /// @dev start/end blocks of 0 will skip updating those fields, will otherwise pop and replace last value
    function forceUpdate(address contractAddress, uint256 _deployed, uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].deployedBlock = _deployed;  
        if (_startBlock > 0) {
            contractInfo[contractAddress].startBlock.pop();  
            contractInfo[contractAddress].startBlock.push(_startBlock);  
        }
        if (_endBlock > 0) {
            contractInfo[contractAddress].endBlock.pop();  
            contractInfo[contractAddress].endBlock.push(_endBlock);
        }
        emit LogForceUpdate(contractAddress,  _deployed, _startBlock, _endBlock);
    }

    /// @notice Force an updated of contract meta data, effectively overwritting old values
    /// @param contractAddress Address of the deployed contract
    /// @param _abiVersion New ABI version
    /// @param _tag New tag
    /// @param _metaData new MetaData
    function forceUpdateMeta(address contractAddress, string calldata _abiVersion, string calldata _tag, string calldata _metaData) external onlyOwner {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].abiVersion = _abiVersion;  
        contractInfo[contractAddress].tag = _tag;  
        contractInfo[contractAddress].metaData = _metaData;  
        emit LogForceUpdateMeta(contractAddress, _abiVersion, _tag, _metaData);
    }

    /// @notice Designate a new contract as active, disabling the last active one 
    /// @param _contractName Contract group name
    /// @param _contractAddress Address of contract to start
    /// @param _startBlock Block this contract was activated
    function activateContract(string calldata _contractName, address _contractAddress, uint256 _startBlock) external onlyWhitelist {
        address[] memory contracts = contractMap[_contractName];
        uint256 contractLength = contracts.length;
        require(contractLength > 0, 'No addresses for contracts');
        address deactivated;
        bool newActiveExists;
        for(uint256 i; i < contractLength; i++) {
            if (contracts[i] == _contractAddress) {
                newActiveExists = true;
            }
            if (contractInfo[contracts[i]].active) {
                require(contracts[i] != _contractAddress, 'activateContract: !Already active');
                deactivated = contracts[i];
                contractInfo[contracts[i]].active = false;
                contractInfo[contracts[i]].endBlock.push(_startBlock);  
            }
        }
        require(newActiveExists, 'activateContract: contract not added to group'); 
        contractInfo[_contractAddress].startBlock.push(_startBlock);  
        contractInfo[_contractAddress].active = true;
        emit LogContractActivated(_contractName, _contractAddress, deactivated);
    }

    /// @notice Add meta data to contract
    /// @param contractAddress Address of target contract
    /// @param _metaData Meta data JSON string
    function setMetaData(address contractAddress, string calldata _metaData) external onlyWhitelist {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].metaData = _metaData;  
    }

    /// @notice Get all deployed contracts in a contract type group
    /// @param contractName Contract type name
    function getContractMap(string calldata contractName) external view returns (address[] memory) {
        return contractMap[contractName];
    }

    /// @notice Get the contract data of the last added contract in a contract type group
    /// @param contractName Contract type name
    function getLatestData(string calldata contractName) external view returns (contractData memory data) {
        address[] memory contracts = contractMap[contractName];
        uint256 contractLength = contracts.length;
        if (contractLength > 0) {
            return contractInfo[contracts[contractLength - 1]];
        }
        return contractInfo[address(0)];
    }

    /// @notice Get the contract data of the last added contract in a contract type group
    /// @param contractName Contract type name
    function getLatest(string calldata contractName) external view returns (address) {
        return contractMap[contractName][contractMap[contractName].length - 1];
    }

    /// @notice Get the contract data of the active contract in a contract type group
    /// @param contractName Contract type name
    function getActiveData(string calldata contractName) external view returns (contractData memory data) {
        address[] memory contracts = contractMap[contractName];
        for(uint256 i; i < contracts.length; i++) {
            if (contractInfo[contracts[i]].active) {
                return contractInfo[contracts[i]];
            }
        }
        return contractInfo[address(0)];
    }

    /// @notice Get the address of the active contract in a contract type group
    /// @param contractName Contract type name
    function getActive(string calldata contractName) external view returns (address) {
        address[] memory contracts = contractMap[contractName];
        for(uint256 i; i < contracts.length; i++) {
            if (contractInfo[contracts[i]].active) {
                return contracts[i];
            }
        }
        return address(0);
    }

    /// @notice Get data for specified contract
    /// @param contractAddress Address of the deployed contract
    function getContractData(address contractAddress) external view returns (contractData memory) {
        return contractInfo[contractAddress];
    }
}
