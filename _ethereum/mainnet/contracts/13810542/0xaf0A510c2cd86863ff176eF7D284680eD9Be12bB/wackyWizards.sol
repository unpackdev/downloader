// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

// dev is @elbrupt on telegram

contract WackyWizards is ERC721, Ownable {
    using Strings for uint256;

    // test withdraw wallets
    address public verifiedSigner = 0xF41D419b73AC92f0f2C2135e798879CE9AB24B63;
    address private memberOne = 0x0722780e64624E45bacD4446c5B720521Da9baaB;
    address private memberTwo = 0x6562b6B31fF1dFf6972430Bc6Bd986fAAd753C42;
    address private memberThree = 0x9d3E9C35938AAFDA6e1f280D6c8286D4256e1DF6;
    address private memberFour = 0xF41D419b73AC92f0f2C2135e798879CE9AB24B63;
    address private memberFive = 0x0FFD545c46C83b8b48f7304D53610F4915afD00A;
    address private memberSix = 0xC4969a68e74b327E01F4CaD9D7d4988e1bc1567f;
    address private memberSeven = 0x2cC01f7bCDE9FF9Fa36aDb03FB34f9869B438e47;

    uint256 public NFT_MAX = 3333;
    uint256 public NFT_PRICE = 0.08 ether;
    uint256 public constant NFTS_PER_MINT = 2;
    string private _contractURI;
    string private _tokenBaseURI;
    string public _mysteryURI;

    mapping(uint256 => bool) private usedNonce;

    bool public revealed;
    bool public saleLive;
    bool public giftLive;
    bool public burnLive;

    uint256 public totalSupply;
    uint256 public totalBurnedSupply;

    constructor() ERC721("Wacky Wizards", "WZRD") {}

    function mintGiftAsOwner(uint256 tokenQuantity, address wallet)
        external
        onlyOwner
    {
        require(giftLive, "GIFTING_CLOSED");
        require(totalSupply < NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function mintGift(
        uint256 tokenQuantity,
        uint256 nonce,
        address wallet,
        bytes memory signature
    ) external {
        require(giftLive, "GIFTING_CLOSED");
        require(totalSupply < NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_PUBLIC");
        require(usedNonce[nonce] == false, "NONCE_ALREADY_USED");
        require(
            matchSigner(
                hashTransaction(nonce, wallet, tokenQuantity),
                signature
            ),
            "NOT_ALLOWED_TO_MINT"
        );
        usedNonce[nonce] = true;

        // gifts wallet input
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function mint(
        uint256 tokenQuantity,
        uint256 nonce,
        address wallet,
        bytes memory signature
    ) external payable {
        require(saleLive, "SALE_CLOSED");
        require(totalSupply < NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");
        require(NFT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        require(!usedNonce[nonce], "NONCE_ALREADY_USED");
        require(tokenQuantity <= NFTS_PER_MINT, "EXCEED_NFTS_PER_MINT");
        require(
            matchSigner(
                hashTransaction(nonce, wallet, tokenQuantity),
                signature
            ),
            "NOT_ALLOWED_TO_MINT"
        );
        usedNonce[nonce] = true;

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function hashTransaction(
        uint256 nonce,
        address wallet,
        uint256 tokenQuantity
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(nonce, wallet, tokenQuantity))
            )
        );
        return hash;
    }

    function matchSigner(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return verifiedSigner == ECDSA.recover(hash, signature);
    }

    function withdraw() external {
        uint256 currentBalance = address(this).balance;
        payable(memberOne).transfer((currentBalance * 23) / 100);
        payable(memberTwo).transfer((currentBalance * 23) / 100);
        payable(memberThree).transfer((currentBalance * 23) / 100);
        payable(memberFour).transfer((currentBalance * 15) / 100);
        payable(memberFive).transfer((currentBalance * 8) / 100);
        payable(memberSix).transfer((currentBalance * 4) / 100);
        payable(memberSeven).transfer((currentBalance * 4) / 100);
    }

    function burnMint(uint256 _tokenId) public {
        require(burnLive == true, "BURN_IS_NOT_LIVE");
        require(ownerOf(_tokenId) == msg.sender, "TOKEN_TO_BURN_NOT_BY_OWNER");
        _burn(_tokenId);
        totalBurnedSupply = totalBurnedSupply + 1;
    }

    function burnMintAsOwner(uint256 _tokenId) public onlyOwner {
        require(burnLive == true, "BURN_IS_NOT_LIVE");
        _burn(_tokenId);
        totalBurnedSupply = totalBurnedSupply + 1;
    }

    function toggleBurnStatus() external onlyOwner {
        burnLive = !burnLive;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function toggleSaleGiftStatus() external onlyOwner {
        giftLive = !giftLive;
    }

    function toggleMysteryURI() public onlyOwner {
        revealed = !revealed;
    }

    function setVerifiedSigner(address wallet) public onlyOwner {
        verifiedSigner = wallet;
    }

    function setMysteryURI(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function setPriceOfNFT(uint256 price) external onlyOwner {
        // 70000000000000000 = .07 eth
        NFT_PRICE = price;
    }

    function setNFTMax(uint256 max) external onlyOwner {
        NFT_MAX = max;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");

        if (revealed == false) {
            return _mysteryURI;
        }

        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }
}
