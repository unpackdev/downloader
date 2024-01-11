// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";

contract TestPass is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenId;

    bool public paused = true;
    address private _couponOwner;
    string private constant NAME = "TestPass";
    string private constant SYMBOL = "TCP";
    string private _baseUri = "";

    event BaseUri(string _from, string _to);
    event MintPaused(bool _value);
    event CouponOwner(address _from, address _to);

    mapping(address => uint256) private whitelistClaimed;

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    constructor() ERC721(NAME, SYMBOL) {
        _couponOwner = owner();
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        emit BaseUri(_baseUri, baseURI);
        _baseUri = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function setMintPaused(bool status) public onlyOwner returns (bool) {
        emit MintPaused(status);
        paused = status;
        return true;
    }

    function setCouponOwner(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), "CouponOwner: new owner is the zero address");
        emit CouponOwner(_couponOwner, newOwner);
        _couponOwner = newOwner;
        return true;
    }

    function isValidUser(Coupon memory coupon)
        public
        view
        returns (bool)
    {
        return _isValidCoupon(msg.sender, coupon);
    }

    function hasPass(address _sender) public view returns (bool) {
        return whitelistClaimed[_sender] > 0;
    }

    function transferPass(
        address to
    ) public onlyOwner returns (uint256) {
        return _mintAction(to);
    }

    function mintPass(Coupon memory coupon)
        public
        returns (uint256)
    {
        require(_isValidCoupon(msg.sender, coupon), "Non whitelisted user");

        return _mintAction(msg.sender);
    }

    function _mintAction(address to) private returns (uint256) {
        require(paused == false, "Mint paused");

        // Existing Pass check
        require(whitelistClaimed[to] < 1, "User has Pass already");

        tokenId.increment();
        uint256 id = tokenId.current();
        whitelistClaimed[to] = id;
        _safeMint(to, id);
        return id;
    }

    function burnPass(address userAddress) public onlyOwner {
        uint256 _tokenId = whitelistClaimed[userAddress];
        super._burn(_tokenId);
    }

    /**
     * Only for test
     */
    // function getMyPass() public view returns (uint256, string memory) {
    //     uint256 _tokenId = whitelistClaimed[msg.sender];
    //     return (_tokenId, super.tokenURI(_tokenId));
    // }

    function _isValidCoupon(
        address to,
        Coupon memory coupon
    ) private view returns (bool) {
        bytes32 digest = keccak256(abi.encode(to));
        
        address signer = ECDSA.recover(digest, coupon.v, coupon.r, coupon.s);
        return (signer == _couponOwner);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        revert("Token is non-transferable");
        // super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory _data
    ) public virtual override {
        revert("Token is non-transferable");
        // super.safeTransferFrom(from, to, id, _data);
    }

    function approve(address to, uint256 id) public virtual override {
        revert("Token is non-transferable");
        // super.approve(to, id);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        revert("Token is non-transferable");
        // super.transferFrom(from, to, id);
    }
    /** end: Pass none transferable **/
}
