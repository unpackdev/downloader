//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract MusicBearAwards is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 3664;
    uint256 public price = 0.1664 ether;
    uint256 public presalePrice = 0.1464 ether;

    address private whitelistAddress = 0x2b7bA9aAC5B0b7706a7888343fE119509E2939De;

    uint256 public presaleStart = 1649001480;
    uint256 public presaleEnd = 1649005080;
    uint256 public publicStart = 1649003280;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public paused = false;

    mapping(address => uint256) public tokensMinted;

    address[] private team_ = [
        0xFc7A7A40D326836a39D114E181d53aBD28744BBD,
        0x7601683aD8Db1163fcf88166A93619791a299c33,
        0x64C6B5BE522d398D1411f8187877F7bf4dB62e8C,
        0x1594B2F826291640be81C097BbF0b375E2C5497c,
        0x177d750556bBB8a3a6f98b8BA87517696CC0BC4B

    ];
    uint256[] private teamShares_ = [480,480,10,10,20];

    constructor() ERC721A("MusicBearAwards", "MBA") PaymentSplitter(team_, teamShares_) {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmNVRMhZrUW6MVGe8QGRFbze2apmb3Vbm4rJLPiAk6SRBK");
        _safeMint(msg.sender, 1);
    }

    modifier whenNotPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    //GETTERS

    function getPresaleStart() public view returns (uint256) {
        return presaleStart;
    }

    function getPublicStart() public view returns (uint256) {
        return publicStart;
    }

    function getPresaleEnd() public view returns (uint256) {
        return presaleEnd;
    }

    function getSalePrice() public view returns (uint256) {
        return price;
    }

    function getPresalePrice() public view returns (uint256) {
        return presalePrice;
    }

    //END GETTERS

    //SETTERS

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelistAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        whitelistAddress = _newAddress;
    }

    function setPresaleStart(uint256 _newStart) public onlyOwner {
        presaleStart = _newStart;
    }

    function setPublicStart(uint256 _newStart) public onlyOwner {
        publicStart = _newStart;
    }

    function setPresaleEnd( uint256 _newEnd) public onlyOwner {
        presaleEnd = _newEnd;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function switchPause() public onlyOwner {
        paused = !paused;
    }

    //END SETTERS

    //SIGNATURE VERIFICATION

    function verifyAddressSigner(
        address referenceAddress,
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            referenceAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(uint256 number, address sender)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(number, sender));
    }

    //END SIGNATURE VERIFICATION

    //MINT FUNCTIONS

    function presaleMint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable whenNotPaused {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one token");
        require(
            verifyAddressSigner(
                whitelistAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            presaleStart > 0 && block.timestamp >= presaleStart,
            "Music Bear Awards: Whitelist mint is not started yet!"
        );
        require(
            presaleEnd > 0 && block.timestamp < presaleEnd,
            "Music Bear Awards: Whitelist mint is finished!"
        );
        require(
                tokensMinted[msg.sender] + amount <= max,
            "Music Bear Awards: You can't mint more NFTs!"
        );
        require(
            supply + amount <= maxSupply,
            "Music Bear Awards: SOLD OUT !"
        );
        require(
            msg.value >= presalePrice * amount,
            "Music Bear Awards: Insuficient funds"
        );

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable whenNotPaused {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(supply + amount <= maxSupply, "Music Bear Awards: Sold out!");
        require(
            publicStart > 0 && block.timestamp >= publicStart,
            "Music Bear Awards: public sale not started."
        );
        require(
            msg.value >= price * amount,
            "Music Bear Awards: Insuficient funds"
        );

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + addresses.length <= maxSupply,
            "Music Bear Awards: You can't mint more than max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function forceMint(uint256 amount) public onlyOwner {
        require(
            totalSupply() + amount <= maxSupply,
            "Music Bear Awards: You can't mint more than max supply"
        );

        _safeMint(msg.sender, amount);
    }

    // END MINT FUNCTIONS

    // FACTORY

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }
}
