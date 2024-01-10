// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC721Receiver.sol";
import "./ERC721.sol";
import "./HapeExodus.sol";

contract HapeExodusAlpha is ERC721, IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    string public baseURI;
    address public exoHapeContractAddress;
    uint256 public maxTotalSupply = 888;
    bool public isLive = false;

    bytes32 private merkleRoot;

    mapping(address => uint256) public summonsPerWallet;
    mapping(address => bool) public walletUsedProofSummon;

    constructor(string memory name, string memory symbol, address _exoHapeContractAddress) ERC721(name, symbol) {
        exoHapeContractAddress = _exoHapeContractAddress;
    }

    function summon(bytes32[] memory _summonProof, uint256 _summonsForProof) external nonReentrant {
        require(isLive, "Not live");
        require(totalSupply().add(1) <= maxTotalSupply, "Max supply reached");

        uint256 availableSummonCount = summonCountForAddress(_msgSender(), _summonProof, _summonsForProof);
        require(availableSummonCount > 0, "No summons available");

        walletUsedProofSummon[_msgSender()] = true;
        summonsPerWallet[_msgSender()] = 0;

        for (uint256 i = 0; i < availableSummonCount; i++) {
            if (totalSupply().add(1) <= maxTotalSupply) {
                _safeMint(_msgSender());
            }
        }
    }

    function summonCountForAddress(address _address, bytes32[] memory _summonProof, uint256 _summonsForProof) public view returns (uint256) {
        uint256 availableSummons = summonsPerWallet[_address];

        bytes32 leafBytes = getLeafBytes(_address, _summonsForProof);
        if (!walletUsedProofSummon[_address] && MerkleProof.verify(_summonProof, merkleRoot, leafBytes)) {
            availableSummons = availableSummons.add(_summonsForProof);
        }

        return availableSummons;
    }

    function burnForSummons(uint256[] calldata tokenIds) external nonReentrant {
        require(isLive, "Not live");
        require(tokenIds.length >= 5, "Must burn at least 5");
        require(tokenIds.length % 5 == 0, "Amount must be dividable by 5");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            HapeExodus(exoHapeContractAddress).burn(tokenIds[i]);
        }

        summonsPerWallet[_msgSender()] = summonsPerWallet[_msgSender()].add(tokenIds.length / 5);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Token not owned or approved");
        _burn(tokenId);
    }

    function increaseSummonCountForAddress(address _address, uint256 _count) external onlyOwner {
        summonsPerWallet[_address] = summonsPerWallet[_address].add(_count);
    }

    function setMaxTotalSupply(uint256 _maxValue) external onlyOwner {
        maxTotalSupply = _maxValue;
    }

    function setIsLive(bool _isLive) external onlyOwner {
        isLive = _isLive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getLeafBytes(address _address, uint256 _summonsForProof) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _summonsForProof));
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
