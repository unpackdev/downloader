// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721.sol";

contract ASTROS is ERC721, Ownable {
    using Strings for uint256;

    address public signer = 0x3f75B46Ffd304d7676468a024202c01679f8ccFf;
    uint256 public price = 0.07 ether;
    bool public revealed;
    string private _mysteryURI =
        "https://untitled.mypinata.cloud/ipfs/QmeVJxwL3EQsu5PTzXqgQQGm3ijTpV5unusYz43NQtYayU/1.json";
    string private _contractURI;
    string private _tokenBaseURI;

    uint256 public supply = 5555;
    uint256 public totalSupply;
    bool public saleLive = true;

    mapping(uint256 => bool) private usedNonce;

    constructor() ERC721("ASTROS", "ASTROS") {}

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
        require(tokenQuantity <= 10, "BAD MAX PER BUY");
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
        payable(0x7F41CFb3D9241D6f968DB494Eb0a6138001390F4).transfer(
            (currentBalance * 25) / 1000
        );
        payable(0xaa6196b7BD461D3376caecbf248c9cD75cD2E3EA).transfer(
            (currentBalance * 195) / 1000
        );
        payable(0x9a2D28Af88235FfD3C818420FF70358467d4bB5C).transfer(
            (currentBalance * 110) / 1000
        );
        payable(0x46Ec7b4097fBccF6540791E35EAeb6a3ABA2e1F9).transfer(
            (currentBalance * 85) / 1000
        );
        payable(0x9a1219B330493A0DDE9d8C10C579d6fb84Ec1b8b).transfer(
            (currentBalance * 195) / 1000
        );
        payable(0x713eeD92d42dF88AB85934E7156aCDC47b9968C4).transfer(
            (currentBalance * 195) / 1000
        );
        payable(0xE5e7200a9d7F73157D1732715cA0cAA4E76690e6).transfer(
            (currentBalance * 65) / 1000
        );
        payable(0xa1053453525FFb4e460fe34BA10e8D4a37759675).transfer(
            (currentBalance * 130) / 1000
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
