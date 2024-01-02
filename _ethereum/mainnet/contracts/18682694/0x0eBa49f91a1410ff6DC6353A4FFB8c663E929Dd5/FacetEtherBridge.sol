// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SafeTransferLib.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./LibString.sol";
import "./ERC1967FactoryConstants.sol";
import "./ReentrancyGuard.sol";

contract FacetEtherBridge is ReentrancyGuard, EIP712 {
    using LibString for *;
    using SafeTransferLib for address;
    using ECDSA for bytes32;

    error FeatureDisabled();
    error InvalidAmount();
    error NotFactory();
    error ZeroAdminAddress();

    event ethscriptions_protocol_CreateEthscription(
        address indexed initialOwner,
        string contentURI
    );

    struct WithdrawRequest {
        address recipient;
        uint256 amount;
        bytes32 withdrawalId;
        bytes32 blockHash;
        uint256 blockNumber;
        bytes signature;
    }
    
    struct BridgeStorage {
        mapping(bytes32 => bool) processedWithdraws;
        bool depositEnabled;
        bool withdrawEnabled;
        address adminAddress;
        address signerAddress;
        address dumbContractAddress;
        uint256 cancelBlockNumber;
        uint256 withdrawDelay;
    }
    
    function s() internal pure returns (BridgeStorage storage cs) {
        bytes32 position = keccak256("BridgeStorage.contract.storage.v1");
        assembly {
           cs.slot := position
        }
    }
    
    function initialize(
        address adminAddress,
        address signerAddress
    ) external {
        if (msg.sender != ERC1967FactoryConstants.ADDRESS) revert NotFactory();
        if (adminAddress == address(0)) revert ZeroAdminAddress();
        
        s().adminAddress = adminAddress;
        s().signerAddress = signerAddress;
        s().withdrawDelay = 36000;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == s().adminAddress, "Not admin");
        _;
    }
    
    function deposit() public payable {
        if (!s().depositEnabled) revert FeatureDisabled();

        uint256 amount = msg.value;
        address recipient = msg.sender;

        if (amount == 0) revert InvalidAmount();
        
        bytes memory out = abi.encodePacked(
            'data:application/vnd.facet.tx+json;rule=esip6,{"op":"call","data":{"to":"',
            s().dumbContractAddress.toHexString(),
            '","function":"bridgeIn","args":{"to":"',
            recipient.toHexString(),
            '","amount":"',
            amount.toString(),
            '"}}}'
        );
        
        emit ethscriptions_protocol_CreateEthscription(0x00000000000000000000000000000000000FacE7, string(out));
    }

    function withdraw(
        WithdrawRequest calldata req
    ) external nonReentrant {
        require(s().withdrawEnabled, "Withdraw disabled");

        bytes32 hashedMessage = _hashTypedData(keccak256(abi.encode(
            keccak256(
                "Withdraw(address recipient,address dumbContract,uint256 amount,"
                "bytes32 withdrawalId,bytes32 blockHash,uint256 blockNumber)"
            ),
            req.recipient,
            s().dumbContractAddress,
            req.amount,
            req.withdrawalId,
            req.blockHash,
            req.blockNumber
        )));

        address signer = hashedMessage.recoverCalldata(req.signature);

        require(signer == s().signerAddress, "Invalid signature");
        require(!s().processedWithdraws[req.withdrawalId], "Already processed");
        require(s().cancelBlockNumber <= req.blockNumber, "Signature canceled");
        require(block.number >= req.blockNumber + s().withdrawDelay, "Withdraw delay");
        require(req.blockHash == bytes32(0) || blockhash(req.blockNumber) == req.blockHash, "Invalid block number or hash");

        s().processedWithdraws[req.withdrawalId] = true;

        req.recipient.forceSafeTransferETH(req.amount);

        string memory out = string.concat(
            'data:application/vnd.facet.tx+json;rule=esip6,{"op":"call","data":{"to":"',
            s().dumbContractAddress.toHexString(),
            '","function":"markWithdrawalComplete","args":{"to":"',
            req.recipient.toHexString(),
            '","withdrawalId":"',
            uint256(req.withdrawalId).toHexString(),
            '"}}}'
        );
        
        emit ethscriptions_protocol_CreateEthscription(0x00000000000000000000000000000000000FacE7, string(out));
    }
    
    receive() external payable {
        deposit();
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

    function _domainNameAndVersion() 
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "Facet Ether Bridge";
        version = "1";
    }
}