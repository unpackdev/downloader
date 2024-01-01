// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./DefaultOperatorFilterer.sol";

contract Wasbies is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

    enum Step {
        Paused,
        Public
    }

    uint256 public cost = 0.00269 ether; // Price to mint additional NFTs
    uint256 public maxSupply = 6969; // Total supply of NFTs
    Step public situation = Step.Paused;

    mapping(address => uint16) public walletMints; 

    string public uriPrefix = "ipfs://QmTDpSV9SjyRUag6BB2bHqxtrVsNACDEQJBTLqvEQXZyrW/"; 

    constructor() ERC721A("Wasbies", "WASB") Ownable(msg.sender) {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function publicMint(uint256 amount) external payable {
        require(amount > 0 && amount <= maxSupply - totalSupply(), "Invalid mint amount");
        require(situation == Step.Public, "Public mint is not live");

        uint256 requiredValue = cost * amount;
        if(walletMints[msg.sender] == 0) {
            requiredValue -= cost; 
        }

        require(msg.value == requiredValue, "Insufficient funds");
        
        walletMints[msg.sender] += uint16(amount);
        _safeMint(msg.sender, amount);
    }


    function mintForAddress(uint256 amount, address _receiver) public onlyOwner {
        require(amount > 0, "Invalid mint amount");
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _safeMint(_receiver, amount);
    }

    function numberMinted(address _minter) public view returns (uint256) {
        return _numberMinted(_minter);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(uriPrefix, Strings.toString(_tokenId), ".json"));
    }

    function setSituation(Step _situation) public onlyOwner {
        situation = _situation;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}