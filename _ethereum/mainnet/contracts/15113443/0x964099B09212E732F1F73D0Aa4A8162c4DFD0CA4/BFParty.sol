// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract BFParty is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint16 constant MAX_SUPPLY = 8888;
    uint8 constant MAX_FREE_MINT = 1;
    uint8 constant MAX_WL_MINT = 1;

    uint8 public MAX_PUBLIC_MINT = 3;
    uint256 public WL_MINT_PRICE = 0.169 ether;
    uint256 public PUBLIC_MINT_PRICE = 0.2 ether;
    address public FUND_WALLET = 0x2eC9A9a67c80DaDDfBcbEBc7A152496C25bD3a03;
    address public TECH_WALLET = 0x6f0E887dd23dEB37d7804fCB8EF4285a93DA485a;

    mapping(address => uint256) public minted;

    address public signerAddress = 0x0dE743245FeB4b1872e5D7E34654C34b2b652C11;

    string public baseUri;

    constructor(string memory uri) ERC721A("BFParty", "BFP") {
        baseUri = uri;
    }

    function setSignerAddress(address newAddress) external onlyOwner {
        signerAddress = newAddress;
    }

    function setBaseUri(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setWlMintPrice(uint256 price) external onlyOwner {
        WL_MINT_PRICE = price;
    }

    function setPublicMintPrice(uint256 price) external onlyOwner {
        PUBLIC_MINT_PRICE = price;
    }

    function setFundWallet(address wallet) external onlyOwner {
        require(wallet != address(0x0), "Invalid Wallet");
        FUND_WALLET = wallet;
    }

    function setTechWallet(address wallet) external onlyOwner {
        require(wallet != address(0x0), "Invalid Wallet");
        TECH_WALLET = wallet;
    }

    function setMaxPublicMint(uint8 amount) external onlyOwner {
        MAX_PUBLIC_MINT = amount;
    }

    function withdraw() external onlyOwner {
        //50% to be distributed to tech and founder
        uint256 funds = address(this).balance / 2;
        //18% to tech
        (bool successTech, ) = TECH_WALLET.call{value: (funds * 180) / 1000}("");
        //remaining to fund wallet
        funds = address(this).balance;
        (bool successFunds, ) = FUND_WALLET.call{value: funds}("");
        require(
            successTech || successFunds,
            "withdrawal unsuccessful for all."
        );
    }

    function safeMint(address to, uint256 quantity) internal {
        require(quantity + totalSupply() <= MAX_SUPPLY, "Max supply exceeded.");
        _safeMint(to, quantity);
    }

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        safeMint(to, quantity);
    }

    function hashTransaction(address sender, string memory txnType)
        internal
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, txnType))
            )
        );
        return hash;
    }

    function publicMint(bytes memory signature, uint256 quantity)
        external
        payable
    {
        require(
            signerAddress ==
                hashTransaction(msg.sender, "PM").recover(signature),
            "Direct minting disallowed"
        );
        require(
            minted[msg.sender] + quantity <= MAX_PUBLIC_MINT,
            "Public mint quota exceeded."
        );
        require(PUBLIC_MINT_PRICE * quantity == msg.value, "Incorrect Payment");
        minted[msg.sender] += quantity;
        safeMint(msg.sender, quantity);
    }

    function whitelistMint(bytes memory signature) external payable {
        require(
            signerAddress ==
                hashTransaction(msg.sender, "WM").recover(signature),
            "Direct minting disallowed"
        );
        require(
            minted[msg.sender] + 1 <= MAX_WL_MINT,
            "Whitelist mint quota exceeded."
        );
        require(WL_MINT_PRICE == msg.value, "Incorrect Payment");
        minted[msg.sender] += 1;
        safeMint(msg.sender, 1);
    }

    function freeMint(bytes memory signature) external {
        require(
            signerAddress ==
                hashTransaction(msg.sender, "FM").recover(signature),
            "Direct minting disallowed"
        );
        require(
            minted[msg.sender] + 1 <= MAX_FREE_MINT,
            "Free mint quota exceeded."
        );
        minted[msg.sender] += 1;
        safeMint(msg.sender, 1);
    }
}
