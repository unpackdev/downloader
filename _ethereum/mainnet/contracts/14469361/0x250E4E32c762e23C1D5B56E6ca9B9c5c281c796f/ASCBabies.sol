//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract ASCBabies is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 625;
    uint256 public price = 0.12 ether;

    address private whitelistAddress = 0x987B9d837B8c7251cb1804037D309f6bAB8f063E;

    uint256 public breedStart = 1648493940;
    uint256 public publicStart = 1648925940;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public paused = false;

    mapping(address => uint256) public tokensBreeded;

    address[] private team_ = [
        0xd21694BC0f7BFbE3ec2CE3288EFafcd91993219b,
        0x47bcB4887D59c18A981647b2c683c2f8fE8bc29f,
        0xf4812a340455e6Eda92C5272272359171539AB38,
        0x567e7f90D97DD1De458C926e60242DfB42529fAd 
    ];
    uint256[] private teamShares_ = [485, 325, 160, 30];

    constructor() ERC721A("ASCBabies", "ASCB") PaymentSplitter(team_, teamShares_) {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmXRZekto6b2FpqLXqAmAC74uKZsq8mGgf1CEZg9n8dgiy");
        _safeMint(msg.sender, 1);
    }

    modifier whenNotPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    //GETTERS

    function getBreedStart() public view returns (uint256) {
        return breedStart;
    }

    function getPublicStart() public view returns (uint256) {
        return publicStart;
    }

    function getSalePrice() public view returns (uint256) {
        return price;
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

    function setBreedStart(uint256 _newStart) public onlyOwner {
        breedStart = _newStart;
    }

    function setPublicStart(uint256 _newStart) public onlyOwner {
        publicStart = _newStart;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
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

    function breedMint(
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
            breedStart > 0 && block.timestamp >= breedStart,
            "ASC Babies: Breeding is not started yet!"
        );
        require(
                tokensBreeded[msg.sender] + amount <= max,
            "ASC Babies: You can't breed more babies"
        );
        require(
            supply + amount <= maxSupply,
            "ASC Babies: SOLD OUT !"
        );
        
        tokensBreeded[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable whenNotPaused {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(supply + amount <= maxSupply, "ASC Babies: Sold out!");
        require(
            publicStart > 0 && block.timestamp >= publicStart,
            "ASC Babies: public sale not started."
        );
        require(
            msg.value >= price * amount,
            "ASC Babies: Insuficient funds"
        );

        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + addresses.length <= maxSupply,
            "ASC Babies: You can't mint more than max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function forceMint(uint256 amount) public onlyOwner {
        require(
            totalSupply() + amount <= maxSupply,
            "ASC Babies: You can't mint more than max supply"
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