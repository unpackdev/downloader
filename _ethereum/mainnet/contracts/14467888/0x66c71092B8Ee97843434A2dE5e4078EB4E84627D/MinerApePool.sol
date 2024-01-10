// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract MinerApePool is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    address public whitelistSigner = 0xDC257C2947026Fb0c851ffA26ca878FD049462d0;

    string public baseURI = "https://api.minerapepool.com/";

    uint256 public drop = 1;

    uint256 public cost = 0.09 ether;

    uint256 public presaleCost = 0.06 ether;

    uint256 public maxMintAmount = 20;

    uint256 public maxSupply = 2000;

    bool public paused = true;

    bool public presalePaused = true;

    bool public refundable = true;

    mapping(uint256 => mapping(address => uint256)) private addressPresaleMintCount;
    mapping(uint256 => uint256) public nftRefundAmount;
    mapping(uint256 => address) public nftMinter;
    mapping(address => bool) public renouncedMinter;

    bytes32 private immutable DOMAIN_SEPARATOR;
    bytes32 private constant TYPEHASH = keccak256("presale(address buyer,uint256 limit)");

    constructor() ERC721A("Miner Ape Pool", "MAP") {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Miner Ape Pool")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        _safeMint(msg.sender, 30);
    }

    function refund(uint256 nftTokenId) external nonReentrant {
        require(refundable, "Refund closed");
        require(owner() != msg.sender, "Owner cannot refund");
        require(ownerOf(nftTokenId) == msg.sender, "This NFT does not belong to you");
        require(nftMinter[nftTokenId] == msg.sender, "You are not the minter");
        require(!renouncedMinter[msg.sender], "You've renounced your refund claim");

        uint256 amount = nftRefundAmount[nftTokenId];

        require(amount > 0, "Non-refundable NFT");
        require(address(this).balance >= amount, "Not enough funds on the contract");

        safeTransferFrom(msg.sender, owner(), nftTokenId);

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to refund");
    }

    function renounceRefundClaim() external {
        renouncedMinter[msg.sender] = true;
    }

    function whitelistMint(bytes calldata signature, uint256 approvedLimit, uint256 quantity) external payable {
        require(!presalePaused, "Presale is paused");
        require(quantity > 0, "You have to mint at least 1 NFT");
        require(msg.value >= (presaleCost * quantity), "Insufficient payment");
        require(
            (addressPresaleMintCount[drop][msg.sender] + quantity) <= approvedLimit,
            "Address mint limit exceeded"
        );

        uint256 totalSupply = totalSupply();
        require((totalSupply + quantity) <= maxSupply, "Minting would exceed max supply");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(TYPEHASH, msg.sender, approvedLimit))
            )
        );

        address signer = digest.recover(signature);
        require(
            signer != address(0) && signer == whitelistSigner,
            "Invalid signature"
        );

        _safeMint(msg.sender, quantity);

        addressPresaleMintCount[drop][msg.sender] += quantity;

        for (uint256 tokenId = totalSupply + 1; tokenId <= (totalSupply + quantity); tokenId++) {
            nftRefundAmount[tokenId] = presaleCost;
            nftMinter[tokenId] = msg.sender;
        }
    }

    function vaultMint(uint256 quantity) external onlyOwner {
        require((totalSupply() + quantity) <= maxSupply, "Minting would exceed max supply");

        _safeMint(msg.sender, quantity);
    }

    function mintForAddresses(address[] memory addresses) external onlyOwner {
        require((totalSupply() + addresses.length) <= maxSupply, "Minting would exceed max supply");

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function publicMint(uint256 quantity) external payable {
        require(!paused, "Public Sale is paused");
        require(quantity > 0, "You have to mint at least 1 NFT");
        require(maxMintAmount >= quantity, "maxMintAmount is exceeded");
        require(msg.value >= (cost * quantity), "Insufficient payment");

        uint256 totalSupply = totalSupply();

        require((totalSupply + quantity) <= maxSupply, "Minting would exceed max supply");

        _safeMint(msg.sender, quantity);

        for (uint256 tokenId = totalSupply + 1; tokenId <= (totalSupply + quantity); tokenId++) {
            nftRefundAmount[tokenId] = cost;
            nftMinter[tokenId] = msg.sender;
        }
    }

    function checkRefundability(address _address, uint256 nftTokenId) external view returns (uint256) {
        require(refundable, "Refund closed");
        require(owner() != _address, "Owner cannot refund");
        require(ownerOf(nftTokenId) == _address, "This NFT does not belong to the address");
        require(nftMinter[nftTokenId] == _address, "The address is not the minter");
        require(nftRefundAmount[nftTokenId] > 0, "Non-refundable NFT");
        require(!renouncedMinter[_address], "The address renounced its refund claim");
        return nftRefundAmount[nftTokenId];
    }

    function checkAddressPresaleMintCount(address _address) external view returns (uint256) {
        return addressPresaleMintCount[drop][_address];
    }

    function withdraw(address to, uint256 amount) external onlyOwner nonReentrant {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to withdraw");
    }

    function withdrawAll() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

     function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setWhitelistSigner(address _whitelistSigner) external onlyOwner {
        whitelistSigner = _whitelistSigner;
    }

    function setDrop(uint256 _drop) external onlyOwner {
        drop = _drop;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setPresaleCost(uint256 _presaleCost) external onlyOwner {
        presaleCost = _presaleCost;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setPresalePaused(bool _presalePaused) external onlyOwner {
        presalePaused = _presalePaused;
    }

    function setRefundable(bool _refundable) external onlyOwner {
        refundable = _refundable;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
      super.safeTransferFrom(from, to, tokenId, _data);
      nftRefundAmount[tokenId] = 0;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
      super.safeTransferFrom(from, to, tokenId);
      nftRefundAmount[tokenId] = 0;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
      super.transferFrom(from, to, tokenId);
      nftRefundAmount[tokenId] = 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
