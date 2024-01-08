// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./ChainlinkClient.sol";

/// @title Obscurite
/// @author @space_bots0

contract Obscurite is ERC721Enumerable, Ownable, ReentrancyGuard, ChainlinkClient {
    using Strings for uint256;
    using SafeMath for uint256;
    using Chainlink for Chainlink.Request;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    string private path;

    string private baseURI;

    bool private reveal;

    // Default token metrics
    uint256 private presalePrice = 0.07 ether;
    uint256 private publicPrice = 0.09 ether;
    uint256 private maxPurchase = 10;
    uint256 private MAX = 5000;
    uint256 private presaleAmount = 2997;

    //reservations for team and giveaway
    uint256 private numReservationsLeft = 30;
    
    address private withdrawWallets = 0x91660E5D81C513c949b38fD29BF6D55A4707De79;

    bool private presaleStatus;
    bool private publicStatus;

    // Mapping to store addresses allowed for presale, and how
    // many NFTs remain that they can purchase during presale.
    uint256 private counters;
    address[] private walletChecked;
    mapping (address => bool) private walletMapping;
    mapping (address => uint256) private presaleVouchers;

    constructor(string memory _name, string memory _symbol)ERC721(_name, _symbol) {
        setPublicChainlinkToken();
    }

    function setOracle(address _oracle, bytes32 _jobId, uint256 _fee, string memory _path) external onlyOwner {
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
        path = _path;
    }

    function checkWhitelist() public returns (bytes32 requestId) {
        require(!walletMapping[msg.sender], "You already checked this address!");
        uint256 addressSender = uint256(uint160(address(msg.sender)));
        string memory whitelistCheck = addressSender.toHexString();
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("get", path);
        req.add("path", whitelistCheck);
        walletChecked.push(msg.sender);
        walletMapping[msg.sender] = true;
        return sendChainlinkRequestTo(oracle, req, fee);
    }

    function fulfill(bytes32 _requestId, bool _result) public recordChainlinkFulfillment(_requestId) {
        if (_result) {
            address presaleAddress = walletChecked[counters];
            presaleVouchers[presaleAddress] = 3;
            counters += 1;
        } else {
            address presaleAddress = walletChecked[counters];
            presaleVouchers[presaleAddress] = 0;
            counters += 1;
        }
    }

    function setPresalePrice(uint256 newPrice) public onlyOwner {
        presalePrice = newPrice;
    }

    function getPresalePrice() public view returns(uint256) {
        return presalePrice;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }

    function getPublicPrice() public view returns(uint256) {
        return publicPrice;
    }

    function walletCheck(address _entry) public view returns(bool) {
        return walletMapping[_entry];
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setMax(uint256 newMax) public onlyOwner {
        MAX = newMax;
    }

    function getMax() public view returns (uint256) {
        return MAX;
    }

    function reserved(address _to,uint256 numNFT) public onlyOwner {
        require(numNFT <= numReservationsLeft, "NFT: Reservations would exceed max reservation threshold of 500.");
        require(totalSupply().add(numNFT) <= MAX, "NFT: Reservations would exceed max supply of NFT.");
        mint(_to, numNFT);
        // Reduce num reservations left
        numReservationsLeft = numReservationsLeft.sub(numNFT);
    }

    function getReservedAmount() public view returns(uint256) {
        return numReservationsLeft;
    }

    function checkPresaleAddress(address _entry) public view returns(uint256) {
        return presaleVouchers[_entry];
    }

    function checkPresaleAmount() public view returns(uint256) {
        return presaleAmount;
    }
     
    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }

    function revealMetadata() public onlyOwner {
        reveal = !reveal;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!reveal) {
            string memory _tokenURI = "https://ipfs.io/ipfs/QmcAzaFBSAmvQki6cXYSMgWZeExdtSCbA7LrkDE4z4nU1v";
            return _tokenURI;
        }
        return super.tokenURI(tokenId);
    }

    function setPresaleState() public onlyOwner {
        presaleStatus = !presaleStatus;
    }

    function setPublicState() public onlyOwner {
        publicStatus = !publicStatus;
    }

    function getSaleState() public view returns(uint256) {
        uint256 saleStates;
        if (presaleStatus && publicStatus) {
            saleStates = 2;
        }
        else if (presaleStatus && !publicStatus) {
            saleStates = 1;
        }
        else {
            saleStates = 0;
        }
        return saleStates;
    }

    function mint(address _to ,uint256 numberOfTokens) private {
        for (uint256 i; i < numberOfTokens; i++) {
            _safeMint(_to, totalSupply() + 1);
        }
    }

    function mintNFT(uint256 numberOfTokens) public payable nonReentrant {
        require(numberOfTokens <= maxPurchase, "NFT: Please try to mint a lower amount of NFTs");
        require(numberOfTokens > 0, "NFT: NFT amount must greater than 0");
        if (presaleStatus && presaleVouchers[msg.sender] > 0) {
            require(presaleVouchers[msg.sender] >= numberOfTokens, "NFT: You don't not have enough presale vouchers to mint that many NFT.");
            require(presalePrice.mul(numberOfTokens) <= msg.value, "NFT: Ether value sent is not correct.");
            require(numberOfTokens <= presaleAmount, "NFT: Purchase would exceed max supply of NFTs.");
            presaleAmount -= numberOfTokens;
            presaleVouchers[msg.sender] -= numberOfTokens;
            mint(msg.sender, numberOfTokens);
        }
        else {
            require(publicStatus, "NFT: Sale must be active.");
            require(publicPrice.mul(numberOfTokens) <= msg.value, "NFT: Ether value sent is not correct.");
            require(totalSupply().add(numberOfTokens) <= MAX.sub(presaleAmount).sub(numReservationsLeft), "NFT: Purchase would exceed max supply of NFTs.");
            mint(msg.sender, numberOfTokens);
        }
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(withdrawWallets).transfer(balance);
    }
}