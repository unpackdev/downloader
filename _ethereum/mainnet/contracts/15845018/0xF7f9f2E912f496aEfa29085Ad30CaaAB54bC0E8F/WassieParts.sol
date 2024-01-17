// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

/*-----------------------------ERRORS---------------------------------*/
error ExceedsTxnLimit();
error ExceedsLimitPerTxn();
error NotOnAllowlist();
error MintInactive();
error AllowlistMintInactive();

contract WassieParts is ERC721AQueryable, ERC721ABurnable, Ownable {
    /*-----------------------------VARIABLES------------------------------*/
    uint256 public constant MAX_PUBLIC_MINTS = 10;
    uint256 public constant MAX_ALLOWLIST_MINTS = 10;
    uint256 public constant MAX_BATCH_SIZE = 5;
    bool public isPublicMintActive = false;
    bool public isAllowlistMintActive = true;
    string public baseTokenURI;
    bytes32 public merkleRoot;

    /*------------------------------EVENTS--------------------------------*/
    event Minted(address indexed receiver, uint256 amount);

    /*--------------------------CONSTRUCTOR-------------------------------*/
    constructor() ERC721A("WassieParts", "WASSIEPARTS") {}

    /*--------------------------MINT FUNCTIONS----------------------------*/
    function mintPublic(uint256 nMints) external {
        if (!isPublicMintActive) revert MintInactive();
        if (nMints > MAX_PUBLIC_MINTS) revert ExceedsTxnLimit();
        _mint(msg.sender, nMints);
        emit Minted(msg.sender, nMints);
    }

    function mintAllowlist(bytes32[] calldata _proof, uint256 nMints) external {
        if (!isAllowlistMintActive) revert AllowlistMintInactive();
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_proof, merkleRoot, node)) revert NotOnAllowlist();
        if (nMints > MAX_ALLOWLIST_MINTS) revert ExceedsLimitPerTxn();

        _mint(msg.sender, nMints);
        emit Minted(msg.sender, nMints);
    }

    function mintAirdrop(uint256 nMints, address recipient) external onlyOwner {
        uint256 remainder = nMints % MAX_BATCH_SIZE;
        unchecked {
            uint256 nBatches = nMints / MAX_BATCH_SIZE;
            for (uint256 i; i < nBatches; ++i) {
                _mint(msg.sender, MAX_BATCH_SIZE);
            }
        }
        if (remainder != 0) {
            _mint(recipient, remainder);
        }
        emit Minted(recipient, nMints);
    }

    /*-------------------------------ADMIN--------------------------------*/

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function togglePublicMintActive() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function toggleAllowlistMintActive() external onlyOwner {
        isAllowlistMintActive = !isAllowlistMintActive;
    }
}
