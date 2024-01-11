// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./Clones.sol";
import "./Ownable.sol";
import "./Address.sol";

interface IProxyContract {
    function initialize(
        address payable _owner,
        string[] memory _stringData,
        uint256[] memory _uintData,
        bool[] memory _boolData,
        address[] memory _addressData
    ) external;
}

interface IRoyaltyManager {
    function getRoyalties(address _contract) external view returns (uint256);

    function royaltyRecipient() external view returns (address);
}

contract CloneFactory is Ownable {
    using Clones for address;

    event ProxyContractCreated(
        address _proxy,
        address _owner,
        string[] _stringData,
        uint256[] _uintData,
        bool[] _boolData,
        address[] _addressData
    );

    address public royaltyManager;

    function createProxyContract(
        string[] memory _stringData,
        uint256[] memory _uintData,
        bool[] memory _boolData,
        address[] memory _addressData,
        uint256 nonce,
        address implementation
    ) external returns (address) {
        address proxy = implementation.cloneDeterministic(keccak256(abi.encodePacked(msg.sender, nonce)));
        IProxyContract(proxy).initialize(payable(msg.sender), _stringData, _uintData, _boolData, _addressData);
        emit ProxyContractCreated(proxy, msg.sender, _stringData, _uintData, _boolData, _addressData);
        return address(proxy);
    }

    function setRoyaltyManager(address _royaltyManager) public onlyOwner {
        royaltyManager = _royaltyManager;
    }

    function getProtocolFeeAndRecipient(address _contract) public view returns (uint256, address) {
        address _protocolFeeRecipient = IRoyaltyManager(royaltyManager).royaltyRecipient();
        uint256 _protocolFee = IRoyaltyManager(royaltyManager).getRoyalties(_contract);

        return (_protocolFee, _protocolFeeRecipient);
    }

    function predictCollectionAddress(uint256 _nonce, address _implementation) external view returns (address) {
        return _implementation.predictDeterministicAddress(keccak256(abi.encodePacked(msg.sender, _nonce)));
    }
}
