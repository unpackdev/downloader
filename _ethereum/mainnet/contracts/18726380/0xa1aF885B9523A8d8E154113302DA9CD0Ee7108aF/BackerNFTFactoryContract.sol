// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ECDSA.sol";
import "./BackerNFT.sol";

contract BackerNFTFactoryContract {
    using ECDSA for bytes32;
    
    struct BackerNFTConstructor {
        string baseUri;
        string collectionName;
        string collectionSymbol;
        address minter;
        bool transferable;
    }
    
    event ContractCreated(string id, address indexed campaignOwner, address newContract, BackerNFTConstructor backerNFTConstructor, uint256 timestamp);

    address[] private deployedContract;
    address private adminVerifier;
    address private owner = msg.sender;
    mapping(string => bool) private excutedOrderIds;

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }

    constructor(address _adminVerifier) {
        adminVerifier = _adminVerifier;
    }

    function setAdminVerifier(address _adminVerifier) external onlyOwner {
        adminVerifier = _adminVerifier;
    }

    function createContract(
        BackerNFTConstructor calldata _backerNFTConstructor,
        bytes calldata _signature,
        string calldata _orderId,
        string calldata _id
    ) external {
        require(!excutedOrderIds[_orderId], "Order is excuted");
        require(
            _validateSignature(
                _signature,
                _orderId,
                msg.sender,
                _backerNFTConstructor
            ), "Invalid signature");
        excutedOrderIds[_orderId] = true;

        BackerNFT newContract = new BackerNFT(
            _backerNFTConstructor.collectionName,
            _backerNFTConstructor.collectionSymbol,
            _backerNFTConstructor.minter,
            msg.sender,
            _backerNFTConstructor.baseUri,
            _backerNFTConstructor.transferable
        );
        deployedContract.push(address(newContract));

        emit ContractCreated(
            _id,
            msg.sender,
            address(newContract), 
            _backerNFTConstructor,
            block.timestamp
        );
    }

    function getDeployedContract(uint256 _index) external view returns (address) {
        return deployedContract[_index];
    }

    function allDeployedContractLength() external view returns (uint256) {
        return deployedContract.length;
    }

    function _validateSignature(
        bytes calldata _signature,
        string calldata _orderId,
        address _campaignOwner,
        BackerNFTConstructor calldata _backerNFTConstructor
    ) private view returns (bool) {
        bytes32 hashValue = keccak256(
            abi.encodePacked(
                _orderId,
                _campaignOwner,
                _backerNFTConstructor.transferable,
                _backerNFTConstructor.minter,
                _backerNFTConstructor.baseUri,
                _backerNFTConstructor.collectionName,
                _backerNFTConstructor.collectionSymbol
            )
        );
        address recover = hashValue.toEthSignedMessageHash().recover(_signature);
        return recover == adminVerifier;
    }
}