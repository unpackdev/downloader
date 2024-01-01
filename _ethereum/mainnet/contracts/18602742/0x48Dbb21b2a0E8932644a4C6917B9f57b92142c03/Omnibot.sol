// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Omnibot is ERC721A, Ownable {
    bytes32 public merkleRoot;
    string public baseURI;
    uint256 public startTime = 1700668800;
    uint256 public price = 0.004 ether;
    uint256 public whitelistPrice = 0.003 ether;
    uint256 public supply = 1000;
    uint256 public maxPerWallet = 3;

    constructor() ERC721A("OMNIBOT", "OMNBT") Ownable(_msgSender()) {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(block.timestamp >= startTime, "Minting currently restricted by timestamp parameters.");
        require(totalSupply() + quantity <= supply, "Mint quantity exceeds the supply.");
        require(_numberMinted(_msgSender()) + quantity <= maxPerWallet, "Mint quantity exceeds the max per wallet limit.");
        require(price * quantity <= msg.value, "Ethereum value insufficient to cover mint fees.");

        _mint(_msgSender(), quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Merkle proof fails cryptographic validation.");
        require(block.timestamp >= startTime, "Minting currently restricted by timestamp parameters.");
        require(totalSupply() + quantity <= supply, "Mint quantity exceeds the supply.");
        require(_numberMinted(_msgSender()) + quantity <= maxPerWallet, "Mint quantity exceeds the max per wallet limit.");
        require(whitelistPrice * quantity <= msg.value, "Ethereum value insufficient to cover mint fees.");

        _mint(_msgSender(), quantity);
    }

    function airdrop(address[] memory _addresses) external onlyOwner {
        require(totalSupply() + _addresses.length <= supply, "Mint quantity exceeds the supply.");

        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }

    function mintTo(uint256 quantity, address receiver) external onlyOwner {
        require(totalSupply() + quantity <= supply, "Mint quantity exceeds the supply.");

        _mint(receiver, quantity);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Balance below the required threshold.");
        payable(_msgSender()).transfer(address(this).balance);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        supply = _supply;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }
}
