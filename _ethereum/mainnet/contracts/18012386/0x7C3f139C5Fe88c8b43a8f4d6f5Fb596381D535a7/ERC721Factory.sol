// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base721.sol";
import "./MultiTokenMetadataBaseUrl.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

// @author: NFT Studios - Buildtree

contract ERC721Factory is Ownable {
    event ContractCreated(address indexed contractAddress, address indexed owner);

    bytes32 public root;

    mapping(address => address) public contracts;

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function unsetContract(address _userAddress) external onlyOwner {
        contracts[_userAddress] = address(0);
    }

    function createContract(
        uint96 _royalty,
        string memory _name,
        string memory _symbol,
        address _metadataResolver,
        string memory _baseURI,
        bool lockMetadata,
        uint256 _amountToMint,
        address _recipient,
        bytes32[] memory _proof
    ) external {
        require(verify(_proof, msg.sender), "Invalid proof");
        require(contracts[msg.sender] == address(0), "Contract for the given address has been already deployed");

        Base721 contractInstance = new Base721(_royalty, msg.sender, _name, _symbol);
        contractInstance.setMetadataResolver(_metadataResolver);
        MultiTokenMetadataBaseUrl(_metadataResolver).setBaseURI(address(contractInstance), _baseURI);

        uint256[] memory mintIds = new uint256[](_amountToMint);
        for (uint256 i; i < _amountToMint; i++) {
            mintIds[i] = i;
        }

        contractInstance.mint(_recipient, mintIds);

        if (lockMetadata) {
            contractInstance.lockMetadata();
            contractInstance.lockMint();
        }

        contractInstance.transferOwnership(msg.sender);

        contracts[msg.sender] = address(contractInstance);
        emit ContractCreated(address(contractInstance), msg.sender);
    }

    function ownerCreateContract(
        uint96 _royalty,
        string memory _name,
        string memory _symbol,
        address _metadataResolver,
        string memory _baseURI,
        bool lockMetadata,
        uint256 _amountToMint,
        address _recipient
    ) external onlyOwner {
        require(contracts[_recipient] == address(0), "Contract for the given address has been already deployed");

        Base721 contractInstance = new Base721(_royalty, _recipient, _name, _symbol);
        contractInstance.setMetadataResolver(_metadataResolver);
        MultiTokenMetadataBaseUrl(_metadataResolver).setBaseURI(address(contractInstance), _baseURI);

        uint256[] memory mintIds = new uint256[](_amountToMint);
        for (uint256 i; i < _amountToMint; i++) {
            mintIds[i] = i;
        }

        contractInstance.mint(_recipient, mintIds);

        if (lockMetadata) {
            contractInstance.lockMetadata();
            contractInstance.lockMint();
        }

        contractInstance.transferOwnership(_recipient);

        contracts[_recipient] = address(contractInstance);
        emit ContractCreated(address(contractInstance), _recipient);
    }

    function verify(bytes32[] memory _proof, address _addr) private view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_addr))));

        return MerkleProof.verify(_proof, root, leaf);
    }
}
