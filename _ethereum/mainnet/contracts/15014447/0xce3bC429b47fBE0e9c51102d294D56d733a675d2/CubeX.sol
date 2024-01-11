// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract CubeX is Ownable, ERC721A {
    uint256 public maxSupply;
    uint256 public whitelistSupply;
    uint256 public passAmount;
    uint256 public reservedAmount;

    uint256 public amountMinted;
    uint256 public amountClaimed;

    struct SaleInfo {
        uint256 whitelistStartTime;
        uint256 whitelistPrice;
        uint256 publicSaleStartTime;
        uint256 publicPrice;
        uint256 claimTime;
    }

    SaleInfo public saleInfo;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public userWhitelistMinted;
    mapping(address => uint256) public userPublicMinted;
    mapping(address => uint256) public userPurchasedAmount;
    mapping(address => uint256) public passClaim;
    mapping(address => uint256) public userTotalClaimed;

    constructor(
        uint256 maxSupply_,
        uint256 whitelistSupply_,
        uint256 passAmount_,
        uint256 reservedAmount_
    ) ERC721A("CubeX", "CUBEX") {
        maxSupply = maxSupply_;
        whitelistSupply = whitelistSupply_;
        passAmount = passAmount_;
        reservedAmount = reservedAmount_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function payWhitelist(uint256 quantity) external payable callerIsUser {
        uint256 userMintedWL = userWhitelistMinted[msg.sender];
        require(
            block.timestamp >= saleInfo.whitelistStartTime && block.timestamp <= saleInfo.publicSaleStartTime,
            "whitelist has not started"
        );
        require(whitelist[msg.sender], "not eligible for whitelist");
        require(amountMinted + quantity <= whitelistSupply, "exceeds whitelist supply");
        require(userMintedWL + quantity <= 2, "quantity exceeds WL allowance per user");
        require(msg.value >= saleInfo.whitelistPrice * quantity, "not enough ETH sent");
        userWhitelistMinted[msg.sender] += quantity;
        amountMinted += quantity;
        userPurchasedAmount[msg.sender] += quantity;
    }

    function payPublic(uint256 quantity) external payable callerIsUser {
        require(
            block.timestamp >= saleInfo.publicSaleStartTime && block.timestamp <= saleInfo.claimTime,
            "public sale has not started"
        );
        require(amountMinted + reservedAmount + passAmount + quantity <= maxSupply, "exceeds max supply");
        require(
            userPublicMinted[msg.sender] + quantity <= 3,
            "exceeds mint maximum"
        );
        require(
            msg.value >= saleInfo.whitelistPrice * quantity,
            "not enough ETH sent"
        );
        amountMinted += quantity;
        userPublicMinted[msg.sender] += quantity;
        userPurchasedAmount[msg.sender] += quantity;
    }

    function mintReserved(uint256 quantity, address receiver)
        external
        onlyOwner
    {
        require(receiver != address(0), "cannot mint to zero address");
        _safeMint(receiver, quantity);
        amountClaimed += quantity;
    }

    function getAmountToClaim(address user) public view returns (uint256) {
        return userPurchasedAmount[user] + passClaim[user] - userTotalClaimed[user];
    }

    function claimCubeX() external {
        require(block.timestamp >= saleInfo.claimTime, "claim has not started");
        uint256 amountToClaim = getAmountToClaim(msg.sender);
        require(amountToClaim > 0, "nothing to claim");
        _safeMint(msg.sender, amountToClaim);

        userTotalClaimed[msg.sender] += amountToClaim;
        amountClaimed += amountToClaim;
    }

    function setSaleInfo(
        uint256 whitelistStartTime_,
        uint256 whitelistPrice_,
        uint256 publicSaleStartTime_,
        uint256 publicPrice_,
        uint256 claimTime_
    ) external onlyOwner {
        saleInfo = SaleInfo(
            whitelistStartTime_,
            whitelistPrice_,
            publicSaleStartTime_,
            publicPrice_,
            claimTime_
        );
    }

    function setWhitelistStartTime(uint256 timestamp) external onlyOwner {
        saleInfo.whitelistStartTime = timestamp;
    }

    function setWhitelistPrice(uint256 whitelistPrice) external onlyOwner {
        saleInfo.whitelistPrice = whitelistPrice;
    }

    function setPublicStartTime(uint256 timestamp) external onlyOwner {
        saleInfo.publicSaleStartTime = timestamp;
    }

    function setPublicPrice(uint256 publicPrice) external onlyOwner {
        saleInfo.publicPrice = publicPrice;
    }

    function setClaimTime(uint256 timestamp) external onlyOwner {
        saleInfo.claimTime = timestamp;
    }

    function setWhitelist(
        address[] memory addresses,
        bool eligible
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = eligible;
        }
    }

    function setPassClaim(
        address[] memory addresses,
        uint256 amountToClaim
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            passClaim[addresses[i]] = amountToClaim;
        }
    }

    function withdrawFunds(address payable addr1, address payable addr2, address payable addr3, address payable addr4)
        external
        onlyOwner
    {
        uint256 balance = address(this).balance;
        payable(addr1).transfer((balance * 9325) / 10000);
        payable(addr2).transfer((balance * 400) / 10000);
        payable(addr3).transfer((balance * 175) / 10000);
        payable(addr4).transfer((balance * 100) / 10000);

    }

    string public baseURI;

    string public placeholderURI;

    bool public revealed = false;

    function setPlaceHolderURI(string calldata placeholderURI_) external onlyOwner {
        placeholderURI = placeholderURI_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function toggleReveal(bool revealed_) external onlyOwner {
        revealed = revealed_;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (!revealed) return placeholderURI;
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
}
