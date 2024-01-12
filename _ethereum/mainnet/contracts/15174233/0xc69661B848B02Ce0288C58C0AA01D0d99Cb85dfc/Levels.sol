// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./AccessControlEnumerable.sol";
import "./EnumerableSet.sol";
import "./IFancyBearHoneyConsumption.sol";

contract Levels is AccessControlEnumerable {

    struct ConsumptionData {
        uint256 eth;
        mapping(address => uint256) tokens;
    }

    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    EnumerableSet.AddressSet private approvedCollections;
    EnumerableSet.AddressSet private approvedTokens;

    mapping(address => mapping(uint256 => ConsumptionData)) private consumptionData;

    address public fancyBearContract;
    address public honeyContract;
    IFancyBearHoneyConsumption public honeyConsumptionContract;

    event TokenConsumed(address indexed _collectionAddress, uint256 indexed _collectionTokenId, address indexed _tokenAddress, uint256 _amount);
    event ETHConsumed(address indexed _collectionAddress, uint256 indexed _collectionTokenId, uint256 _amount);
    event CollectionAdded(address indexed _collectionAddress);
    event CollectionRemoved(address indexed _collectionAddress);
    event TokenAdded(address indexed _tokenAddress);
    event TokenRemoved(address indexed _tokenAddress);

    constructor(address _fancyBearContract, address _honeyContract, IFancyBearHoneyConsumption _honeyConsumptionContract) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        fancyBearContract = _fancyBearContract;
        honeyContract = _honeyContract;
        honeyConsumptionContract = _honeyConsumptionContract;
    }

    function addApprovedCollection(address _collectionAddress) public onlyRole(MANAGER_ROLE) {
        approvedCollections.add(_collectionAddress);
        emit CollectionAdded(_collectionAddress);
    }

    function removeApprovedCollection(address _collectionAddress) public onlyRole(MANAGER_ROLE) {
        approvedCollections.remove(_collectionAddress);
        emit CollectionRemoved(_collectionAddress);
    }

    function getApprovedCollections() public view returns (address[] memory) {
        return approvedCollections.values();
    }

    function addApprovedToken(address _tokenAddress) public onlyRole(MANAGER_ROLE) {
        approvedTokens.add(_tokenAddress);
        emit TokenAdded(_tokenAddress);
    }

    function removeApprovedTokens(address _tokenAddress) public onlyRole(MANAGER_ROLE) {
        approvedTokens.remove(_tokenAddress);
        emit TokenRemoved(_tokenAddress);
    }

    function getApprovedTokens() public view returns (address[] memory) {
        return approvedTokens.values();
    }

    function getConsumedToken(address _collectionAddress, uint256 _collectionTokenId, address _tokenAddress) public view returns (uint256) {
        
        require(approvedCollections.contains(_collectionAddress), "getConsumedToken: Not an approved collection");
        require(approvedTokens.contains(_tokenAddress), "getConsumedToken: Not an approved token");

        if(_collectionAddress == fancyBearContract && _tokenAddress == honeyContract){
            return consumptionData[_collectionAddress][_collectionTokenId].tokens[_tokenAddress] + honeyConsumptionContract.honeyConsumed(_collectionTokenId);
        }
        else{
            return consumptionData[_collectionAddress][_collectionTokenId].tokens[_tokenAddress];
        }
    }

    function consumeToken(address _collectionAddress, uint256 _collectionTokenId, address _tokenAddress, uint256 _amount) public onlyRole(CONSUMER_ROLE) {
        
        require(approvedCollections.contains(_collectionAddress), "tokenConsumption: Not an approved collection");
        require(approvedTokens.contains(_tokenAddress), "tokenConsumption: Not an approved token");
        require(_amount > 0, "tokenConsumption: must consume more than 0");

        consumptionData[_collectionAddress][_collectionTokenId].tokens[_tokenAddress] += _amount;

        emit TokenConsumed(_collectionAddress, _collectionTokenId, _tokenAddress, _amount);
    }

    function consumeETH(address _collectionAddress, uint256 _collectionTokenId, uint256 _amount) public onlyRole(CONSUMER_ROLE){
        require(approvedCollections.contains(_collectionAddress), "consumeETH: Not an approved collection");
        require(_amount > 0, "consumeETH: must consume more than 0");

        consumptionData[_collectionAddress][_collectionTokenId].eth += _amount;

        emit ETHConsumed(_collectionAddress, _collectionTokenId, _amount);
    }

    function getTokensConsumed(address _collectionAddress, uint256 _collectionTokenId) public view returns (address[] memory, uint256[] memory, uint256) {
        
        uint256[] memory amounts = new uint256[](approvedTokens.length());
        address[] memory tokenAddresses = new address[](approvedTokens.length());
        
        uint256 i;
        for(;i < approvedTokens.length();){

            tokenAddresses[i] = approvedTokens.at(i);
            amounts[i] = getConsumedToken(_collectionAddress, _collectionTokenId, tokenAddresses[i]);
            
            unchecked{
                i++;
            }

        }

        return (tokenAddresses, amounts, consumptionData[_collectionAddress][_collectionTokenId].eth);
    }

    function getConsumedETH(address _collectionAddress, uint256 _collectionTokenId) public view returns (uint256) {
        return consumptionData[_collectionAddress][_collectionTokenId].eth;
    }

}