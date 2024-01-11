// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721.sol";

contract ASTROSALIENS is ERC721, Ownable {
    using Strings for uint256;

    address public signer = 0xF9eD343A8426279255ddbCdbf57a97DA66701069;
    uint256 public price = 0 ether;
    bool public revealed = true;
    string private _mysteryURI;
    string private _contractURI =
        "https://untitled.mypinata.cloud/ipfs/QmakK2SmJanR6Tr8jTVKvuCKVpgLtqFnkG81FMsss74fVF/";
    string private _tokenBaseURI =
        "https://untitled.mypinata.cloud/ipfs/QmakK2SmJanR6Tr8jTVKvuCKVpgLtqFnkG81FMsss74fVF/";

    uint256 public supply = 1000;
    uint256 public totalSupply;
    bool public saleLive = true;

    mapping(uint256 => bool) private usedNonce;

    constructor() ERC721("ASTROSALIENS", "ASTROSALIENS") {}

    function mintGiftOwner(uint256 tokenQuantity, address wallet)
        external
        onlyOwner
    {
        require(totalSupply + tokenQuantity <= supply, "BAD SUPPLY");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function mint(
        uint256 tokenQuantity,
        uint256 nonce,
        bytes memory signature
    ) external payable {
        require(saleLive, "SALE_CLOSED");
        require(tokenQuantity <= 2, "BAD MAX PER BUY");
        require(!usedNonce[nonce], "BAD NONCE");
        require(price * tokenQuantity <= msg.value, "BAD PRICE");
        require(totalSupply + tokenQuantity <= supply, "BAD MAX SUPPLY");

        require(
            matchSigner(hashTransaction(nonce), signature),
            "NOT ALLOWED TO MINT"
        );

        usedNonce[nonce] = true;

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function hashTransaction(uint256 nonce) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(nonce))
            )
        );
        return hash;
    }

    function matchSigner(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return signer == ECDSA.recover(hash, signature);
    }

    function withdraw() external {
        uint256 currentBalance = address(this).balance;
        payable(0xF9eD343A8426279255ddbCdbf57a97DA66701069).transfer(
            (currentBalance * 1000) / 1000
        );
    }

    function switchMysteryURI() public onlyOwner {
        revealed = !revealed;
    }

    function switchSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function newMysteryURI(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function newPriceOfNFT(uint256 priceNew) external onlyOwner {
        price = priceNew;
    }

    function newContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function newBaseURI(string calldata URI) external onlyOwner {
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
