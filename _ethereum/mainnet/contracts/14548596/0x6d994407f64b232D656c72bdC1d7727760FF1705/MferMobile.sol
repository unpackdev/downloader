//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract MferMobile is ERC721A, Ownable {
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 5000;
    uint256 private constant PUBLIC_MINT_PRICE = 0.03 ether;
    uint256 private constant HOLDER_MINT_PRICE = 0.01 ether;
    uint256 private constant MAX_PER_PUBLIC_MINT = 10;

    string private _baseTokenURI;
    IERC721 private _mfersContract;
    address private _signerAddress;

    mapping(uint256 => uint256) private _mferIdMap;
    mapping(uint256 => bool) public mferMinted;
    mapping(address => bool) public freeMinted;

    constructor(address mfersContractAddress) ERC721A("MferMobile", "MM") {
        _mfersContract = IERC721(mfersContractAddress);
    }

    modifier validateSignature(bytes calldata sig) {
        require(
            keccak256(abi.encodePacked(msg.sender))
                .toEthSignedMessageHash()
                .recover(sig) == _signerAddress,
            "Invalid signature"
        );
        _;
    }

    function _holderMint(uint256 mferTokenId) private {
        require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");
        require(!mferMinted[mferTokenId], "Mfer already mferMinted");
        require(
            _mfersContract.ownerOf(mferTokenId) == msg.sender,
            "Should own the mfer"
        );
        uint256 tokenId = _currentIndex;
        _safeMint(msg.sender, 1);
        mferMinted[mferTokenId] = true;
        _mferIdMap[tokenId] = mferTokenId + 1;
    }

    function holderMint(uint256 mferTokenId) external payable {
        require(msg.value >= HOLDER_MINT_PRICE, "Insufficient funds");
        _holderMint(mferTokenId);
    }

    // free mint
    function holderMint(uint256 mferTokenId, bytes calldata signature)
        external
        payable
        validateSignature(signature)
    {
        require(!freeMinted[msg.sender], "Already free minted");
        _holderMint(mferTokenId);
        freeMinted[msg.sender] = true;
    }

    function _publicMint(uint256 quantity) private {
        require(quantity <= MAX_PER_PUBLIC_MINT, "Exceeds max per public mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(
            msg.value >= PUBLIC_MINT_PRICE * quantity,
            "Insufficient funds"
        );
        _publicMint(quantity);
    }

    // free mint
    function publicMint(uint256 quantity, bytes calldata signature)
        external
        payable
        validateSignature(signature)
    {
        require(
            quantity > 0 && msg.value >= PUBLIC_MINT_PRICE * (quantity - 1),
            "Insufficient funds"
        );
        require(!freeMinted[msg.sender], "Already free minted");
        _publicMint(quantity);
        freeMinted[msg.sender] = true;
    }

    function devMint(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    function getMferTokenId(uint256 tokenId) external view returns (uint256) {
        if (_mferIdMap[tokenId] == 0) {
            return 55555;
        }
        return _mferIdMap[tokenId] - 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(
            0x92e8975B99b3b1dcDaa6e47b67E7b290B9b1DC26,
            ((balance * 40) / 100)
        );
        _withdraw(
            0x4A458d69df6f197C2Cc14e746Ac09722aC7B9711,
            ((balance * 40) / 100)
        );
        _withdraw(msg.sender, ((balance * 15) / 100));
        _withdraw(
            0x21130E908bba2d41B63fbca7caA131285b8724F8, // unofficialmfers.eth
            address(this).balance
        );
    }
}
