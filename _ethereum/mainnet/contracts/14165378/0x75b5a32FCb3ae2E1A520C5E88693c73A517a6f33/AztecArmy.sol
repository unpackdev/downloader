// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract AztecArmy is ERC721, Ownable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    uint256 public maxTokens;
    uint256 public maxOwnerTokens;
    uint256 public tokenPrice;
    uint public presaleTimestamp;
    uint public saleTimestamp;
    address public signer;
    string public baseUri;

    Counters.Counter private tokenCounter;
    uint256 private ownerTokenCounter;

    mapping (address => uint) presaleParticipants;

    modifier tokensAvailable() {
        require(totalSupply() < maxTokens, "Soldout");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _tokenPrice, uint256 _maxTokens, uint _maxOwnerTokens, uint _presaleTimestamp, uint _saleTimestamp, string memory _baseUri) ERC721(_name, _symbol) {
        require(_presaleTimestamp < _saleTimestamp, "presaleTimestamp >= saleTimestamp");
        require(_maxOwnerTokens <= _maxTokens, "maxOwnerTokens > maxTokens");
        maxTokens = _maxTokens;
        maxOwnerTokens = _maxOwnerTokens;
        tokenPrice = _tokenPrice;
        saleTimestamp = _saleTimestamp;
        presaleTimestamp = _presaleTimestamp;
        baseUri = _baseUri;
        signer = _msgSender();
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter.current();
    }

    function isPresaleActive() public view returns(bool) {
        return block.timestamp >= presaleTimestamp && block.timestamp < saleTimestamp;
    }

    function isSaleActive() public view returns(bool) {
        return block.timestamp >= saleTimestamp;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setPresaleTimestamp(uint _presaleTimestamp) external onlyOwner {
        require(_presaleTimestamp < saleTimestamp, "presaleTimestamp >= saleTimestamp");
        presaleTimestamp = _presaleTimestamp;
    }

    function setSaleTimestamp(uint _saleTimestamp) external onlyOwner {
        require(presaleTimestamp < _saleTimestamp, "presaleTimestamp >= saleTimestamp");
        saleTimestamp = _saleTimestamp;
    }

    function setTokenPrice(uint _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setMaxTokens(uint _maxTokens) external onlyOwner {
        require(_maxTokens >= totalSupply(), "_maxTokens < totalSupply");
        maxTokens = _maxTokens;
    }

    function mintOwnerTokens(uint256 _amount) external onlyOwner {
        ownerTokenCounter += _amount;
        require(ownerTokenCounter <= maxOwnerTokens);
        for(uint256 index = 0; index < _amount; index++) {
            mint();
        }
    }

    function mintPresaleToken(bytes memory _signature) external payable {
        address sender = _msgSender();
        uint tokensPurchased = presaleParticipants[sender];

        require(isPresaleActive(), "Presale not active");
        require(verifySignature(sender, _signature), "Invalid signature");
        require(msg.value >= tokenPrice, "Value below price");

        uint tokensToMint = msg.value / tokenPrice;
        require(tokensPurchased + tokensToMint <= 2, "Presale accounts can mint a maximum of 2 tokens");
        presaleParticipants[sender] = tokensPurchased + tokensToMint;

        for(uint index = 0; index < tokensToMint; index++) {
            mint();
        }
    }

    function mintToken() external payable {
        require(msg.sender == tx.origin, "Only EOA");
        require(isSaleActive(), "Sale not active");
        require(msg.value >= tokenPrice, "Value below price");

        uint tokensToMint = msg.value / tokenPrice;
        require(tokensToMint <= 3, "Minting in bulk is limited to 3 tokens at once");

        for(uint index = 0; index < tokensToMint; index++) {
            mint();
        }
    }

    function mint() private tokensAvailable {
        address sender = _msgSender();
        tokenCounter.increment();
        _mint(sender, totalSupply());
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed");
    }

    function tokenURI(uint256 _tokenID) override public view returns (string memory) {
        require(_tokenID > 0 && _tokenID <= totalSupply(), "query for nonexistent token");
        return string(abi.encodePacked(baseUri, Strings.toString(_tokenID), ".json"));
    }

    function verifySignature(address _sender, bytes memory _signature) public view returns (bool) {
        return keccak256(abi.encodePacked(_sender)).toEthSignedMessageHash().recover(_signature) == signer;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
}