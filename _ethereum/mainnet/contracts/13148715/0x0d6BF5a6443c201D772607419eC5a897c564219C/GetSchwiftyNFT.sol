// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


contract GetSchwiftyNFT is ERC721Enumerable, PaymentSplitter, Ownable {

    using SafeMath for uint256;

    string private _apiURI;
    address private _owner;
    uint256 private _itemPrice;
    uint256 private _mutatePrice;
    mapping(address => uint256) private _addressMinted;

    mapping(uint256 => bool) public canBreed;
    bool public mintActive;
    bool public breedActive;
    bool public mutateActive;
    bool public presaleActive;
    uint256 public constant MAX_NFT = 10000;
    uint256 public constant MAX_SALE = 6900;
    uint256 public constant MAX_PRESALE = 420;
    uint256 public constant MAX_MINT = 25;
    
    address[] private _team = [0xd9b6897Bf82c79e6c04723B6E6B9a99a49aD47dC, 0x4ADF2Fde317cB3A3db3d16f0855f37831477C795, 0x99DB1930c6800ed26E46b870a42167d85cE08f19];
    uint256[] private _shares = [42, 42, 16];

    constructor() ERC721("Get Schwifty Club", "GSC") PaymentSplitter(_team, _shares) {
        _owner = msg.sender;
        _apiURI = "https://api-getschwifty.club/meta/";
        _itemPrice = 42000000000000000;
        _mutatePrice = 10000000000000000;
        mintActive = false;
        breedActive = false;
        mutateActive = false;
        presaleActive = false;
    }

    event Breed(uint256 indexed parentId1, uint256 indexed parentId2, uint256 indexed childId);
    event MutatePickle(uint256 indexed id);

    function withdrawAll() public onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }    

    function freeBreeds(address _address) view public returns (uint256) {
        return _addressMinted[_address];
    }

    function addFreeBreeds(address _address, uint256 amount) public onlyOwner {
        _addressMinted[_address] = _addressMinted[_address].add(amount);
    }

    function mintMultiple(uint256 amount) public payable {
        require(mintActive, "Sale is not acitve!");
        require(_itemPrice.mul(amount) == msg.value, "Insufficient ETH");
        require(amount <= MAX_MINT, "Exeeds max mints per txn!");
        require(totalSupply().add(amount) <= MAX_SALE, "Purchase would exeed max mint");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
            canBreed[totalSupply()] = true;
        }
    }

    function presaleMint(uint256 amount) public payable {
        require(presaleActive, "Presale is not active!");
        require(amount <= MAX_MINT, "Exeeds max mints per txn!");
        require(_itemPrice.mul(amount) == msg.value, "Insufficient ETH");
        require(totalSupply().add(amount) <= MAX_PRESALE, "Purchase would exeed max presale items");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
            canBreed[totalSupply()] = true;
        }
        _addressMinted[msg.sender] += amount;
    }

    function masterMint(uint256 amount) public onlyOwner {
        require(totalSupply().add(amount) <= MAX_NFT, "Purchase would exeed max items");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
            canBreed[totalSupply()] = true;
        }
    }

    function breed(uint256 id1, uint256 id2) public payable {
        require(breedActive, "Breed is not acitve!");
        require((ownerOf(id2) == msg.sender) && (ownerOf(id1) == msg.sender), "You dont own these IDs!");
        uint256 price = _itemPrice;
        if (freeBreeds(msg.sender) > 0) {
            _addressMinted[msg.sender] -= 1;
            price = 0;
        } else {
            require(price == msg.value, "Insufficient ETH");
        }
        require(canBreed[id1] && canBreed[id2], "IDs cannot breed anymore!");
        require(totalSupply() < MAX_NFT, "Breed would exeed max supply!");

        //TODO: emit event that id has been breeded with id1 and id2
        emit Breed(id1, id2, totalSupply() + 1);

        _safeMint(msg.sender, totalSupply() + 1);

        canBreed[id1] = false;
        canBreed[id2] = false;
        canBreed[totalSupply()] = true;
    }

    function mutateToPickle(uint256 id) public payable {
        require(mutateActive, "Mutation is not active!");
        require(ownerOf(id) == msg.sender, "You dont own the token!");
        require(_mutatePrice == msg.value, "Insufficient ETH");
        emit MutatePickle(id);
    }

    function setItemPrice(uint256 _price) public onlyOwner {
        _itemPrice = _price;
    }

    function setMintActive(bool _active) public onlyOwner {
        mintActive = _active;
    }

    function setBreedActive(bool _active) public onlyOwner {
        breedActive = _active;
    }

    function setMutateActive(bool _active) public onlyOwner {
        mutateActive = _active;
    }

    function setPresaleActive(bool _active) public onlyOwner {
        presaleActive = _active;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _apiURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }
}
