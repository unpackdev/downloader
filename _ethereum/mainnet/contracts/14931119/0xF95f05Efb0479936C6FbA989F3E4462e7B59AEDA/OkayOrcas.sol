// developed by @b_gbz

pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./ERC721A.sol";
import "./Ownable.sol"; 
import "./ReentrancyGuard.sol";
import "./Allowlist.sol";

contract OrcatownWtf is ERC721A, Ownable, ReentrancyGuard, Allowlist {

    string public        baseURI;
    uint public          price             = 0.008 ether;
    uint public          maxPerTx          = 20;
    uint public          totalFree         = 111;
    uint public          maxSupply         = 444;
    bool public          mintEnabled;

    constructor(bytes32 _merkleRoot) ERC721A("Orcatown.wtf", "OTF"){
        merkleRoot = _merkleRoot;
    }

    function mint(uint256 amt) external payable
    {
        uint cost = price;
        uint maxMint = maxPerTx;

        if(totalSupply() + amt < totalFree + 1) {
            cost = 0;
            maxMint = 1;
        }

        require(mintEnabled, "Minting is not live yet");
        require(msg.value == amt * cost, "Please send the exact amount.");
        require( amt < maxMint + 1, "Max per TX reached.");
        require(totalSupply() + amt < maxSupply + 1, "Max supply reached");

        _safeMint(msg.sender, amt);
    }

    function mintToAL(address _to, bytes32[] calldata _merkleProof) public {
        require(onlyAllowlistMode == true, "Allowlist minting is closed");
        require(isAllowlisted(_to, _merkleProof), "Address is not in Allowlist!");
        require(numberMinted(msg.sender) < 2, "Max minted per wallet.");

        _safeMint(_to, 1);
    }

    function enableMint()  external onlyOwner {
        onlyAllowlistMode = false;
        mintEnabled = true;
    }

    function ownerBatchMint(uint256 amt) external onlyOwner
    {
        require(totalSupply() + amt < maxSupply + 1, "too many!");

        _safeMint(msg.sender, amt);
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setTotalFree(uint256 totalFree_) external onlyOwner {
        totalFree = totalFree_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}