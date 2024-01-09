// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract RichShibaGuild is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 5555;
    uint256 public price = 0.15 ether;

    uint256 public publicStart = 1644695940;

    address private freeMintAddress = 0xF0105d5c34ce8A84Df3551474a022dDC7fd19E28;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public paused = false;

    mapping(address => bool) canReserveToken;
    mapping(address => bool) mintedFreemint;

    address[] private team_ = [0x2FBEe863474becBe958F7ee66F8cc377Db515247, 0x567e7f90D97DD1De458C926e60242DfB42529fAd];
    uint256[] private teamShares_ = [9850, 150];

    constructor()
        ERC721A("RichShibaGuild", "RSG")
        PaymentSplitter(team_, teamShares_)
    {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmVq95pHxbDSJy9Fid7duoVkhrHTh6d4Ln89JY2MXBCsb1");
        canReserveToken[msg.sender] = true;
        _safeMint(msg.sender, 1);
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

    function freeMint(uint256 max, bytes calldata signature) external payable {
        require(paused == false, "RichShibaGuild: Contract Paused");
        uint256 supply = totalSupply();
        require(
            verifyAddressSigner(
                freeMintAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            mintedFreemint[msg.sender] == false,
            "RichShibaGuild: You already received your freemint"
        );
        require(supply + max <= maxSupply, "RichShibaGuild: SOLD OUT!");

        mintedFreemint[msg.sender] = true;

        _safeMint(msg.sender, max);
    }

    function publicSaleMint(uint256 amount) external payable {
        require(paused == false, "RichShibaGuild: Contract Paused");
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(supply + amount <= maxSupply, "RichShibaGuild: Sold out!");
        require(
            publicStart > 0 && block.timestamp >= publicStart,
            "RichShibaGuild: sale not started"
        );
        require(
            msg.value >= price * amount,
            "RichShibaGuild: Insuficient funds"
        );

        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        require(
            totalSupply() + addresses.length <= maxSupply,
            "RichShibaGuild: You can't mint more than max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function reserveTokens(uint256 amount) external {
        require(
            canReserveToken[msg.sender] == true,
            "RichShibaGuild: You are not allowed to reserve tokens"
        );
        require(
            totalSupply() + amount <= maxSupply,
            "RichShibaGuild: You can't mint mint than max supply"
        );

        _safeMint(msg.sender, amount);
    }

    // END MINT FUNCTIONS
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

    function setCanReserveToken(address _address, bool _can) public onlyOwner {
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

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setFreemint(address newFreemint) public onlyOwner {
        freeMintAddress = newFreemint;
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