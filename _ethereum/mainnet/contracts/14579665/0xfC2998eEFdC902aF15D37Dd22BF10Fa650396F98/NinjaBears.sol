// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
// import "./ERC721A.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract NinjaBears is Ownable, ERC721A, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;

    // metadata URI
    string private _baseTokenURI = "ipfs://bafybeic4kaz4qf6nljilr7vwfse5s3avbkgfcebwefihg3jayeq3y6737m/bears-meta-data/";

    // Extension
    string private _extension = ".json";

    // Token Supply
    uint256 private constant _totalSupply = 6666;
    // Current Supply
    // uint256 private currentSupply;
    // Token Price
    uint256 public tokenPrice = 0.06 ether;
    // Pre Sales Price
    uint256 public preSalesPrice = 0.05 ether;

    // Max NFT number per wallet
    uint256 public immutable maxPerAddressDuringMint = 10;

    // PRESALE TIMESTAMP
    uint256 public preSaleRelease = 1649948400;

    bool public publicSaleActive = false;
    bool public preSaleActive = true;

    // Contract Owner
    address private _contractOwner;
    address private _signer;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    mapping(address => uint256) private _mintedTokens;

    constructor() ERC721A("NinjaBears", "NB") {
        _contractOwner = _msgSender();
        _signer = _msgSender();
    }

    function getCurrentPrice() public view returns (uint256) {
        if (preSaleActive) {
            return preSalesPrice;
        } else {
            return tokenPrice;
        }
    }

    function getSignerAddress(address caller, bytes calldata signature)
        internal
        pure
        returns (address)
    {
        bytes32 dataHash = keccak256(abi.encodePacked(caller));
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        return ECDSA.recover(message, signature);
    }

    function buyTokensOnPresale(uint256 tokensNumber, bytes calldata signature)
        public
        payable
    {
        require(preSaleActive, "Sale is closed at this moment");
        require(
            block.timestamp >= preSaleRelease,
            "Purchase is not available now"
        );
        require(
            tokensNumber <= maxPerAddressDuringMint,
            "You cannot purchase more than 10 tokens at once"
        );
        require(
            _mintedTokens[msg.sender].add(tokensNumber) <=
                maxPerAddressDuringMint,
            "You cannot purchase more then 10 tokens on Presale"
        );
        require(
            (tokensNumber.mul(getCurrentPrice())) <= msg.value,
            "Received value doesn't match the requested tokens"
        );
        require(
            (totalMinted().add(tokensNumber)) <= _totalSupply,
            "You try to mint more tokens than totalSupply"
        );

        address signer = getSignerAddress(msg.sender, signature);
        require(
            signer != address(0) && signer == _signer,
            "claim: Invalid signature!"
        );

        _mintedTokens[msg.sender] = _mintedTokens[msg.sender].add(tokensNumber);
        _safeMint(msg.sender, tokensNumber);
    }

    function buyTokens(uint256 tokensNumber) public payable{
        require(publicSaleActive, "Sale is closed at this moment");
        require(
            tokensNumber <= maxPerAddressDuringMint,
            "You cannot purchase more than 10 tokens at once"
        );
        require(
            _mintedTokens[msg.sender].add(tokensNumber) <=
                maxPerAddressDuringMint,
            "You cannot purchase more then 10 tokens"
        );
        require(
            (tokensNumber.mul(getCurrentPrice())) == msg.value,
            "Received value doesn't match the requested tokens"
        );
        require(
            (totalMinted().add(tokensNumber)) <= _totalSupply,
            "You try to mint more tokens than totalSupply"
        );
        _mintedTokens[msg.sender] = _mintedTokens[msg.sender].add(tokensNumber);
        // currentSupply+=tokensNumber;
        _safeMint(msg.sender, tokensNumber);
    }

    function setPreSalesRelease(uint256 _releaseTime) public onlyOwner {
        require(
            _releaseTime > block.timestamp,
            "Release time must be greater than last mined block timestamp"
        );
        preSaleRelease = _releaseTime;
    }

    // Metadata info

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function sendTokensForGiveaway(address[] memory receivers, uint _tokensNumber) public onlyOwner {
       require((totalMinted().add(receivers.length * _tokensNumber)) <= _totalSupply, "You try to mint more tokens than totalSupply");
       for(uint i = 0; i<receivers.length; i++) {
        _mintedTokens[receivers[i]] = _mintedTokens[receivers[i]].add(_tokensNumber);
        _safeMint(receivers[i], _tokensNumber);
      }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        string memory revealedURI = bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), _extension))
            : "";
        return revealedURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function triggerSaleMode() public onlyOwner {
        preSaleActive = !preSaleActive;
        publicSaleActive = !publicSaleActive;
    }

    function changeSignerAddres(address _newSigner) public onlyOwner {
        _signer = _newSigner;
    }
}
