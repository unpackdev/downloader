// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./ERC721.sol";
import "./Ownable.sol";


contract Pepeliens is Ownable, ERC721 {
    using ECDSA for bytes32;

    uint256 constant public PEPES_AMOUNT = 5555 + 1;
    uint256 public wlPrice = 0.004 ether;
    uint256 public publicPrice = 0.007 ether;
    uint256 public publicMintDate = 1661274000; // 2022-08-23 17:00:00
    uint256 public wlMintDate = 1661272200; // 2022-08-23 16:30:00
    uint256 public maxPerWallet = 20;
    uint256 public teamReserved = 155;
    uint256 private minted = 1;
    string public baseTokenURI = "";
    string private _contractURI = "";

    address private _wlSignerAddress;

    mapping(address => bool) public freeTaken;


    constructor(address wlSignerAddress_)
        ERC721("Pepeliens", "PEPELIENS")
    {
        _wlSignerAddress = wlSignerAddress_;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function totalSupply() public view returns (uint256) {
        return minted - 1;
    }

    modifier enoughTokens(uint256 amount) {
        require(
            minted + amount - 1 < PEPES_AMOUNT - teamReserved,
            "no more tokens"
        );
        _;
    }
    modifier publicOnly() {
        require(block.timestamp > publicMintDate, "public mint not started");
        _;
    }

    modifier wlOnly(bytes calldata signature) {
        require(block.timestamp > wlMintDate, "whitelist mint not started");
        require(_wlSignerAddress == keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            bytes32(uint256(uint160(msg.sender)))
        )).recover(signature), "signer address mismatch");
        _;
    }

    function publicMint(uint256 amount) external payable publicOnly enoughTokens(amount) {
        require(amount > 0, "too less");
        require(balanceOf(msg.sender) + amount < maxPerWallet, "too many");
        uint256 freeAmount = freeTaken[msg.sender] ? 0 : 1;
        require(msg.value == (amount - freeAmount) * publicPrice, "wrong price");
        _mintMany(msg.sender, amount);
        freeTaken[msg.sender] = true;
    }

    function publicFreeMint() external publicOnly enoughTokens(1) {
        uint256 _totalSupply = minted;
        require(balanceOf(msg.sender) < maxPerWallet, "too many");
        require(!freeTaken[msg.sender], "free already minted");
        _mint(msg.sender, _totalSupply);
        _totalSupply++;
        minted = _totalSupply;
        freeTaken[msg.sender] = true;
    }

    function wlMint(uint256 amount, bytes calldata signature) external payable wlOnly(signature) enoughTokens(amount) {
        require(amount > 0, "too less");
        require(balanceOf(msg.sender) + amount < maxPerWallet, "too many");
        uint256 freeAmount = freeTaken[msg.sender] ? 0 : 1;
        require(msg.value == (amount - freeAmount) * wlPrice, "wrong price");
        _mintMany(msg.sender, amount);
        freeTaken[msg.sender] = true;
    }

    function wlFreeMint(bytes calldata signature) external wlOnly(signature) enoughTokens(1) {
        uint256 _totalSupply = minted;
        require(balanceOf(msg.sender) < maxPerWallet, "too many");
        require(!freeTaken[msg.sender], "free already minted");
        _mint(msg.sender, _totalSupply);
        _totalSupply++;
        minted = _totalSupply;
        freeTaken[msg.sender] = true;
    }

    function setReserved(uint256 _teamReserved) public onlyOwner {
        teamReserved = _teamReserved;
    }

    function mintReserved(address to, uint256 amount) public onlyOwner {
        uint256 tr = teamReserved;
        require(minted + amount - 1 < PEPES_AMOUNT, "no more tokens");
        require(tr + 1 > amount, "no more reserved tokens");
        _mintMany(to, amount);
        teamReserved = tr - amount;
    }

    function setMintDate(uint256 _wlMintDate, uint256 _publicMintDate) public onlyOwner {
        wlMintDate = _wlMintDate;
        publicMintDate = _publicMintDate;
    }

    function setPrices(uint256 _wlPrice, uint256 _publicPrice) public onlyOwner {
        wlPrice = _wlPrice;
        publicPrice = _publicPrice;
    }

    function setSigner(address wlSignerAddress_) public onlyOwner {
        _wlSignerAddress = wlSignerAddress_;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function _mintMany(address to, uint256 amount) internal virtual {
        uint256 _totalSupply = minted;
        for (uint256 i; i < amount; i++) {
            _mint(to, _totalSupply);
            _totalSupply++;
        }
        minted = _totalSupply;
    }

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
