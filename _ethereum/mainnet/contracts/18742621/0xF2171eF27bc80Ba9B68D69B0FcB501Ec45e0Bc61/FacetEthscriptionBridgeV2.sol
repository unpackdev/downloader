// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ECDSA.sol";
import "./EIP712.sol";
import "./LibString.sol";
import "./ERC1967FactoryConstants.sol";

contract FacetEthscriptionBridgeV2 is EIP712 {
    using LibString for *;
    using ECDSA for bytes32;
    
    event ethscriptions_protocol_TransferEthscriptionForPreviousOwner(
        address indexed previousOwner,
        address indexed recipient,
        bytes32 indexed id
    );

    event ethscriptions_protocol_CreateEthscription(
        address indexed initialOwner,
        string contentURI
    );
    
    struct WithdrawRequest {
        address recipient;
        bytes32[] ethscriptionIds;
        bytes32 withdrawalId;
        bytes32 blockHash;
        uint256 blockNumber;
        bytes signature;
    }
    
    struct DepositConfirmation {
        address sender;
        bytes32[] ethscriptionIds;
        bytes32 depositId;
        bytes32 blockHash;
        uint256 blockNumber;
        bytes signature;
    }

    struct BridgeStorage {
        mapping(bytes32 => bool) processedWithdrawalIds;
        bool depositEnabled;
        bool withdrawEnabled;
        address adminAddress;
        address signerAddress;
        address dumbContractAddress;
        uint256 cancelBlockNumber;
        mapping(address => bytes32[]) pendingDeposits;
        mapping(bytes32 => bool) processedDepositIds;
        uint256 withdrawDelay;
    }
    
    function s() internal pure returns (BridgeStorage storage cs) {
        bytes32 position = keccak256("BridgeStorage.contract.storage.v1");
        assembly {
           cs.slot := position
        }
    }
    
    modifier onlyAdmin() {
        require(msg.sender == s().adminAddress, "Not admin");
        _;
    }

    function withdraw(
        WithdrawRequest calldata req
    ) external {
        require(s().withdrawEnabled, "Withdraw not enabled");

        bytes32 hashedMessage = _hashTypedData(keccak256(abi.encode(
            keccak256(
                "Withdraw(address recipient,address dumbContract,bytes32[] ethscriptionIds,"
                "bytes32 withdrawalId,bytes32 blockHash,uint256 blockNumber)"
            ),
            req.recipient,
            s().dumbContractAddress,
            keccak256(abi.encodePacked(req.ethscriptionIds)),
            req.withdrawalId,
            req.blockHash,
            req.blockNumber
        )));

        address signer = hashedMessage.recoverCalldata(req.signature);

        require(signer == s().signerAddress, "Invalid signature");
        require(!s().processedWithdrawalIds[req.withdrawalId], "Already processed");
        require(s().cancelBlockNumber <= req.blockNumber, "Signature canceled");
        require(block.number >= req.blockNumber + s().withdrawDelay, "Withdraw delay");
        require(req.blockHash == bytes32(0) || blockhash(req.blockNumber) == req.blockHash, "Invalid block number or hash");

        s().processedWithdrawalIds[req.withdrawalId] = true;

        for (uint i = 0; i < req.ethscriptionIds.length;) {
            bytes32 ethscriptionId = req.ethscriptionIds[i];
            emit ethscriptions_protocol_TransferEthscriptionForPreviousOwner(req.recipient, req.recipient, ethscriptionId);

            unchecked {
                i += 1;
            }
        }

        string memory out = string.concat(
            'data:application/vnd.facet.tx+json;rule=esip6,{"op":"call","data":{"to":"',
            s().dumbContractAddress.toHexString(),
            '","function":"markWithdrawalComplete","args":{"to":"',
            req.recipient.toHexString(),
            '","withdrawalId":"',
            uint256(req.withdrawalId).toHexString(32),
            '"}}}'
        );
        
        emit ethscriptions_protocol_CreateEthscription(0x00000000000000000000000000000000000FacE7, string(out));
    }

    function confirmDeposit(
        DepositConfirmation calldata deposit
    ) external {
        require(s().depositEnabled, "Deposit not enabled");

        bytes32 hashedMessage = _hashTypedData(keccak256(abi.encode(
            keccak256(
                "DepositConfirmation(address sender,address dumbContract,bytes32[] ethscriptionIds,"
                "bytes32 depositId,bytes32 blockHash,uint256 blockNumber)"
            ),
            deposit.sender,
            s().dumbContractAddress,
            keccak256(abi.encodePacked(deposit.ethscriptionIds)),
            deposit.depositId,
            deposit.blockHash,
            deposit.blockNumber
        )));

        address signer = hashedMessage.recoverCalldata(deposit.signature);

        require(signer == s().signerAddress, "Invalid signature");
        require(!s().processedDepositIds[deposit.depositId], "Already processed");
        require(s().cancelBlockNumber <= deposit.blockNumber, "Signature canceled");
        require(deposit.blockHash == bytes32(0) || blockhash(deposit.blockNumber) == deposit.blockHash, "Invalid block number or hash");
        require(
            keccak256(abi.encodePacked(s().pendingDeposits[deposit.sender])) == keccak256(abi.encodePacked(deposit.ethscriptionIds)),
            "Invalid deposits"
        );
        
        delete s().pendingDeposits[deposit.sender];
        s().processedDepositIds[deposit.depositId] = true;

        bytes memory out = abi.encodePacked(
            'data:application/vnd.facet.tx+json;rule=esip6,{"op":"call","data":{"to":"',
            s().dumbContractAddress.toHexString(),
            '","function":"bridgeIn","args":{"to":"',
            deposit.sender.toHexString(),
            '", "amount":"',
            deposit.ethscriptionIds.length.toString(),
            '"}}}'
        );
        
        emit ethscriptions_protocol_CreateEthscription(0x00000000000000000000000000000000000FacE7, string(out));
    }
    
    function setWithdrawEnabled(bool enabled) external onlyAdmin {
        s().withdrawEnabled = enabled;
    }
    
    function setDepositEnabled(bool enabled) external onlyAdmin {
        s().depositEnabled = enabled;
    }

    function enableAllFeatures() external onlyAdmin {
        s().depositEnabled = true;
        s().withdrawEnabled = true;
    }
    
    function disableAllFeatures() external onlyAdmin {
        s().depositEnabled = false;
        s().withdrawEnabled = false;
    }
    
    function cancelSignatures() external onlyAdmin {
        s().cancelBlockNumber = block.number;
    }
    
    function setDumbContract(address dumbContract) external onlyAdmin {
        s().dumbContractAddress = dumbContract;
    }
    
    function setSigner(address signer) external onlyAdmin {
        s().signerAddress = signer;
    }
    
    function setAdmin(address admin) external onlyAdmin {
        s().adminAddress = admin;
    }
    
    function setWithdrawDelay(uint256 withdrawDelay) external onlyAdmin {
        s().withdrawDelay = withdrawDelay;
    }

    function pendingDeposits(address sender) external view returns (bytes32[] memory) {
        return s().pendingDeposits[sender];
    }
    
    fallback() external {
        require(msg.data.length % 32 == 0 && msg.data.length > 0, "Invalid concatenated hashes length");
        require(s().depositEnabled, "Deposit not enabled");
        require(s().pendingDeposits[msg.sender].length == 0, "Existing pending deposit");
        
        for (uint256 i = 0; i < msg.data.length / 32; i++) {
            bytes32 ethscriptionId = abi.decode(msg.data[i*32:(i+1)*32], (bytes32));
            s().pendingDeposits[msg.sender].push(ethscriptionId);
        }
    }
    
    function adminMarkComplete(address recipient, bytes32 withdrawalId) external onlyAdmin {
        string memory out = string.concat(
            'data:application/vnd.facet.tx+json;rule=esip6,{"op":"call","data":{"to":"',
            s().dumbContractAddress.toHexString(),
            '","function":"markWithdrawalComplete","args":{"to":"',
            recipient.toHexString(),
            '","withdrawalId":"',
            uint256(withdrawalId).toHexString(32),
            '"}}}'
        );
        
        emit ethscriptions_protocol_CreateEthscription(0x00000000000000000000000000000000000FacE7, string(out));
    }
    
    function getSigner() external view returns (address) {
        return s().signerAddress;
    }
    
    function getAdmin() external view returns (address) {
        return s().adminAddress;
    }
    
    function getWithdrawDelay() external view returns (uint256) {
        return s().withdrawDelay;
    }
    
    function getDumbContract() external view returns (address) {
        return s().dumbContractAddress;
    }
    
    function getCancelBlockNumber() external view returns (uint256) {
        return s().cancelBlockNumber;
    }
    
    function getDepositEnabled() external view returns (bool) {
        return s().depositEnabled;
    }
    
    function getWithdrawalEnabled() external view returns (bool) {
        return s().depositEnabled;
    }
    
    function processedWithdraws(bytes32 withdrawalId) external view returns (bool) {
        return s().processedWithdrawalIds[withdrawalId];
    }
    
    function processedDepositIds(bytes32 depositId) external view returns (bool) {
        return s().processedDepositIds[depositId];
    }

    function _domainNameAndVersion() 
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "Facet Ethscription ERC20 Bridge";
        version = "1";
    }
}
