// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ISellToken.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Pausable.sol";

contract TolPassSeller2nd is AccessControl, Ownable, Pausable {
    using ECDSA for bytes32;

    // Manage
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant SELLER = "SELLER";

    // TOL Pass
    ISellToken public sellToken;
    address public ownerAddress;

    // Sell
    address public withdrawAddress;
    address private signer;
    uint256 public minSellCost;
    uint256 public nonce = 0;
    uint256 public timezoneOffsetSec = 9 hours;

    // Modifier
    modifier isValidSignature (address _to, uint256 _tokenId, bytes calldata _signature) {
        address recoveredAddress = keccak256(
            abi.encodePacked(
                _to,
                _tokenId,
                msg.value,
                getCurrentTerm(),
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
        _grantRole(ADMIN, msg.sender);
        withdrawAddress = msg.sender;
    }

    // Sell
    function sell(address _to, uint256 _tokenId, bytes calldata _signature) external payable onlyRole(SELLER)
        whenNotPaused
        hasToken(_tokenId)
        isValidSignature(_to, _tokenId, _signature)
    {
        sellToken.safeTransferFrom(ownerAddress, _to, _tokenId);
        nonce++;
    }

    // Getter
    function getCurrentTerm() public view returns (uint256) {
        return (block.timestamp + timezoneOffsetSec) / 1 days;
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
    function setTimezoneOffsetMin(uint256 _value) external onlyRole(ADMIN) {
        timezoneOffsetSec = _value;
    }


    // Metadata
    function withdraw() external payable onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }


    // Pausable
    function pause() external onlyRole(ADMIN) {
        _pause();
    }
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }
}