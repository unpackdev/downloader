// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";

import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";

contract EasyDAO is ERC721AQueryable, Ownable, ReentrancyGuard  {
    using ECDSA for bytes32;

    uint256 public MaxSupply;
    uint256 public MaxReserveMint;

    uint256 public whiteListMintPrice = 0.2 ether;

    address public royaltyAddress;
    uint256 public royaltyPercent;

    bytes32 public root;
    address public vault;
    string public _baseTokenURI;

    constructor(uint256 _MaxSupply, uint256 _MaxReserveMint, address _vault)
        ERC721A("Easy DAO Pass", "EDP")
    {
        royaltyAddress = owner();
        royaltyPercent = 10;
        MaxSupply = _MaxSupply;
        MaxReserveMint = _MaxReserveMint;
        vault = _vault;
    }
    
    modifier eoaOnly() {
        require(tx.origin == msg.sender, "EOA Only");
        _;
    }

    function whiteListMint(bytes32[] memory _proof)
        external
        payable
        nonReentrant
        eoaOnly
    {

        require(numberMinted(msg.sender) == 0, "Already mint Easy DAO Pass");

        require(_whitelistVerify(_proof), "Invalid merkle proof");

        require(totalSupply() <= MaxSupply, "Exceed max token supply");

        _safeMint(msg.sender, 1);

        makeChange(whiteListMintPrice);
    }

    function reserveMint(address _reserveAddr, uint256 quantity)
        external
        onlyOwner
    {
        require(
            totalSupply() + quantity <= MaxSupply,
            "Exceed max token supply"
        );
        require(quantity <= MaxReserveMint, "Exceed max reserve supply");

        MaxReserveMint -= quantity;

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(_reserveAddr, 1);
        }
    }

    function makeChange(uint256 _price) private {
        require(msg.value >= _price, "Insufficient ether amount");
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    function _whitelistVerify(bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non-existent token");
        return (royaltyAddress, (salePrice * royaltyPercent) / 100);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setWhiteListMintPrice(uint256 _price) public onlyOwner {
        whiteListMintPrice = _price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(vault).transfer(balance);
    }

    function setVault(address _vault) public onlyOwner {
        vault = _vault;
    }

    function setRoyaltyReceiver(address royaltyReceiver) public onlyOwner {
        royaltyAddress = royaltyReceiver;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage) public onlyOwner {
        royaltyPercent = royaltyPercentage;
    }

}