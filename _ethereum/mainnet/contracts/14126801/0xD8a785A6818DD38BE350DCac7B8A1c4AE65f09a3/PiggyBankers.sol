// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract PiggyBankers is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 7777;
    uint256 public price = 0.29 ether;

    uint256 public presaleStart = 1643815740;
    uint256 public publicStart = 1643817540;

    address private presaleAddress = 0xC1aA8a41daBb016C4D369116f5Ae111fC3576D55;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public paused = false;

    mapping(address => bool) canReserveToken;
    mapping(address => bool) public premintClaimed;

    address[] private team_ = [0x27D3c66e0CA3ea5C5e8c1A68c3eBA6e195324C8C,0x567e7f90D97DD1De458C926e60242DfB42529fAd];
    uint256[] private teamShares_ = [98,2];

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri)
        ERC721A("PiggyBankers", "PB")
        PaymentSplitter(team_, teamShares_)
    {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        canReserveToken[msg.sender] = true;
    }

    //GETTERS

    function getSalePrice() public view returns (uint256) {
        return price;
    }

    //END GETTERS

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
    ) external payable {
        require(paused == false, "PiggyBankers: Contract Paused");
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one token");
        require(
            verifyAddressSigner(
                presaleAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            presaleStart > 0 && block.timestamp >= presaleStart,
            "PiggyBankers: presale not started"
        );
        require(amount <= max, "PiggyBankers: You can't mint more tokens at presale!");
        require(supply + amount <= maxSupply, "PiggyBankers: SOLD OUT!");
        require(msg.value >= price * amount, "PiggyBankers: INVALID PRICE");

        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require(paused == false, "PiggyBankers: Contract Paused");
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(supply + amount <= maxSupply, "PiggyBankers: Sold out!");
        require(
            publicStart > 0 && block.timestamp >= publicStart,
            "PiggyBankers: sale not started"
        );
        require(msg.value >= price * amount, "PiggyBankers: Insuficient funds");

        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        require(
            totalSupply() + addresses.length <= maxSupply,
            "PiggyBankers: You can't mint more than max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function reserveTokens(uint256 amount) external {
        require(canReserveToken[msg.sender] == true, "PiggyBankers: You are not allowed to reserve tokens");
        require(totalSupply() + amount <= maxSupply, "PiggyBankers: You can't mint mint than max supply");

        _safeMint(msg.sender, amount);
    }

    // END MINT FUNCTIONS

    function setPresaleStart(uint256 _start) external onlyOwner {
        presaleStart = _start;
    }

    function setSaleStart(uint256 _start) external onlyOwner {
        publicStart = _start;
    }

    function pauseSale() external onlyOwner {
        paused = true;
    }

    function unpauseSale() external onlyOwner {
        paused = false;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setCanReserveToken(address _address, bool _can) public onlyOwner{
        canReserveToken[_address] = _can;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

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
