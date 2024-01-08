// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./RandomlyAssigned.sol";

interface IResurrectables {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}

contract ResurrectablesSales is Ownable, EIP712, RandomlyAssigned {
    
    address _signerAddress;
    mapping(address => uint) public accountToMinted;
    IResurrectables public resurrectables = IResurrectables(0x3Ac4Cdc4c22825Df6fc7f1D54eEf864b8aE46617);
    
    constructor() RandomlyAssigned(777, 0) EIP712("RESURRECT", "1.0.0") {
        _signerAddress = 0x3115fEF0931aF890bd4E600fd5f19591430663c1;
    }

    function setMaxSupply(uint maxSupply_) external onlyOwner {
        _setMaxSupply(maxSupply_);
    }
    
    function _getTokenId(uint randomId) internal pure returns (uint) {
        if (randomId < 3) return 0;
        if (randomId < 13) return 1;
        if (randomId < 63) return 2;
        return 3;
    }
    
    function mint(uint quantity, uint maxMints, bytes calldata signature) external ensureAvailabilityFor(quantity) {
        require(_signerAddress == recoverAddress(msg.sender, maxMints, signature), "user cannot mint");
        require(accountToMinted[msg.sender] + quantity <= maxMints, "user allowance exceeded");
        
        for (uint i = 0; i < quantity; i++) {
            uint randomId = nextToken();
            resurrectables.mint(msg.sender, _getTokenId(randomId), 1, "");
        }
        
        accountToMinted[msg.sender] += quantity;
    }
    
    function _hash(address account, uint maxMints) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFT(uint256 maxMints,address account)"),
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