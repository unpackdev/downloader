// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeTransferLib.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./LibString.sol";
import "./ERC1967FactoryConstants.sol";

contract FacetCardReserver is EIP712 {
    using LibString for *;
    using SafeTransferLib for address;
    using ECDSA for bytes32;
    
    event ethscriptions_protocol_CreateEthscription(
        address indexed initialOwner,
        string contentURI
    );
    
    struct CardReserverStorage {
        mapping(string => bool) takenNames;
        uint256 previousNameId;
        address adminAddress;
        address signerAddress;
        uint256 cancelBlockNumber;
    }
    
    function s() internal pure returns (CardReserverStorage storage cs) {
        bytes32 position = keccak256("CardReserverStorage");
        assembly {
           cs.slot := position
        }
    }
    
    function initialize(
        address adminAddress,
        address signerAddress
    ) external {
        require(msg.sender == ERC1967FactoryConstants.ADDRESS, "Not factory");
        require(adminAddress != address(0), "No zero address");
        
        s().adminAddress = adminAddress;
        s().signerAddress = signerAddress;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == s().adminAddress, "Not admin");
        _;
    }
    
    function reserveName(
        string calldata requestedName,
        uint256 duration,
        uint256 cost,
        bytes calldata signature
    ) external payable {
        bytes32 hashedMessage = _hashTypedData(keccak256(abi.encode(
            keccak256(
                "Preregistration(string name,uint256 duration,uint256 cost)"
            ),
            keccak256(bytes(requestedName)),
            duration,
            cost
        )));
        
        address signer = hashedMessage.recoverCalldata(signature);

        require(signer == s().signerAddress, "Invalid signature");
        require(s().cancelBlockNumber <= block.number, "Signature canceled");
        
        require(msg.value == cost, "Invalid payment amount");
        require(!s().takenNames[requestedName], "Name taken");
        
        s().takenNames[requestedName] = true;
        
        uint256 currentId = s().previousNameId + 1;
        s().previousNameId += 1;
        
        string memory out = string.concat(
            'data:', requestedName, '/', msg.sender.toHexString(), ';rule=esip6,',
            '{"name":"', requestedName,
            '","owner":"', msg.sender.toHexString(),
            '","duration":', duration.toString(),
            ',"id":', currentId.toString(),
            '}'
        );

        emit ethscriptions_protocol_CreateEthscription(address(this), out);
    }
    
    function nextNameId() public view returns(uint256) {
        return s().previousNameId + 1;
    }
    
    function nameIsTaken(string calldata name) external view returns(bool) {
        return s().takenNames[name];
    }
    
    function getSigner() external view returns(address) {
        return s().signerAddress;
    }
    
    function cancelSignatures() external onlyAdmin {
        s().cancelBlockNumber = block.number;
    }
    
    function setSigner(address signer) external onlyAdmin {
        s().signerAddress = signer;
    }
    
    function setAdmin(address admin) external onlyAdmin {
        s().adminAddress = admin;
    }
    
    function withdraw() external onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount > 0, "No balance");
        s().adminAddress.forceSafeTransferETH(amount);
    }

    function _domainNameAndVersion() 
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "Facet Card Reserver";
        version = "1";
    }
}
