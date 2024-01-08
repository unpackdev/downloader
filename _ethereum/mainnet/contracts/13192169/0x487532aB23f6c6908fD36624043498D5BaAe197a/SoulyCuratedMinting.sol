//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ISouly.sol";
import "./IReverseRegistrar.sol";

contract SoulyCuratedMinting is Ownable {

    using ECDSA for bytes32;

    event MintingAllowanceUpdated(address indexed curator, uint256 mintingAllowance);

    ISouly private _tokenContract;

    mapping (address => uint256) private _mintingAllowance;
    mapping (bytes32 => bool) private _minted;

    struct EIP712DomainType {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    struct MintType {
        address creator;
        bytes32 assetHash;
        address curator;
        address destination;
        uint256 validUntil;
    }

    bytes32 private constant EIP712DomainTypeHash = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 private constant MintTypeHash = keccak256(bytes("Mint(address creator,bytes32 assetHash,address curator,address destination,uint256 validUntil)"));
    bytes32 private _domainSeparator;

    constructor(ISouly tokenContract) Ownable() {
        _tokenContract = tokenContract;
        setDomainSeparator("Souly Curated Minting", "2");
    }

    function setDomainSeparator(string memory name, string memory version) public onlyOwner {
        _domainSeparator = hash(EIP712DomainType(name, version, block.chainid, address(this)));
    }

    function updateMintingAllowance(address curator, uint256 mintingAllowance_) public onlyOwner {
        _mintingAllowance[curator] = mintingAllowance_;
        emit MintingAllowanceUpdated(curator, mintingAllowance_);
    }

    function updateMintingAllowances(address[] memory curators, uint256[] memory mintingAllowances) public {
        require(curators.length == mintingAllowances.length, ":facepalm:");
        for (uint256 index; index < curators.length; index++){
            updateMintingAllowance(curators[index], mintingAllowances[index]);
        }
    }

    function hash(EIP712DomainType memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DomainTypeHash,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function hash(MintType memory mint_) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MintTypeHash, mint_.creator, mint_.assetHash, mint_.curator, mint_.destination, mint_.validUntil
        ));
    }

    function mint(bytes32 assetHash, address curator, bytes memory signature, address destination, uint256 validUntil) external {
        require(block.timestamp <= validUntil, "validUntil");

        require(_mintingAllowance[curator] > 0, "allowance");
        _mintingAllowance[curator] = _mintingAllowance[curator] - 1;

        require(!_minted[assetHash], "minted");
        _minted[assetHash] = true;

        bytes32 msgHash = keccak256(abi.encodePacked(
            "\x19\x01",
            _domainSeparator,
            hash(
                MintType(msg.sender, assetHash, curator, destination, validUntil)
            )
        ));
        require(msgHash.recover(signature) == curator, "signature");

        _tokenContract.mint(payable(msg.sender), destination, assetHash);
    }

    function mintingAllowance(address curator) public view returns(uint256) {
        return _mintingAllowance[curator];
    }

    function setReversRegistry(IReverseRegistrar registrar, string memory name) external onlyOwner returns (bytes32) {
        return registrar.setName(name);
    }
}