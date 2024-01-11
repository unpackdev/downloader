// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./draft-EIP712.sol";

interface ILandz {
    function mint(uint quantity, address receiver) external;
}

contract LandzSale is EIP712, Ownable {
    ILandz _landz = ILandz(0x8A479d6B4435E0b82dc9587610C977C138b86AB4);
    address _signerAddress;
    
    uint public price = 0.06 ether;
    uint public holderPrice = 0.05 ether;
    uint public publicSalesStartTimestamp = 1650060000;
    uint public whitelistSalesStartTimestamp = 1650052800;
    
    address communityAddress = 0x68E321383B3E7976f468ED9A827f7cE62ff86393;

    constructor() EIP712("LANDZ", "1.0.0") {
        _signerAddress = 0x42bC5465F5b5D4BAa633550e205A1d7D81e6cACf;
    }

    function mint(uint quantity) external payable {
        require(isPublicSalesActive(), "sale is not active yet");
        require(msg.value >= price * quantity, "not enough ether");
        
        _landz.mint(quantity, msg.sender);
    }

    function whitelistMint(uint quantity, bool isHolder, bytes calldata signature) external payable {
        require(recoverAddress(msg.sender, isHolder, signature) == _signerAddress, "account is not whitelisted");
        require(isWhitelistSalesActive(), "sale is not active yet");
        require(msg.value >= (isHolder ? holderPrice : price) * quantity, "not enough ether");
        
        _landz.mint(quantity, msg.sender);
    }
    
    function isPublicSalesActive() public view returns (bool) {
        return publicSalesStartTimestamp <= block.timestamp;
    }
    
    function isWhitelistSalesActive() public view returns (bool) {
        return whitelistSalesStartTimestamp <= block.timestamp;
    }
    
    function setPublicSalesStartTimestamp(uint newTimestamp) external onlyOwner {
        publicSalesStartTimestamp = newTimestamp;
    }
    
    function setWhitelistSalesStartTimestamp(uint newTimestamp) external onlyOwner {
        whitelistSalesStartTimestamp = newTimestamp;
    }
    
    function setPrice(uint newPrice, uint newHolderPrice) external onlyOwner {
        price = newPrice;
        holderPrice = newHolderPrice;
    }

    function _hash(address account, bool isHolder) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("LANDZ(address account,bool isHolder)"),
                        account,
                        isHolder
                    )
                )
            );
    }

    function recoverAddress(address account, bool isHolder, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, isHolder), signature);
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(communityAddress).send(address(this).balance));
    }
}