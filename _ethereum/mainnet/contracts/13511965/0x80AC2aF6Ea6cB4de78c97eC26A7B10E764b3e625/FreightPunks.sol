// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";


interface IWorldOfFreight {
    function ownerOf(uint256 _tokenId) external view returns(address);
    function balanceOf(address _address) external view returns(uint256);
}

contract FreightPunks is  ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint public constant MAX_PUNKS = 10000;
    uint private PUNK_PRICE = 0.00 ether;
    uint256 private constant DEADLINE = 1636156800;
    uint256 private START = 1635530400;
    bool private WHITELIST_MINT_OPEN = false;
    uint256 private MAX_MINT = 10;
    uint256 private MAX_WHITELIST_TOTAL = 10;
    bool private PUBLIC_SALE_OPEN = false;
    address public CONTRACT_OWNER;
    address public awardAddress;
    string public PROVENANCE = "";
    string public _prefixURI;

    IWorldOfFreight public nftContract;

    constructor(address _wof) ERC721("Freight Punks", "FPUNK") {
        nftContract = IWorldOfFreight(_wof);
        CONTRACT_OWNER = msg.sender;
    }

    mapping(uint256 => bool) public tokenMint;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) private mintCount;


    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }
    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }
    //SET AWARDS ADDRESS
    function setAwardAddress(address _address) public onlyOwner {
        awardAddress = _address;
    }

    //SET START TIME
    function setStart(uint256 _time) public onlyOwner {
        START = _time;
    }

    //WHITELIST FUNCTIONS
    function setWhitelistStatus() public onlyOwner {
        WHITELIST_MINT_OPEN = !WHITELIST_MINT_OPEN;
    }
    function setMaxMintPerWallet(uint256 _amount) public onlyOwner {
        MAX_WHITELIST_TOTAL = _amount;
    }
    function setMaxMint(uint256 _amount) public onlyOwner {
        MAX_MINT = _amount;
    }

    //PUBLIC SALE FUNCTIONS
    function setPublicSaleStatus() public onlyOwner {
        PUBLIC_SALE_OPEN = !PUBLIC_SALE_OPEN;
    }
    function setPrice(uint256 _amount) public onlyOwner {
        PUNK_PRICE = _amount;
    }

    function isMintedforToken (uint256 _tokenId) public view returns (bool) {
        return tokenMint[_tokenId];
    }

    //MINTING FOR WOF HODLERS
    function mintPunk(uint256 [] memory _tokenId, uint256 _amount) public {
        require(block.timestamp >= START, 'Sorry, minting not started yet');
        require(_tokenId.length == _amount, 'Amount not equal to tokenIds amount');
        require(block.timestamp <= DEADLINE, 'Sorry, minting has ended');
        require(nftContract.balanceOf(msg.sender) >= _amount, 'You do not own enough WOF NFT-s');
        for (uint i = 0; i < _amount; i++) {
            require(tokenMint[_tokenId[i]] == false, 'Punk already minted for this NFT');
            require(nftContract.ownerOf(_tokenId[i]) == msg.sender, 'You do not own this token');
            tokenMint[_tokenId[i]] = true;
            _mintItem(msg.sender);
        }
    }

    //ADD TO WHITELIST
    function addToWhitelist(address [] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    //WHITELIST MINTING
    function whitelistMint(uint256 _amount) public {
        require(WHITELIST_MINT_OPEN == true, 'Minting not open');
        require(whitelist[msg.sender] == true, 'You are not on whitelist');
        require(_amount <= MAX_MINT, 'Can not mint this much');
        require(MAX_WHITELIST_TOTAL >= mintCount[msg.sender], 'Max mints per wallet achieved');
        for (uint i = 0; i < _amount; i++) {
            _mintItem(msg.sender);
        }
        mintCount[msg.sender] = mintCount[msg.sender].add(_amount);
    }

    //OPEN MINTING
    function openMint(uint256 _amount) public payable {
        require(PUBLIC_SALE_OPEN == true, 'Minting not open');
        require(_amount <= MAX_MINT, 'Can not mint this much');
        require(msg.value >= PUNK_PRICE , 'Send more eth');
        for (uint i = 0; i < _amount; i++) {
            _mintItem(msg.sender);
        }
    }

    //REWARDS TO MANY
    function airdropMany(address [] memory _rewardee) public {
        require(msg.sender == CONTRACT_OWNER || msg.sender ==  awardAddress, 'Not permitted');
        require(totalSupply().add(_rewardee.length) <= MAX_PUNKS, 'Exeeds max');
        for (uint i = 0; i < _rewardee.length; i++) {
             _mintItem(_rewardee[i]);
        }
    }

    //REWARD TO SINGLE
    function airDrop(address _to, uint256 _amount) public {
        require(msg.sender == CONTRACT_OWNER || msg.sender ==  awardAddress, 'Not permitted');
        require(totalSupply().add(_amount) <= MAX_PUNKS, 'Exeeds max');
        for (uint i = 0; i < _amount; i++) {
            _mintItem(_to);
        }
    }

    //SINGLE MINTING FUNCTION
    function _mintItem(address _to) internal returns (uint256) {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        require(id <= MAX_PUNKS, 'Max already minted');
        _safeMint(_to, id);
        return id;
    }

    function withdrawAmount(address payable to, uint256 amount) public onlyOwner {
        require(msg.sender == CONTRACT_OWNER);
        to.transfer(amount); 
    }
}