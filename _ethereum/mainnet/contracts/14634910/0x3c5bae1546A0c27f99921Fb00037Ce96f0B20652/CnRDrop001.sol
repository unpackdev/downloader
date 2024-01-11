// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract CnRDrop001 is ERC721, Ownable {

    using Strings for uint256;
    using Counters for Counters.Counter;
    using MerkleProof for bytes32[];

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_MINT = 1000;
    uint256 public PRICE = 0.375 ether;
    uint256 public MAX_RESERVE = 44;

    bool public isActive = false;
    bool public isAllowListActive = true;
    bool public isRedeemable = false;

    uint256 public purchaseLimit = 1;
    uint256 public totalPublicSupply;

    bytes32 private merkleRoot;
    mapping(address => uint256) private _claimed;
    mapping(uint256 => address) private _redeemed;

    uint256[] private _gifted;

    string private _contractURI = "";
    string private _tokenBaseURI = "";

    constructor(bytes32 initialRoot) ERC721("CULTandRAIN DROP 001", "CnR001") {
        merkleRoot = initialRoot;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function howManyClaimed(address _address) external view returns (uint256) {
        return _claimed[_address];
    }

    function onAllowList(address addr,bytes32[] calldata _merkleProof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(_merkleProof,merkleRoot,leaf);
    }

    function buyNFT(bytes32[] calldata _merkleProof) external payable {
        require(isActive, "Contract is not active");

        require(totalSupply() < MAX_MINT, "All tokens have been minted");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            isAllowListActive ? MerkleProof.verify(_merkleProof,merkleRoot,leaf) : true,
            "You are not on the Allow List"
        );

        require(
            msg.value > 0 && msg.value % PRICE == 0,
            "Amount must be a multiple of price"
        );

        uint256 amount = msg.value / PRICE;
        require(
            amount >= 1 && amount <= purchaseLimit,
            "Amount should be at least 1"
        );

        require(
            (_claimed[msg.sender] + amount) <= purchaseLimit,
            "Purchase exceeds purchase limit"
        );

        uint256 reached = amount + _tokenIdCounter.current();
        require(
            reached <= (MAX_MINT - MAX_RESERVE),
            "Purchase would exceed public supply"
        );

        _claimed[msg.sender] += amount;

        totalPublicSupply += amount;

        for (uint256 i = 0; i < amount; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _mint(msg.sender, newTokenId);
        }
    }

    function gift(address to) external onlyOwner {
        require(totalSupply() < MAX_MINT, "All tokens have been minted");

        require(_gifted.length < MAX_RESERVE, "Max reserve reached");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _gifted.push(newTokenId);
        _mint(to, newTokenId);
    }

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setNewPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice;
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setPurchaseLimit(uint256 newLimit) external onlyOwner {
        require(
            newLimit > 0 && newLimit < MAX_MINT,
            "New reserve must be greater than zero"
        );
        purchaseLimit = newLimit;
    }

    function setMaxReserve(uint256 newReserve) external onlyOwner {
        MAX_RESERVE = newReserve;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to witdraw!");
        payable(msg.sender).transfer(balance);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function publicSupply() external view returns (uint256) {
        return totalPublicSupply;
    }

    function redeem(uint256 _tokenId) external returns (bool) {
        require(isRedeemable, "Redeeming not available");
        require(ownerOf(_tokenId) == msg.sender, "You must own the NFT");
        require(_redeemed[_tokenId] == address(0), "You already redeemed the NFT");
        _redeemed[_tokenId] = msg.sender;
        return true;
    }

    function setRedeemable(bool _redeemable) external onlyOwner {
        isRedeemable = _redeemable;
    }

    function whoRedeemed(uint256 _tokenId) external view returns (address) {
        return _redeemed[_tokenId];
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
      merkleRoot = root;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function getGiftedTokens() public view returns (uint256[] memory) {
        return _gifted;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}
