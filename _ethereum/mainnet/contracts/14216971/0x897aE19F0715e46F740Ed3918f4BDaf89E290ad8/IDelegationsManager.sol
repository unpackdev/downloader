// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ILazyInitCapableElement.sol";

interface IDelegationsManager is ILazyInitCapableElement {

    event DelegationSet(address indexed delegationAddress, address indexed treasuryAddress);
    event SupportedToken(address indexed collectionAddress, uint256 indexed objectId);
    event Factory(address indexed factory, bool indexed allowed);

    struct DelegationData {
        address location;
        address treasury;
    }

    function split(address executorRewardReceiver) external;

    function supportedToken() external view returns(address collection, uint256 objectId);
    function setSupportedToken(address collection, uint256 tokenId) external;

    function maxSize() external view returns(uint256);
    function setMaxSize(uint256 newValue) external returns (uint256 oldValue);

    function size() external view returns (uint256);
    function list() external view returns (DelegationData[] memory);
    function partialList(uint256 start, uint256 offset) external view returns (DelegationData[] memory);
    function listByAddresses(address[] calldata delegationAddresses) external view returns (DelegationData[] memory);
    function listByIndices(uint256[] calldata indices) external view returns (DelegationData[] memory);

    function exists(address delegationAddress) external view returns(bool result, uint256 index, address treasuryOf);
    function treasuryOf(address delegationAddress) external view returns(address treasuryAddress);

    function get(address delegationAddress) external view returns(DelegationData memory);
    function getByIndex(uint256 index) external view returns(DelegationData memory);

    function set() external;

    function remove(address[] calldata delegationAddresses) external returns(DelegationData[] memory removedDelegations);
    function removeAll() external;

    function executorRewardPercentage() external view returns(uint256);

    function getSplit(address executorRewardReceiver) external view returns (address[] memory receivers, uint256[] memory values);
    function getSituation() external view returns(address[] memory treasuries, uint256[] memory treasuryPercentages);

    function factoryIsAllowed(address factoryAddress) external view returns(bool);
    function setFactoriesAllowed(address[] memory factoryAddresses, bool[] memory allowed) external;

    function isBanned(address productAddress) external view returns(bool);
    function ban(address[] memory productAddresses) external;

    function isValid(address delegationAddress) external view returns(bool);

    event PaidFor(address indexed delegationAddress, address indexed from, address indexed retriever, uint256 amount);

    function paidFor(address delegationAddress, address retriever) external view returns(uint256 totalPaid, uint256 retrieverPaid);
    function payFor(address delegationAddress, uint256 amount, bytes memory permitSignature, address retriever) external payable;
    function retirePayment(address delegationAddress, address receiver, bytes memory data) external;
    function attachInsurance() external view returns (uint256);
    function setAttachInsurance(uint256 value) external returns (uint256 oldValue);
}