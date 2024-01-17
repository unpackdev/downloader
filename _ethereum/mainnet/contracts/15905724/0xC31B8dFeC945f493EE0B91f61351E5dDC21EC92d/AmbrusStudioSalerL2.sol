// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AccessControl.sol";
import "./MerkleProof.sol";

contract AmbrusStudioSalerL2 is AccessControl {
    struct SaleConfig {
        uint32 start;
        uint32 end;
        uint8 discount;
        bytes32 merkleRoot;
    }

    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    uint16 public count;
    uint256 public startId;
    uint256 public basePrice;

    SaleConfig public permitSaleConfig;
    SaleConfig public whitelistSaleConfig;

    uint16 public soldCount;

    mapping(address => uint256) public permitSaleCount;
    mapping(address => uint256) public whitelistSaleCount;

    event MintRequested(uint256 tokenId);

    constructor(uint16 _count, uint256 _startId, uint256 p0, uint32 s1, uint32 e1, bytes32 m1, uint32 s2, uint32 e2, bytes32 m2) {
        count = _count;
        startId = _startId;

        basePrice = p0;
        permitSaleConfig.discount = 15;
        whitelistSaleConfig.discount = 10;

        permitSaleConfig.start = s1;
        permitSaleConfig.end = e1;
        permitSaleConfig.merkleRoot = m1;

        whitelistSaleConfig.start = s2;
        whitelistSaleConfig.end = e2;
        whitelistSaleConfig.merkleRoot = m2;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, address(0x6465F1250c9fe162602Db83791Fc3Fb202D70a7B));
    }

    function setBasePrice(uint256 _basePrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        basePrice = _basePrice;
    }

    function permitSalePrice() external view returns (uint256) {
        return basePrice - basePrice * permitSaleConfig.discount / 100;
    }
    function setPermitSaleTime(uint32 start, uint32 end) external onlyRole(DEFAULT_ADMIN_ROLE) {
        permitSaleConfig.start = start;
        permitSaleConfig.end = end;
    }
    function setPermitSaleDiscount(uint8 discount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        permitSaleConfig.discount = discount;
    }
    function setPermitSaleMerkleRoot(bytes32 merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        permitSaleConfig.merkleRoot = merkleRoot;
    }
    function isPermitSaleAllowed(address account, bytes32[] calldata signature) external view returns (bool) {
        return isAccountAllowed(account, permitSaleConfig.merkleRoot, signature);
    }

    function permitSale(bytes32[] calldata signature) external payable {
        require(permitSaleCount[msg.sender] < 2, "Exceeds purchase limit");
        permitSaleCount[msg.sender] += 1;
        _restrictedSale(permitSaleConfig, signature);
    }

    function whitelistSalePrice() external view returns (uint256) {
        return basePrice - basePrice * whitelistSaleConfig.discount / 100;
    }
    function setWhitelistSaleTime(uint32 start, uint32 end) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistSaleConfig.start = start;
        whitelistSaleConfig.end = end;
    }
    function setWhitelistSaleDiscount(uint8 discount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistSaleConfig.discount = discount;
    }
    function setWhitelistSaleMerkleRoot(bytes32 merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistSaleConfig.merkleRoot = merkleRoot;
    }
    function isWhitelistSaleAllowed(address account, bytes32[] calldata signature) external view returns (bool) {
        return isAccountAllowed(account, whitelistSaleConfig.merkleRoot, signature);
    }

    function whitelistSale(bytes32[] calldata signature) external payable {
        require(whitelistSaleCount[msg.sender] < 2, "Exceeds purchase limit");
        whitelistSaleCount[msg.sender] += 1;
        _restrictedSale(whitelistSaleConfig, signature);
    }

    function _restrictedSale(SaleConfig memory config, bytes32[] calldata signature) private {
        require(block.timestamp >= config.start, "Sale not start");
        require(block.timestamp < config.end, "Sale has ended");
        require(isAccountAllowed(msg.sender, config.merkleRoot, signature), "You're not allowed to buy");
        require(msg.value == (basePrice - basePrice * config.discount / 100), "Sent value not equal to price");

        _sale();
    }
    function isAccountAllowed(address account, bytes32 merkleRoot, bytes32[] calldata signature) public pure returns (bool) {
        if (merkleRoot == "") {
            return false;
        }

        return MerkleProof.verify(signature, merkleRoot, keccak256(abi.encodePacked(account)));
    }

    function _sale() private {
        require(soldCount < count, "Sold out");

        soldCount++;

        emit MintRequested(startId + soldCount);
    }

    function withdraw(address account) external onlyRole(WITHDRAWER_ROLE) {
        payable(account).transfer(address(this).balance);
    }

    receive() external payable { }
}
