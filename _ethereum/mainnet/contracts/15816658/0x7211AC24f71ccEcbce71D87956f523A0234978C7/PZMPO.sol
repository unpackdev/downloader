// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract PZMPO is Ownable, AccessControl {
    using ECDSA for bytes32;

    address private signerAddress = 0x7f16518Cb6ffC503014e2192BcEFa2abAa5C7359;
    address private poolAddress = 0xCC9B5D0FAC5c2B9bEd68341C79c23D34A8e72A9c;
    bool public preOrderLive = false;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 public preOrderPrice = 1 ether;

    mapping(address => bool) public isRegistered;
    mapping(uint256 => address) public isTokenClaimed;

    event PoolAddressChanged(address indexed _from, address _to, address _oldAddress);
    event PreOrderPriceChanged(address indexed _from, uint256 _value);
    event PreOrderDirectRegistered(address indexed _from, uint256 _value, address _to);
    event PreOrderDirectUnset(address indexed _from, uint256 _tokenId, address _oldAddress);
    event PreOrderRegistered(address indexed _from, uint256 _value, address _to);
    event PreOrderToggled(address indexed _from, bool _value);
    event PreOrderTokenIdUpdated(address indexed _from, uint256 _oldTokenId, uint256 _newTokenId, address _address);
    event SignerAddressChanged(address indexed _from, address _to, address _oldAddress);

    constructor(address _deployer) {
        _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
        _setRoleAdmin(OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        transferOwnership(_deployer);
    }

    modifier checkSigned(
        address _address,
        uint256 _nonce,
        uint256 _tokenId,
        bytes32 _messageHash,
        bytes memory _signature
    ) {
        require(_tokenId > 0 && _tokenId <= 1987, "Token ID invalid, out of range!");
        require(isTokenClaimed[_tokenId] == address(0), "Token ID already claimed!");
        require(msg.value == preOrderPrice, "Fund doesn't match pre order price!");
        require(
            _messageHash ==
                ECDSA.toEthSignedMessageHash(hashPacked(_address, _nonce, _tokenId)),
            "Invalid message hash"
        );
        require(
            signerAddress == ECDSA.recover(_messageHash, _signature),
            "Invalid signature"
        );
        _;
    }

    function togglePreOrder() external onlyRole(OPERATOR_ROLE) {
        preOrderLive = !preOrderLive;
        emit PreOrderToggled(msg.sender, preOrderLive);
    }

    function setPreOrderPrice(uint256 _preOrderPrice) external onlyOwner {
        preOrderPrice = _preOrderPrice;
        emit PreOrderPriceChanged(msg.sender, preOrderPrice);
    }

    function updatePreOrderTokenId(uint256 _oldTokenId, uint256 _tokenId, address _directAddress) external onlyOwner {
        require(_directAddress != address(0), "Address is not valid!");
        require(isTokenClaimed[_oldTokenId] == _directAddress, "Token is not yours!");
        require(isTokenClaimed[_tokenId] == address(0), "Token is already taken!");
        isTokenClaimed[_oldTokenId] = address(0);
        isTokenClaimed[_tokenId] = _directAddress;
        emit PreOrderTokenIdUpdated(msg.sender, _oldTokenId, _tokenId, _directAddress);
    }

    function setRegisterPreOrderDirect(uint256 _tokenId, address _directAddress) external onlyOwner {
        require(_directAddress != address(0), "Address is not valid!");
        require(!isRegistered[_directAddress], "Address has claimed!");
        require(isTokenClaimed[_tokenId] == address(0), "Token is already taken!");
        isRegistered[_directAddress] = true;
        isTokenClaimed[_tokenId] = _directAddress;
        emit PreOrderDirectRegistered(msg.sender, _tokenId, _directAddress);
    }

    function unsetRegisterPreOrderDirect(uint256 _tokenId) external onlyOwner {
        require(isTokenClaimed[_tokenId] != address(0), "Token is unclaimed!");
        address oldAddress = isTokenClaimed[_tokenId];
        isRegistered[oldAddress] = false;
        isTokenClaimed[_tokenId] = address(0);
        emit PreOrderDirectUnset(msg.sender, _tokenId, oldAddress);
    }

    function setRegisterPreOrder(
        uint256 _nonce,
        uint256 _tokenId,
        bytes32 _msgHash,
        bytes memory _signature
    ) external payable checkSigned(msg.sender, _nonce, _tokenId, _msgHash, _signature) {
        require(preOrderLive, "Preorder period not started");
        require(!isRegistered[msg.sender], "You already pre ordered!");
        isRegistered[msg.sender] = true;
        isTokenClaimed[_tokenId] = msg.sender;
        (bool sent, ) = poolAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit PreOrderRegistered(msg.sender, msg.value, poolAddress);
    }

    function setPoolAddress(address _newPoolAddress) external onlyOwner {
        require(_newPoolAddress != address(0), "Address is not valid!");
        address oldAddress = poolAddress;
        poolAddress = _newPoolAddress;
        emit PoolAddressChanged(msg.sender, poolAddress, oldAddress);
    }

    function setSignerAddress(address _newSigner) external onlyOwner {
        require(_newSigner != address(0), "Address is not valid!");
        address oldAddress = signerAddress;
        signerAddress = _newSigner;
        emit SignerAddressChanged(msg.sender, signerAddress, oldAddress);
    }

    function hashPacked(address _address, uint256 _nonce, uint256 _tokenId)
        private
        pure
        returns (bytes32)
    {
        bytes memory hashData = abi.encodePacked(_address, _nonce, _tokenId);
        bytes32 hash = keccak256(hashData);
        return hash;
    }
}
