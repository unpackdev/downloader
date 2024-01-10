// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./draft-EIP712.sol";
import "./Ownable.sol";

interface IFeudalzOrcz {
    function mint(uint quantity, address receiver) external;
}

contract FeudalzOrczOffchainSales is Ownable, EIP712 {
    IFeudalzOrcz orcz = IFeudalzOrcz(0x60A0860503D9ECDA03436cA692D948319f5377f7);
    
    bool public isSalesActive = true;
    mapping (address => uint) public accountToMintedTokens;
    
    address _signerAddress;
    
    constructor() EIP712("ORCZ", "1.0.0") {
        _signerAddress = 0x42bC5465F5b5D4BAa633550e205A1d7D81e6cACf;
    }

    function mint(uint quantity, uint maxMints, bytes calldata signature) external {
        require(isSalesActive, "sale is not active");
        require(recoverAddress(msg.sender, maxMints, signature) == _signerAddress, "invalid signature");
        require(quantity + accountToMintedTokens[msg.sender] <= maxMints, "quantity exceeds allowance");

        orcz.mint(quantity, msg.sender);
        
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
                        keccak256("Orcz(uint256 maxMints,address account)"),
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