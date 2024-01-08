// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Accountable.sol";

pragma solidity ^0.8.0;

contract BunnyBuds is ERC721Enumerable, Ownable, Accountable {
    using Address for address;    
    KIA private koalas;

    uint256 public constant MAX_SUPPLY = 10000;             // One too high
    uint256 private constant MAX_KOALA_SUPPLY = 1701;       // One too high -- Checks against current tokenID index
    uint256 private constant MAX_WHITELIST_SUPPLY = 3701;   // One too high 
    uint256 private constant RESERVES = 201;                // One too high

    uint256 public saleTimeKoalas = 1633557600;             // Wednesday, October 6th, 2021 6:00 PM EST
    uint256 public saleTimeWhitelist = 1633730400;          // Friday, October 8th, 2021 6:00 PM EST
    uint256 public saleTimePublic = 1633986000;             // Monday, October 11th, 2021 5:00 PM EST
    uint256 private _maxPerTransaction = 16;                // One too high
    uint256 private _maxPerPresale = 11;                    // One too high
    uint256 private _price = 6 * 10 ** 16;                  // .06 ETH
    string private _baseTokenURI;

    mapping(address => bool) addressWhitelisted;
    mapping(address => uint256) addressToMintsUsed;

    event BunnyMinted (
        address minter,
        uint256 tokenId
    );

    constructor(
        string memory baseURI,
        address[] memory _splits,
        uint256[] memory _splitWeights,
        address _koalasAddress
    )
        ERC721("BunnyBuds", "BunnyBuds")
        Accountable(_splits, _splitWeights)
    {
        setBaseURI(baseURI);
        koalas = KIA(_koalasAddress);
    }

    modifier mintIsValid() {
        require(!address(msg.sender).isContract() && tx.origin == msg.sender, "Contracts cannot mint.");
        _;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI; 
    }

    function setPrice(uint256 _newWEIPrice) public onlyOwner {
        _price = _newWEIPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function setSaleTimeKoalas(uint256 _time) public onlyOwner {
        saleTimeKoalas = _time;
    }

    function setSaleTimeWhitelist(uint256 _time) public onlyOwner {
        saleTimeWhitelist = _time;
    }

    function setSaleTimePublic(uint256 _time) public onlyOwner {
        saleTimePublic = _time;
    }

    function setMaxPerTransaction(uint256 _max) public onlyOwner {
        _maxPerTransaction = _max;
    }

    function getMaxPerTransaction() public view returns (uint256) {
        return _maxPerTransaction;
    }

    function setMaxPerPresaleAddress(uint256 _max) public onlyOwner {
        _maxPerPresale = _max;
    }

    function getMaxPerPresaleAddress() public view returns (uint256) {
        return _maxPerPresale;
    }

    function setWhitelistAddresses(address[] memory _address) public onlyOwner {
        for (uint256 i; i < _address.length; i++) {
            addressWhitelisted[_address[i]] = true;
        }
    }

    /**
     * NOTE: This function is super weird looking and we are actually subtracting one. 
     * We are doing this because the value is always stored as one higher than it 
     * really is to avoid gte calls for whitelist max cap management however if they are
     * not whitelisted 0 is still returned.
     */
    function getPresaleMintsAvailable(address _address) public view returns (uint256) {
        if(koalas.balanceOf(_address) > 0 || addressWhitelisted[_address]) {
            return _maxPerPresale - addressToMintsUsed[_address] - 1;
        }
        else {
            return 0;
        }
    }

    function _mint(uint256 totalSupply, uint256 _count) internal {
        uint256 tokenId;
        for (uint256 i; i < _count; i++) {
            tokenId = totalSupply + i;
            _safeMint(msg.sender, tokenId);
            emit BunnyMinted(msg.sender, tokenId);
        }
    }

    /**
     * NOTE: This function allows the passing of count however a maximum cap of 40 is 
     * recommended to prevent any unexpected issues like running out of gas.
     */
    function collectReserves(uint256 _count) public onlyOwner {
        require(block.timestamp < saleTimePublic,
            "Public access already began."
        );
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < RESERVES, "Beyond max limit");

        _mint(totalSupply, _count);
    }

    function koalaMint(uint256 _count) public payable mintIsValid {
        require(koalas.balanceOf(msg.sender) > 0, "Wallet does not contain a KIA.");
        require(saleTimeKoalas < block.timestamp, "KIA presale not started.");
        require(addressToMintsUsed[msg.sender] + _count < _maxPerPresale, "Exceeds wallet presale limit.");
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < MAX_KOALA_SUPPLY, "KIA presale ended.");
        require(_price * _count == msg.value, "Transaction value incorrect.");

        addressToMintsUsed[msg.sender] += _count;
        _mint(totalSupply, _count);
        tallySplits();
    }

    function whitelistMint(uint256 _count) public payable mintIsValid {
        require(addressWhitelisted[msg.sender], "Not on whitelist.");
        require(saleTimeWhitelist < block.timestamp, "Whitelist presale not started.");
        require(addressToMintsUsed[msg.sender] + _count < _maxPerPresale, "Exceeds wallet presale limit.");
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < MAX_WHITELIST_SUPPLY, "Whitelist presale ended.");
        require(_price * _count == msg.value, "Transaction value incorrect.");

        addressToMintsUsed[msg.sender] += _count;
        _mint(totalSupply, _count);
        tallySplits();
    }

    function mint(uint256 _count) public payable mintIsValid {
        require(saleTimePublic < block.timestamp, "Sale not started.");
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < MAX_SUPPLY, "Exceeds max supply.");
        require(_count < _maxPerTransaction, "Exceeds max per transaction.");
        require(_price * _count == msg.value, "Transaction value incorrect.");

        _mint(totalSupply, _count);
        tallySplits();
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
}

abstract contract KIA {
    function balanceOf(address owner) external virtual view returns (uint256 balance);
}