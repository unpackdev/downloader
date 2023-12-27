//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";
import "./ECDSA.sol";
import "./ERC721Enumerable.sol";

contract PudgyApes is ERC721Enumerable, Ownable, PaymentSplitter {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenId;

    uint256 public maxSupply = 8888;
    uint256 public reservedPudges = 180;
    uint256 public mintPrice = 0.05 ether;

    uint256 public maxTX = 10;
    uint256 public walletMax = 80;
    uint256 public presaleMax = 4;

    bool public presale = false;
    bool public mainsale = false;

    string public baseTokenURI;

    uint256[] private _shares = [15,15,30,15,13,12];
    address[] private _shareholders = [
        0x81Bf2Bc8119695ed2A196556e4182DaF49872163,
        0x3461895e441a1D368E04525276B96Aeb87431fe9,
        0x3584fE4F1e719FD0cC0F814a4A675181438B45DD,
        0xD9E43D71842FD22fE4423F1c41Bb8c50438d2f7D,
        0x23bB22E8E1C87a11aF14D5E8349C3E83CB2e3Fa1,
        0xB3e38814740CC61Ac717d2A0D6085a9CcbC0ca05
    ];

    address private _signer;

    event mint(uint256 tokenId, address owner);

    constructor()
        ERC721("PudgyApes", "PAFC")
        PaymentSplitter(_shareholders, _shares)
    {}

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Must use EOA");
        _;
    }

    modifier enoughFunds(uint256 _amountToMint) {
        require(msg.value >= mintPrice.mul(_amountToMint), "PudgyApes: You don't have enough ETH to mint your PudgyApes!");
        _;
    }

    modifier enoughSupply(uint256 _amountToMint) {
        require(maxSupply.sub(reservedPudges) >= _tokenId.current().add(_amountToMint), "PudgyApes: Minting would exceed max supply!");
        _;
    }

    function withdrawAll() external onlyOwner {
        for (uint256 sh = 0; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }

    function _mintMultiple(uint256 _amountToMint) private {
        for (uint256 i = 0; i < _amountToMint; i++) {
            _tokenId.increment();
            _safeMint(msg.sender, _tokenId.current());
            emit mint(_tokenId.current(), msg.sender);
        }
    }

    function isWhitelisted(bytes memory _signature) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return messageHash.recover(_signature) == _signer;
    }

    function giveawayMint(address _to, uint256 _amount) external onlyOwner {
        require(maxSupply >= _tokenId.current().add(_amount), "PudgyApes: Minting would exceed max supply!");
        
        for (uint256 i = 0; i < _amount; i++) {
            _tokenId.increment();
            _safeMint(_to, _tokenId.current());
        }
    }

    function presaleMint(uint _amount, bytes memory _signature) external payable onlyEOA enoughFunds(_amount) enoughSupply(_amount) {
        require(presale, "PudgyApes: Presale is currently paused!");
        require(isWhitelisted(_signature), "PudgyApes: You aren't whitelisted for presale!");
        require(_amount <= presaleMax, "PudgyApes: You can only mint a maximum of 4 PudgyApes at a time!");
        require(balanceOf(msg.sender).add(_amount) <= presaleMax, "PudgyApes: You can only mint a maximum of 4 PudgyApes during presale!");

        _mintMultiple(_amount);
    }

    function publicMint(uint _amount) external payable onlyEOA enoughFunds(_amount) enoughSupply(_amount) {
        require(mainsale, "PudgyApes: Mainsale is currently paused!");
        require(_amount <= walletMax, "PudgyApes: You already own the maximum amount of PudgyApes!");
        require(_amount <= maxTX, "PudgyApes: You can only mint a maximum of 10 PudgyApes at a time!");

        _mintMultiple(_amount);
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMainsale(bool _state) external onlyOwner {
        mainsale = _state;
    }

    function setPresale(bool _state) external onlyOwner {
        presale = _state;
    }

    function setSigner(address _signerAddress) external onlyOwner {
        _signer = _signerAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
