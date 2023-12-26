// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ISellToken.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Pausable.sol";

contract RomacoAbuseMusicSeller is AccessControl, Ownable, Pausable {
    using ECDSA for bytes32;

    // Role
    bytes32 public constant ADMIN = "ADMIN";

    // SellToken
    ISellToken public sellToken;
    address public ownerAddress;

    // Sell
    address public withdrawAddress;
    address private signer;
    uint256 public minSellCost;
    uint256 public nonce = 0;

    // Modifier
    modifier isValidSignature (address _to, uint256 _tokenId, bytes calldata _signature) {
        address recoveredAddress = keccak256(
            abi.encodePacked(
                _to,
                _tokenId,
                msg.value,
                nonce
            )
        ).toEthSignedMessageHash().recover(_signature);
        require(recoveredAddress == signer, "Invalid Signature");
        _;
    }
    modifier isValidCost () {
        require(msg.value >= minSellCost, "Invalid Cost");
        _;
    }
    modifier hasToken(uint256 _tokenId) {
        require(sellToken.ownerOf(_tokenId) == ownerAddress, 'Not Token Owner');
        _;
    }

    // Constructor
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        withdrawAddress = msg.sender;
    }

    // Sell
    function sell(address _to, uint256 _tokenId, bytes calldata _signature) external payable
        whenNotPaused
        hasToken(_tokenId)
        isValidSignature(_to, _tokenId, _signature)
    {
        sellToken.safeTransferFrom(ownerAddress, _to, _tokenId);
        nonce++;
    }
    function withdraw() external onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // Setter
    function setSellToken(address _value) external onlyRole(ADMIN) {
        sellToken = ISellToken(_value);
    }
    function setOwnerAddress(address _value) external onlyRole(ADMIN) {
        ownerAddress = _value;
    }
    function setWithdrawAddress(address _value) external onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setSigner(address _value) external onlyRole(ADMIN) {
        signer = _value;
    }
    function setMinSellCost(uint256 _value) external onlyRole(ADMIN) {
        minSellCost = _value;
    }

    // Pausable
    function pause() external onlyRole(ADMIN) {
        _pause();
    }
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }
}