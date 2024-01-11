// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./draft-EIP712.sol";

interface ILandz {
    function mint(uint quantity, address receiver) external;
}

contract LandzOffchainSale is Ownable, EIP712 {
    ILandz _landz = ILandz(0x8A479d6B4435E0b82dc9587610C977C138b86AB4);
    address _signerAddress;

    bool public isSalesActive;
    mapping (address => uint) public accountToMintedTokens;
    
    constructor() EIP712("LANDZ", "1.0.0") {
        isSalesActive = false;
        _signerAddress = 0x42bC5465F5b5D4BAa633550e205A1d7D81e6cACf;
    }

    function mint(uint quantity, uint maxMints, bytes calldata signature) external {
        require(isSalesActive, "sale is not active");
        require(recoverAddress(msg.sender, maxMints, signature) == _signerAddress, "invalid signature");
        require(quantity + accountToMintedTokens[msg.sender] <= maxMints, "quantity exceeds allowance");
        
        _landz.mint(quantity, msg.sender);

        accountToMintedTokens[msg.sender] += quantity;
    }

    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }

    function _hash(address account, uint maxMints) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("Landz(uint256 maxMints,address account)"),
                        maxMints,
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, uint maxMints, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, maxMints), signature);
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }
}