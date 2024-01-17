// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title: NFTMinterMerkle
/// @author: Pacy (inspired by HayattiQ NFTBoil)

import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";

// prettier-ignore
interface IERC721 {
    function totalSupply() external view returns (uint256);
    function mint(address _to, uint256 _tokenId) external;
    function lock(uint256 tokenId_) external;
}

contract NFTMinterMerkle is Ownable, Pausable {
    using Strings for uint256;

    uint256 public preCost = 0.02 ether;
    uint256 public publicCost = 0.03 ether;

    bool public presale;

    uint256 public constant MAX_SUPPLY = 1024;

    bytes32 public freeMerkleRoot;
    bytes32 public preMerkleRoot;

    address public nft;

    mapping(address => uint256) public freeAllowListClaimed;
    mapping(address => uint256) public preAllowListClaimed;

    constructor(address nft_) {
        presale = true;
        _pause();
        nft = nft_;
    }

    function publicMint(uint256 _mintAmount) public payable whenNotPaused {
        uint256 supply = IERC721(nft).totalSupply();
        uint256 cost = publicCost * _mintAmount;
        _mintCheck(_mintAmount, supply, cost);
        require(!presale, "Presale is active.");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            IERC721(nft).mint(msg.sender, supply + i);
        }
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _alAmount,
        bytes32[] calldata _merkleProof
    ) public payable whenNotPaused {
        uint256 supply = IERC721(nft).totalSupply();
        uint256 cost = preCost * _mintAmount;
        _mintCheck(_mintAmount, supply, cost);
        require(presale, "Presale is not active.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _alAmount));
        require(
            MerkleProof.verify(_merkleProof, preMerkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            require(
                preAllowListClaimed[msg.sender] < _alAmount,
                "Already fully minted"
            );
            IERC721(nft).mint(msg.sender, supply + i);
            preAllowListClaimed[msg.sender]++;
        }
    }

    function freeMint(
        uint256 _mintAmount,
        uint256 _alAmount,
        bytes32[] calldata _merkleProof
    ) public payable whenNotPaused {
        uint256 supply = IERC721(nft).totalSupply();
        uint256 cost = 0;
        _mintCheck(_mintAmount, supply, cost);
        require(presale, "Free mint is not active.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _alAmount));
        require(
            MerkleProof.verify(_merkleProof, freeMerkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            require(
                freeAllowListClaimed[msg.sender] < _alAmount,
                "Already fully minted"
            );
            uint256 tokenId = supply + i;
            IERC721(nft).mint(msg.sender, tokenId);
            IERC721(nft).lock(tokenId);
            freeAllowListClaimed[msg.sender]++;
        }
    }

    function _mintCheck(
        uint256 _mintAmount,
        uint256 supply,
        uint256 cost
    ) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(supply + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
    }

    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    function setPreCost(uint256 _preCost) public onlyOwner {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function getCurrentCost() public view returns (uint256) {
        if (presale) {
            return preCost;
        } else {
            return publicCost;
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setFreeMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        freeMerkleRoot = _merkleRoot;
    }

    function setPreMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        preMerkleRoot = _merkleRoot;
    }
}
