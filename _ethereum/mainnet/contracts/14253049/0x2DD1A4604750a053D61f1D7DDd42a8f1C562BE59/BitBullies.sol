// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./LunchMoneyDistributor.sol";

contract BitBullies is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    string private prefix = "\x19Ethereum Signed Message:\n20";

    bool public isWhitelistSaleActive;
    bool public isSaleActive;
    address public whiteListVerification;
    uint256 public immutable price;
    uint256 public immutable maxAmount;
    uint256 public immutable maxWhitelistQty;
    uint256 public immutable devMintQty;
    uint256 private immutable maxBatchSize;

    string private baseURI;

    mapping(address => uint256) public bulliesBalance;
    mapping(address => uint256) public whitelistClaimed;

    LunchMoneyDistributor public tokenDistributor;

    constructor(
        uint256 price_,
        uint256 maxAmount_,
        uint256 devMintQty_,
        uint256 maxBatchSize_
    )
        ERC721A("BitBullies", "BITBULLIES")
    {
        price = price_;
        maxAmount = maxAmount_;
        devMintQty = devMintQty_;
        maxWhitelistQty = 15;
        maxBatchSize = maxBatchSize_;
        isWhitelistSaleActive = false;
        isSaleActive = false;
        whiteListVerification = owner();
    }

    function setLunchMoneyDistributor(address _distributor) external onlyOwner {
        tokenDistributor = LunchMoneyDistributor(_distributor);
    }

    function _hash(address _address) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(prefix, _address));
    }

    function _verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return (_recover(hash, signature) == whiteListVerification);
    }

    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= devMintQty, "too many already minted before dev mint");
        require(quantity % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
        tokenDistributor.updateRewardOnMint(msg.sender);
        bulliesBalance[msg.sender] += quantity;
    }

    function mintWhitelist(bytes calldata signature, uint256 quantity) external payable {
        bytes32 hash = _hash(msg.sender);
        require(isWhitelistSaleActive, "Whitelist Sale is Not Active");

        require(_verify(hash, signature), "This Hash's signature is invalid");

        require(msg.value == price * quantity, "Incorrect Value");
        require(whitelistClaimed[msg.sender] + quantity <= maxWhitelistQty, 'You cannot mint this many.');

        tokenDistributor.updateRewardOnMint(msg.sender);
        whitelistClaimed[msg.sender] += quantity;
        _mintToken(msg.sender, quantity);
    }

    function mintPublic(uint256 quantity) external payable {
        require(isSaleActive, "Public Sale is Not Active");
        require(quantity * price == msg.value, "Invalid amount.");

        tokenDistributor.updateRewardOnMint(msg.sender);
        _mintToken(msg.sender, quantity);
    }

    function _mintToken(address to, uint256 quantity) internal {
        require(quantity + totalSupply() <= maxAmount, "Exceeded Max");
        require(quantity <= maxBatchSize, "Exceeded Max Batch Size");

        _safeMint(to, quantity);
        bulliesBalance[msg.sender] += quantity;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
		tokenDistributor.updateRewardOnTransfer(from, to);
		bulliesBalance[from]--;
		bulliesBalance[to]++;
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
		tokenDistributor.updateRewardOnTransfer(from, to);
		bulliesBalance[from]--;
		bulliesBalance[to]++;
		super.safeTransferFrom(from, to, tokenId, _data);
	}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setWhitelistSaleActive(bool active_) external onlyOwner {
        isWhitelistSaleActive = active_;
    }

    function setSaleActive(bool active_) external onlyOwner {
        isSaleActive = active_;
    }

    function mintTokens(address to, uint256 quantity) external onlyOwner {
        _mintToken(to, quantity);
    }

    function setWhitelistVerification(address verificationAddress) external onlyOwner {
        whiteListVerification = verificationAddress;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}