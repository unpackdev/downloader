//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./ECDSA.sol";

abstract contract MintEngineContract is Context {
  using ECDSA for bytes32;  
  using Counters for Counters.Counter;

    mapping (address => Counters.Counter) private nonces;
    MintEnginePayee[] public Payees;

    address private mintEngineOwner;
    address private mintEngineSigner;
    address private mintEngineVault;
    uint256 private mintEngineFee = 100;   

    struct MintEngineNFT {
        uint256 tokenId;
        string ipfsMetadataHash;
    }

    struct MintEnginePayee {
        address payeeAddress;
        uint256 basisFee;
    }

    constructor() {
        mintEngineOwner = 0x8612f5c320e04867E73dA6c4D381aC87Ae8911A2;
        mintEngineSigner = 0xB70656932D602aca3C8318BC1C1285Cfb39DEC53;
        mintEngineVault = 0x5350Aa319221d04834BC797709dCc891A964F1Ca;
    }

    /**
     * @dev Throws if called by any account other than the MintEngine owner.
     */
    modifier onlyMintEngine() {
        _checkMintEngineOwner();
        _;
    }

    /**
     * @dev Returns the address of the MintEngine Owner.
     */
    function getMintEngineOwner() public view virtual returns (address) {
        return mintEngineOwner;
    }

    /**
     * @dev Returns the address of the MintEngine Vault.
     */
    function getMintEngineVault() public view virtual returns (address) {
        return mintEngineVault;
    }

    /**
     * @dev Returns the integer of the MintEngine Fee.
     */
    function getMintEngineFee() public view virtual returns (uint256) {
        return mintEngineFee;
    }

    /**
     * @dev Throws if the sender is not the MintEngine owner.
     */
    function _checkMintEngineOwner() internal view virtual {
        require(getMintEngineOwner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Simplifies hashing a string for signature verification
     */
    function hashData(string memory _s, string memory _k) private view returns(bytes32) {
        return keccak256(abi.encodePacked(currentMintEngineNonce(msg.sender), _k, _s));
    }
    
    function hashData(address _a, string memory _k) private view returns(bytes32) {
        return keccak256(abi.encodePacked(currentMintEngineNonce(msg.sender), _k, _a));
    }

    function verifySigner(address _ad, string memory _k, bytes memory signature) internal returns(bool) {
        bytes32 h = hashData(_ad, _k);
        return verifySigner(h, signature);
    }

    function verifySigner(string memory _sth, string memory _k, bytes memory signature) internal returns(bool) {
        bytes32 h = hashData(_sth, _k);
        return verifySigner(h, signature);
    }

    function verifySigner(bytes32 hash, bytes memory signature) internal returns(bool) {
        bool isVerified =  mintEngineSigner == hash.recover(signature);
        nonces[msg.sender].increment();
        return isVerified;
    }

    /**
     * @dev Allows the MintEngine admins only to change MintEngine Only information for operability. 
     * Requires private key signature generation by system.
     */
    function setMingEngineOwner(bytes memory signature, address newOwner) public {
        require(verifySigner(hashData(msg.sender, "mintEngineOnly"), signature), "INVALID SIGNATURE");
        mintEngineOwner = newOwner;
    }

    function setMintEngineSigner(bytes memory signature, address newSigner) public {
        require(verifySigner(hashData(msg.sender, "mintEngineOnly"), signature), "INVALID SIGNATURE");
        mintEngineSigner = newSigner;     
    }

    function setMintEngineVault(bytes memory signature, address newVault) public {
        require(verifySigner(hashData(msg.sender, "mintEngineOnly"), signature), "INVALID SIGNATURE");
        mintEngineVault = newVault;       
    }

    function setMintEngineFee(bytes memory signature, uint256 fee) public {
        require(verifySigner(hashData(msg.sender, "mintEngineOnly"), signature), "INVALID SIGNATURE");
        mintEngineFee = fee  ;    
    }

    function currentMintEngineNonce(address owner) public view returns (uint256) {
        return nonces[owner].current();
    }
}

