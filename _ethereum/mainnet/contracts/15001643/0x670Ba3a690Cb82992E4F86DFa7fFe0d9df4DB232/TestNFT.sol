// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC2981.sol";

contract Pass {
    function hasPass(address) public view returns (bool) {}
}

contract TestNFT is ERC721, ERC2981, Ownable {
    Pass pass;
    bool public paused = true;
    uint256 public mintPrice = 0.00001 ether; // ETH
    string private _contractURI;

    using Counters for Counters.Counter;
    Counters.Counter private tokenId;
    Counters.Counter private reservedCount;
    address private _couponOwner;
    address private _accountOwner;
    uint256 public constant MAX_SUPPLY = 6000;
    uint256 public constant RESERVED_SUPPLY = 250; 
    uint256 public constant PER_USER_SUPPLY = 1; 
    uint96 private constant _royaltyFeesInBips = 1000; // 10 % ???? confirm
    string private _baseUri = "";
    mapping(address => Counters.Counter) private whitelistClaimed;

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct CouponData {
        uint256 expire;
    }

    constructor() ERC721("TestNFT", "TCN") {
        _couponOwner = owner();
        _accountOwner = owner();
        setRoyaltyInfo(owner());
    }

    function connectPass(address _pass) public onlyOwner {
        pass = Pass(_pass);
    }

    function hasPass() public view returns (bool) {
        return pass.hasPass(msg.sender);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseUri = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function setContractURI(string calldata URI) public onlyOwner {
        _contractURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setRoyaltyInfo(address _receiver)
        public
        onlyOwner
    {
        super._setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setMintPaused(bool status) public onlyOwner returns (bool) {
        paused = status;
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 _tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, _tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function setCouponOwner(address newOwner) public onlyOwner returns (bool) {
        _couponOwner = newOwner;
        return true;
    }

    function setAccountOwner(address newOwner) public onlyOwner returns (bool) {
        _accountOwner = newOwner;
        return true;
    }

    function isValidUser(CouponData memory meta, Coupon memory coupon)
        public
        view
        returns (bool)
    {
        return _isValidCoupon(msg.sender, meta, coupon);
    }

    function _isValidCoupon(address to, CouponData memory meta, Coupon memory coupon)
        private
        view
        returns (bool)
    {
        require(block.timestamp < meta.expire, "Coupon expired");

        bytes32 digest = keccak256(abi.encode(to, meta.expire));
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        return (signer == _couponOwner);
    }

    function transferToken(address to) public onlyOwner returns (bool) {
        require(
            reservedCount.current() < RESERVED_SUPPLY,
            "Maximum reserved supply reached"
        );

        _mintAction(to);
        reservedCount.increment();
        return true;
    }

    function _mintAction(address to)
        private
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        require(paused == false, "Mint paused");

        require(tokenId.current() < MAX_SUPPLY, "Maximum supply reached");

        tokenId.increment();
        uint256 newId = tokenId.current();
        _safeMint(to, newId);
        whitelistClaimed[to].increment();
        string memory newURI = super.tokenURI(newId);
        return (newId, newURI, whitelistClaimed[to].current());
    }

    function claimedCount()
        public
        view
        returns (uint256)
    {
        return whitelistClaimed[msg.sender].current();
    }

    function mintNFT(CouponData memory meta, Coupon memory coupon)
        public
        payable
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        require(
            tokenId.current() + 1 <= (MAX_SUPPLY - RESERVED_SUPPLY),
            "Maximum supply reached"
        );

        require(
            whitelistClaimed[msg.sender].current() < PER_USER_SUPPLY,
            "Per user supply reached"
        );

        require(_isValidCoupon(msg.sender, meta, coupon), "None whitelisted user");

        require(msg.value >= mintPrice, "Not enough eth sent.");

        require(hasPass(), "No pass found");

        return _mintAction(msg.sender);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "balance is 0 ");
        payable(_accountOwner).transfer(address(this).balance);
    }
}
