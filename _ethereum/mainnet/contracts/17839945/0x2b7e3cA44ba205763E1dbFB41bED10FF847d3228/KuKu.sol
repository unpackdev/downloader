// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract KuKu is ERC721A, Ownable {

    using Strings for uint256;

    uint constant public maxTotal = 10000;
    uint constant public maxMint = 5;

    uint public mintTime;
    bool public preMintOpen;
    bool public publicMintOpen;
    bool public blindBoxOpen;
    address public withdrawAddress;
    string public baseTokenURI;
    string public blindTokenURI;
    bytes32 public merkleRoot;
    mapping(address => uint count) public mintCount;
    
    constructor(uint _mintTime, string memory _baseTokenURI) ERC721A("KuKu Club", "KuKu")  {
        mintTime = _mintTime;
        baseTokenURI = _baseTokenURI;
        withdrawAddress = msg.sender;
    }

    function preMint(uint256 num, bytes32[] calldata _proof) external {
        uint256 supply = totalSupply();
        require(verify(_proof), "address is not on the whitelist");
        require(preMintOpen, "pre mint not open");
        require(num <= maxMint, "You can adopt a maximum of 5 KuKu");
        require(supply + num <= maxTotal, "Exceeds maximum KuKu supply");
        require(block.timestamp >= mintTime, "no mint time");
        require(mintCount[tx.origin] + num <= 5, "You can adopt a maximum of 5 KuKu");

        mintCount[tx.origin] += num;
        _safeMint(msg.sender, num);
    }

    function publicMint(uint256 num) external {
        uint256 supply = totalSupply();
        require(publicMintOpen, "public mint not open");
        require(num <= maxMint, "You can adopt a maximum of 5 KuKu");
        require(supply + num <= maxTotal, "Exceeds maximum KuKu supply");
        require(block.timestamp >= mintTime, "You can adopt a maximum of 5 KuKu");
        require(mintCount[tx.origin] + num <= 5, "You can adopt a maximum of 5 KuKu");

        mintCount[tx.origin] += num;
        _safeMint(msg.sender, num);
    }

    function setWithdrawAddress(address _withdrawAddress) external onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setPreMint() external onlyOwner {
        preMintOpen = !preMintOpen;
    }

    function setPublicMint() external onlyOwner {
        publicMintOpen = !publicMintOpen;
    }

    function setBlindBoxOpened() external onlyOwner {
        blindBoxOpen = !blindBoxOpen;
    }

    function setMintTime(uint256 _mintTime) external onlyOwner {
        mintTime = _mintTime;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setBlindTokenURI(string memory _blindTokenURI) external onlyOwner {
        blindTokenURI = _blindTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawAll() external onlyOwner {
        (bool success, ) = withdrawAddress.call{value : address(this).balance}("");
        require(success, "withdraw failed");
    }

    function verify(bytes32[] calldata _merkleProof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function walletOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (blindBoxOpen) {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
        } else {
            return blindTokenURI;
        }
    }

}