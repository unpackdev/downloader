//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./Clones.sol";

interface IClonableWhitelistReference {
  function initialize(bytes32 merkleRoot) external;
}

interface IClonableAirdropMinimal1155Reference {
  function initialize(
    address merkleProofWhitelist,
    address tokenContract,
    uint256 tokenId,
    uint256 startTime,
    uint256 endTime,
    address admin,
    address payout
  ) external;
}

interface IClonableERC1155Reference {
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenURI,
        address admin,
        address factory,
        address minter
    ) external;
    function grantRole(
        bytes32 role,
        address account
    ) external;
    function setTokenURI(
        uint256 _tokenId,
        string memory _tokenURI
    ) external;
    function tokenIdToURI(
        uint256 _tokenId
    ) external returns (string memory);
}

contract MerkleProofAirdropFactory is Ownable {

    event NewMerkle1155AirdropClone(
        uint256 indexed id,
        address indexed referenceContract,
        address indexed airdropClone,
        address merkleProofWhitelist,
        uint256 startTime,
        uint256 endTime
    );

    event NewMerkleWhitelistClone(
        address indexed referenceContract,
        address indexed merkleProofWhitelistClone
    );

    event NewERC1155Clone(
        address indexed referenceContract,
        address indexed erc1155Clone
    );

    event SetClonableAirdropReferenceValidity(
        address indexed referenceContract,
        bool validity
    );

    event SetClonableWhitelistReferenceValidity(
        address indexed referenceContract,
        bool validity
    );

    event SetClonableERC1155ReferenceValidity(
        address indexed referenceContract,
        bool validity
    );

    mapping(address => bool) public validClonableERC1155References;
    mapping(address => bool) public validClonableAirdropReferences;
    mapping(address => bool) public validClonableWhitelistReferences;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Controlled variables
    using Counters for Counters.Counter;
    Counters.Counter private _airdropIds;

    constructor(
        address _clonableERC1155,
        address _clonableMerkleAirdrop,
        address _clonableMerkleWhitelist
    ) {
        validClonableERC1155References[_clonableERC1155] = true;
        validClonableAirdropReferences[_clonableMerkleAirdrop] = true;
        validClonableWhitelistReferences[_clonableMerkleWhitelist] = true;
        emit SetClonableERC1155ReferenceValidity(_clonableERC1155, true);
        emit SetClonableWhitelistReferenceValidity(_clonableMerkleWhitelist, true);
        emit SetClonableAirdropReferenceValidity(_clonableMerkleAirdrop, true);
    }

    function newMerkleAirdrop(
        address _airdropReferenceContract,
        address _whitelistContract,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _endTime,
        address _admin,
        address _payout
    ) external onlyOwner {
        require(validClonableAirdropReferences[_airdropReferenceContract], "INVALID_AIRDROP_REFERENCE_CONTRACT");
        _airdropIds.increment();
        uint256 newAirdropId = _airdropIds.current();
        // Deploy new airdrop contract
        address newAirdropCloneAddress = Clones.clone(_airdropReferenceContract);
        IClonableAirdropMinimal1155Reference newAirdropClone = IClonableAirdropMinimal1155Reference(newAirdropCloneAddress);
        newAirdropClone.initialize(_whitelistContract, _tokenContract, _tokenId, _startTime, _endTime, _admin, _payout);
        emit NewMerkle1155AirdropClone(newAirdropId, _airdropReferenceContract, newAirdropCloneAddress, _whitelistContract, _startTime, _endTime);
        // Set the airdrop contract as a minter of the NFT contract
        IClonableERC1155Reference existingERC1155Clone = IClonableERC1155Reference(_tokenContract);
        existingERC1155Clone.grantRole(MINTER_ROLE, newAirdropCloneAddress);
    }

    function newMerkleWhitelist(
        address _whitelistReferenceContract,
        bytes32 _merkleRoot
    ) external onlyOwner {
        require(validClonableWhitelistReferences[_whitelistReferenceContract], "INVALID_WHITELIST_REFERENCE_CONTRACT");
        // Deploy new whitelist contract
        address newWhitelistCloneAddress = Clones.clone(_whitelistReferenceContract);
        IClonableWhitelistReference newWhitelistClone = IClonableWhitelistReference(newWhitelistCloneAddress);
        newWhitelistClone.initialize(_merkleRoot);
        emit NewMerkleWhitelistClone(_whitelistReferenceContract, newWhitelistCloneAddress);
    }

    function newERC1155(
        address _erc1155ReferenceContract,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenURI,
        address _admin,
        address _minter
    ) external onlyOwner {
        require(validClonableERC1155References[_erc1155ReferenceContract], "INVALID_ERC1155_REFERENCE_CONTRACT");
        // Deploy new ERC1155 contract
        address newERC1155CloneAddress = Clones.clone(_erc1155ReferenceContract);
        IClonableERC1155Reference newERC1155Clone = IClonableERC1155Reference(newERC1155CloneAddress);
        newERC1155Clone.initialize(
            _tokenName,
            _tokenSymbol,
            _tokenURI,
            _admin,
            address(this),
            _minter
        );
        emit NewERC1155Clone(_erc1155ReferenceContract, newERC1155CloneAddress);
    }

    function newMerkleAirdropAndWhitelist(
        address _airdropReferenceContract,
        address _whitelistReferenceContract,
        bytes32 _merkleRoot,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenContract,
        uint256 _tokenId,
        string memory _tokenURI,
        address _admin,
        address _payout
    ) external onlyOwner {
        require(validClonableAirdropReferences[_airdropReferenceContract], "INVALID_AIRDROP_REFERENCE_CONTRACT");
        require(validClonableWhitelistReferences[_whitelistReferenceContract], "INVALID_WHITELIST_REFERENCE_CONTRACT");
        _airdropIds.increment();
        uint256 newAirdropId = _airdropIds.current();
        // Deploy new whitelist contract
        address newWhitelistCloneAddress = cloneAndInitWhitelist(_whitelistReferenceContract, _merkleRoot);
        // Deploy new airdrop contract
        address newAirdropCloneAddress = Clones.clone(_airdropReferenceContract);
        initAirdropClone(newAirdropCloneAddress, newWhitelistCloneAddress, _tokenContract, _tokenId, _startTime, _endTime, _admin, _payout);
        emit NewMerkle1155AirdropClone(newAirdropId, _airdropReferenceContract, newAirdropCloneAddress, newWhitelistCloneAddress, _startTime, _endTime);
        // Set the airdrop contract as a minter of the NFT contract
        IClonableERC1155Reference existingERC1155Clone = IClonableERC1155Reference(_tokenContract);
        existingERC1155Clone.grantRole(MINTER_ROLE, newAirdropCloneAddress);
        // Set the tokenURI of the new token ID if there isn't one set already
        if(keccak256(bytes(existingERC1155Clone.tokenIdToURI(_tokenId))) == keccak256(bytes(""))) {
            existingERC1155Clone.setTokenURI(_tokenId, _tokenURI);
        }
    }

    function newMerkleAirdropAndWhitelistAndERC1155(
        address _airdropReferenceContract,
        address _whitelistReferenceContract,
        address _erc1155ReferenceContract,
        bytes32 _merkleRoot,
        uint256 _startTime,
        uint256 _endTime,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenURI,
        address _airdropAdminAndTempTokenAdmin,
        address _payout
    ) external onlyOwner {
        require(validClonableAirdropReferences[_airdropReferenceContract], "INVALID_AIRDROP_REFERENCE_CONTRACT");
        _airdropIds.increment();
        uint256 newAirdropId = _airdropIds.current();
        // Deploy new airdrop contract
        address newAirdropCloneAddress = Clones.clone(_airdropReferenceContract);
        // Deploy and init new whitelist contract
        address newWhitelistCloneAddress = cloneAndInitWhitelist(_whitelistReferenceContract, _merkleRoot);
        // Deploy and init new ERC1155 contract
        address newERC1155CloneAddress = cloneAndInitERC1155(
            _erc1155ReferenceContract,
            _tokenName,
            _tokenSymbol,
            _tokenURI,
            _airdropAdminAndTempTokenAdmin,
            newAirdropCloneAddress
        );
        // Initialize new airdrop contract
        initAirdropClone(newAirdropCloneAddress, newWhitelistCloneAddress, newERC1155CloneAddress, 1, _startTime, _endTime, _airdropAdminAndTempTokenAdmin, _payout);
        emit NewMerkle1155AirdropClone(newAirdropId, _airdropReferenceContract, newAirdropCloneAddress, newWhitelistCloneAddress, _startTime, _endTime);
    }

    function setClonableAirdropReferenceValidity(
        address _airdropReferenceContract,
        bool _validity
    ) external onlyOwner {
        validClonableAirdropReferences[_airdropReferenceContract] = _validity;
        emit SetClonableAirdropReferenceValidity(_airdropReferenceContract, _validity);
    }

    function setClonableWhitelistReferenceValidity(
        address _whitelistReferenceContract,
        bool _validity
    ) external onlyOwner {
        validClonableWhitelistReferences[_whitelistReferenceContract] = _validity;
        emit SetClonableWhitelistReferenceValidity(_whitelistReferenceContract, _validity);
    }

    function setClonableERC1155ReferenceValidity(
        address _erc1155ReferenceContract,
        bool _validity
    ) external onlyOwner {
        validClonableERC1155References[_erc1155ReferenceContract] = _validity;
        emit SetClonableERC1155ReferenceValidity(_erc1155ReferenceContract, _validity);
    }

    // Internal functions

    function initAirdropClone(
        address _clone,
        address _merkleProofWhitelist,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _endTime,
        address _admin,
        address _payout
    ) internal {
        IClonableAirdropMinimal1155Reference newAirdropClone = IClonableAirdropMinimal1155Reference(_clone);
        newAirdropClone.initialize(_merkleProofWhitelist, _tokenContract, _tokenId, _startTime, _endTime, _admin, _payout);
    }

    function cloneAndInitWhitelist(
        address _whitelistReferenceContract,
        bytes32 _merkleRoot
    ) internal returns (address) {
        require(validClonableWhitelistReferences[_whitelistReferenceContract], "INVALID_WHITELIST_REFERENCE_CONTRACT");
        // Deploy new whitelist contract
        address newWhitelistCloneAddress = Clones.clone(_whitelistReferenceContract);
        // Initialize new whitelist contract
        IClonableWhitelistReference newWhitelistClone = IClonableWhitelistReference(newWhitelistCloneAddress);
        newWhitelistClone.initialize(_merkleRoot);
        emit NewMerkleWhitelistClone(_whitelistReferenceContract, newWhitelistCloneAddress);
        return newWhitelistCloneAddress;
    }

    function cloneAndInitERC1155(
        address _erc1155ReferenceContract,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenURI,
        address _tokenAdmin,
        address _airdropCloneAddress
    ) internal returns (address) {
        require(validClonableERC1155References[_erc1155ReferenceContract], "INVALID_ERC1155_REFERENCE_CONTRACT");
        // Deploy new ERC1155 contract
        address newERC1155CloneAddress = Clones.clone(_erc1155ReferenceContract);
        // Initialize new ERC1155 contract
        IClonableERC1155Reference newERC1155Clone = IClonableERC1155Reference(newERC1155CloneAddress);
        newERC1155Clone.initialize(
            _tokenName,
            _tokenSymbol,
            _tokenURI,
            _tokenAdmin,
            address(this),
            _airdropCloneAddress
        );
        emit NewERC1155Clone(_erc1155ReferenceContract, newERC1155CloneAddress);
        return newERC1155CloneAddress;
    }

}
