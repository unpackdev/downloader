//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Invisiverse is ERC721URIStorage, Ownable {
    event MintInvisiverse(
        address indexed minter,
        uint256 startWith,
        uint256 times
    );

    uint256 public totalInvisiverse;
    uint256 public totalCount = 4010;
    uint256 public psMAX = 2500;
    uint256 public maxBatch = 30;
    uint256 public WLprice = 0.07 ether;
    uint256 public price = 0.12 ether;
    uint256 public WHITELIST_LIMIT = 3;
    string public baseURI;
    bytes32 public whitelistRoot;
    bool public started;
    bool public whiteListStart;
    mapping(address => uint256) whiteListMintCount;
    uint256 addressRegistryCount;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        bytes32 whitelistRoot_
    ) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        whitelistRoot = whitelistRoot_;
    }

    function totalSupply() public view virtual returns (uint256) {
        return totalInvisiverse;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setWhitelistLimit(uint256 newLimit) public onlyOwner {
        WHITELIST_LIMIT = newLimit;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
        setRoot(newMerkleRoot);
    }

    function setPresaleTotal(uint256 newMax) public onlyOwner {
        require(newMax <= totalCount, "cant be above supply bro");
        psMAX = newMax;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function changeWLPrice(uint256 _newPrice) public onlyOwner {
        WLprice = _newPrice;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setNormalStart(bool _start) public onlyOwner {
        started = _start;
    }

    function setWhiteListStart(bool _start) public onlyOwner {
        whiteListStart = _start;
    }

    function getWhitelistMintAmount(address _addr)
        public
        view
        virtual
        returns (uint256)
    {
        return whiteListMintCount[_addr];
    }

    function MintInvisiverses(uint256 _times) public payable {
        require(started, "not started");
        require(_times > 0 && _times <= maxBatch, "mint wrong number");
        require(totalInvisiverse + _times <= totalCount, "too much");
        require(msg.value == _times * price, "value error");
        payable(owner()).transfer(msg.value);
        emit MintInvisiverse(_msgSender(), totalInvisiverse + 1, _times);
        for (uint256 i = 0; i < _times; i++) {
            _mint(_msgSender(), 1 + totalInvisiverse++);
        }
    }

    function adminMint(uint256 _times) public payable onlyOwner {
        require(_times > 0 && _times <= maxBatch, "mint wrong number");
        require(totalInvisiverse + _times <= totalCount, "too much");
        emit MintInvisiverse(_msgSender(), totalInvisiverse + 1, _times);
        for (uint256 i = 0; i < _times; i++) {
            _mint(_msgSender(), 1 + totalInvisiverse++);
        }
    }

    function whitelistMint(uint256 _times, bytes32[] calldata proof)
        public
        payable
    {
        require(isWhitelisted(msg.sender, proof), "You are not white listed");
        require(whiteListStart, "Hang on boys, youll get in soon");
        if (whiteListMintCount[msg.sender] == 0) {
            whiteListMintCount[msg.sender] = WHITELIST_LIMIT + 1;
        }
        require(
            whiteListMintCount[msg.sender] - _times >= 1,
            "Over mint limit for address."
        );
        require(
            totalInvisiverse + _times <= psMAX,
            "Mint amount will exceed total presale amount."
        );
        require(msg.value == _times * WLprice, "Incorrect transaction value.");
        payable(owner()).transfer(msg.value);
        whiteListMintCount[_msgSender()] -= _times;
        emit MintInvisiverse(_msgSender(), totalInvisiverse + 1, _times);
        for (uint256 i = 0; i < _times; i++) {
            _mint(_msgSender(), 1 + totalInvisiverse++);
        }
    }

    function isWhitelisted(address toCheck, bytes32[] calldata proof)
        public
        view
        returns (bool _isWhitelisted)
    {
        bytes32 node = keccak256(abi.encodePacked(toCheck));
        MerkleProof.verify(proof, whitelistRoot, node)
            ? (_isWhitelisted = true)
            : (_isWhitelisted = false);
        return _isWhitelisted;
    }

    function setRoot(bytes32 newMerkleRoot) internal {
        whitelistRoot = newMerkleRoot;
    }

    function adminMintGiveaways(address _addr) public onlyOwner {
        require(
            totalInvisiverse + 1 <= totalCount,
            "Mint amount will exceed total collection amount."
        );
        emit MintInvisiverse(_addr, totalInvisiverse + 1, 1);
        _mint(_addr, 1 + totalInvisiverse++);
    }

    function adminMintGiveawayBatch(address[] memory _addr) public onlyOwner {
        require(_addr.length <= 30, "try smaller batch");
        require(
            totalInvisiverse + _addr.length <= totalCount,
            "Mint amount will exceed total collection amount."
        );
        for (uint256 i = 0; i < _addr.length; i++) {
            emit MintInvisiverse(_addr[i], totalInvisiverse + 1, 1);
            _mint(_addr[i], 1 + totalInvisiverse++);
        }
    }
}