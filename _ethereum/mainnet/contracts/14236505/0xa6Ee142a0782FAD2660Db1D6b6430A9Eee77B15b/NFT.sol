// SPDX-License-Identifier: MIT

/**
ERC-721A contract made by 0x0000
TG: @jacko06v

 */

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract Contract is ERC721A, Ownable {
    address constant WALLET1 = 0x00000000000B186EbeF1AC9a27C7eB16687ac2A9; // 0x0000
    address constant WALLET2 = 0xBcC340f346B9e33Fbe91fAd2795175fbe1591a62; // Mythical Beings Team
    address constant WALLET3 = 0xaAD198caBbbCBca1AF0590D71b51F155216DAE8F; // Valeriya (Artist)
    uint256 constant SHARE1 = 1; // standard 0x0000 share
    uint256 constant SHARE2 = 97;
    uint256 constant SHARE3 = 2;
    uint256 public maxPerWallet = 500; // e.g. 5 per wallet in pre-sale
    uint256 public maxPerTransaction = 10; // e.g. 10 per transaction in public sale
    uint256 public preSalePrice = 0.04 * 10**18;
    uint256 public pubSalePrice = 0.05 * 10**18;
    uint256 public maxSupply = 2222; // e.g. 10000
    bool public preSaleIsActive = true;
    bool public saleIsActive = false;
    string _baseTokenURI;

    bytes32 public root =
        0xc97c0799b39ba3c5ccb2b3689d03e64ae0669d38e50201aebe0c7258154fb572;

    mapping(address => uint256) public presaleQuantity;

    constructor() ERC721A("Mythical Beings", "BEINGS") {}

    function changeRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setPreSalePrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    function setPubSalePrice(uint256 _price) external onlyOwner {
        pubSalePrice = _price;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseTokenURI(),
                    Strings.toString(_tokenId)
                    
                )
            );
    }

    function setMaxPerWallet(uint256 _maxToMint) external onlyOwner {
        maxPerWallet = _maxToMint;
    }

    function setMaxPerTransaction(uint256 _maxToMint) external onlyOwner {
        maxPerTransaction = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function reserve(address _address, uint256 _quantity) public onlyOwner {
        _safeMint(_address, _quantity);
    }

    function mint(uint256 _quantity) public payable {
        uint256 currentSupply = totalSupply();
        require(saleIsActive, "Sale is not active.");
        require(msg.value > 0, "Must send ETH to mint.");
        require(currentSupply <= maxSupply, "Sold out.");
        require(!preSaleIsActive, "Presale active");
        require(
            currentSupply + _quantity <= maxSupply,
            "Requested quantity would exceed total supply."
        );

        require(
            pubSalePrice * _quantity <= msg.value,
            "ETH sent is incorrect."
        );
        require(
            _quantity <= maxPerTransaction,
            "Exceeds per transaction limit."
        );

        _safeMint(msg.sender, _quantity);
    }

    function mintPresale(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
    {
        uint256 currentSupply = totalSupply();
        require(saleIsActive, "Sale is not active.");
        require(msg.value > 0, "Must send ETH to mint.");
        require(currentSupply <= maxSupply, "Sold out.");
        require(preSaleIsActive, "Presale ended");
        require(
            currentSupply + _quantity <= maxSupply,
            "Requested quantity would exceed total supply."
        );

        require(
            preSalePrice * _quantity <= msg.value,
            "ETH sent is incorrect."
        );
        require(
            _quantity <= maxPerWallet,
            "Exceeds per wallet pre-sale limit."
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, root, leaf),
            "Invalid Merkle Proof."
        );
        require(
            presaleQuantity[msg.sender] + _quantity <= maxPerWallet,
            "Exceeds per wallet pre-sale limit."
        );
        presaleQuantity[msg.sender] = presaleQuantity[msg.sender] + _quantity;

        _safeMint(msg.sender, _quantity);
    }

    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 wallet1Balance = (totalBalance * SHARE1) / 100;
        uint256 wallet2Balance = (totalBalance * SHARE2) / 100;
        uint256 wallet3Balance = (totalBalance * SHARE3) / 100;
        payable(WALLET1).transfer(wallet1Balance);
        payable(WALLET2).transfer(wallet2Balance);
        payable(WALLET3).transfer(wallet3Balance);
        uint256 transferBalance = totalBalance -
            (wallet1Balance + wallet2Balance + wallet3Balance);
        payable(msg.sender).transfer(transferBalance);
    }
}
