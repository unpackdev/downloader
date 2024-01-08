/** 
   _____       __  __     __  __     ______   ______     ______     ______     __  __     ______     ______    
  /\ _   \    /\ \_\ \   /\ \_\ \   /\  == \ /\  ___\   /\  == \   /\  ___\   /\ \/\ \   /\  == \   /\  ___\ 
 /  /_/\__\   \ \  __ \  \ \____ \  \ \  _-/ \ \  __\   \ \  __<   \ \ \____  \ \ \_\ \  \ \  __<   \ \  __\   
 \  \_\/  /    \ \_\ \_\  \/\_____\  \ \_\    \ \_____\  \ \_\ \_\  \ \_____\  \ \_____\  \ \_____\  \ \_____\ 
  \/_____/      \/_/\/_/   \/_____/   \/_/     \/_____/   \/_/ /_/   \/_____/   \/_____/   \/_____/   \/_____/ 

**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./AddressUpgradeable.sol";

contract HyperCubeCurated is ERC721Upgradeable, OwnableUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    uint256 private constant MAX_ARTIST_CHOICE = 10;
    uint256 private constant MAX_ITEMS = 1000;

    CountersUpgradeable.Counter private _tokenIds;

    uint256 public itemStartPrice;
    uint256 public itemEndPrice;
    uint256 public totalSupply;
    uint256 public artistChoiceMinted;
    uint256 private publicSaleDuration;
    uint256 private publicSaleStartTime;
    bool public publicSale;
    string internal baseURI;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(uint256 => bool) public artistChoices;
    mapping(bytes32 => uint256) private hashToTokenId;
    address public _artistAddress;
    uint256 private _totalShares;
    address[] private _payees;
    mapping(address => uint256) private _shares;
    string[] public scripts;
    string public scriptIPFSHash;

    modifier onlyArtist() {
        require( (owner() == _msgSender() || _artistAddress == _msgSender()), "only artist or owner can call");
        _;
    }

    function initialize(string memory _tokenName, string memory _tokenSymbol) initializer public {
        __ERC721_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        totalSupply = 0;
        artistChoiceMinted = 0;
        _artistAddress = owner();
        publicSale = false;
        itemStartPrice = 0;
        itemEndPrice = 0;
        _totalShares = 0;
    }

    function startPublicSale(uint256 saleDuration, uint256 saleStartPrice, uint256 saleEndPrice) external onlyOwner {
        require(!publicSale, "Public sale has already begun");
        publicSaleDuration = saleDuration;
        itemStartPrice = saleStartPrice; // in case we need to restart after pause 
        itemEndPrice = saleEndPrice; // in case we need to restart after pause 
        publicSaleStartTime = block.timestamp;
        publicSale = true;
    }

    function pausePublicSale() external onlyOwner {
        publicSaleStartTime = 0;
        publicSale = false;
    }

    // generate hash
    function _generateHash() internal view returns (bytes32) {        
            return keccak256(abi.encodePacked(totalSupply, block.number, block.timestamp, msg.sender));
    }

    //purchase to
    function purchaseTo(address _to) public payable {
        require(publicSale, "Sale not started"); 
        require(totalSupply + 1 <= MAX_ITEMS, "MaxSupply");
        require(msg.value >= getMintPrice(), "low eth");
        _mintToken(_to, _generateHash());
    }

    //mint to with token hash, onlyArtist 
    function mintToWithHash(address _to, bytes32 _tokenHash) public onlyArtist {
        require(totalSupply + 1 <= MAX_ITEMS, "MaxSupply");
        require(hashToTokenId[_tokenHash] == 0, "hash already exists");
        require(artistChoiceMinted < MAX_ARTIST_CHOICE, "all artist choice minted"); 
        artistChoiceMinted++;
        artistChoices[totalSupply+1] = true;
        _mintToken(_to, _tokenHash);
    }

    // admin minting
    function adminMint(address _to, bytes32 _tokenHash) public onlyOwner {
        require(totalSupply + 1 <= MAX_ITEMS, "MaxSupply");
        bytes32 tokenHash = (_tokenHash.length != 64) ? _generateHash() : bytes32(_tokenHash); 
        _mintToken(_to, tokenHash);
    }

    //mint token
    function _mintToken(address _to, bytes32 _tokenHash) internal {
        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current();
        _safeMint(_to, newItemId);
        totalSupply++;
       
        tokenIdToHash[newItemId] = _tokenHash; 
        hashToTokenId[_tokenHash] = newItemId;
    }

    // Owner can fix hash if Artist uploaded incorrect one, like too short
    function fixHash(uint256 _tokenId, bytes32 _newTokenHash) public onlyOwner {
        tokenIdToHash[_tokenId] = _newTokenHash; 
    }

    //Metadata
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "!token");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    //store JS
    function addScript(string memory _script) public onlyOwner {
        scripts.push(_script);
    }

    function updateScript(uint256 _index, string memory _newScript) public onlyOwner {
        scripts[_index] = _newScript;
    }

    function setScriptIPFSHash(string memory _ipfsHash) public onlyOwner {
        scriptIPFSHash = _ipfsHash;
    } 

    //AUCTION
    function getElapsedSaleTime() internal view returns (uint256) {
        return publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
    }

    function getRemainingSaleTime() external view returns (uint256) {
        if (publicSaleStartTime == 0) {
            return 604800; //one week, means public sale has not started yet or is paused
        }
        if (getElapsedSaleTime() >= publicSaleDuration) {
            return 0;
        }
        return (publicSaleStartTime + publicSaleDuration) - block.timestamp;
    }

    function getMintPrice() public view returns (uint256) {
        if (!publicSale) {
            return 0;
        }
        uint256 elapsed = getElapsedSaleTime();
        if (elapsed >= publicSaleDuration) {
            return itemEndPrice;
        } else {
            int256 tempPrice = int256(itemStartPrice) +
                ((int256(itemEndPrice) -
                    int256(itemStartPrice)) /
                    int256(publicSaleDuration)) *
                int256(elapsed);
            uint256 currentPrice = uint256(tempPrice);
            return
                currentPrice > itemEndPrice
                    ? currentPrice
                    : itemEndPrice;
        }
    }

    // returns script code
    function projectScriptByIndex(uint256 _index) view public returns (string memory){
        return scripts[_index];
    }

    //set Artist
    function setArtist(address _newArtistAddress) public onlyOwner {
        require(_newArtistAddress != address(0), "PaymentSplitter: account is the zero address");
        _artistAddress = _newArtistAddress; 
    }

    //withdraw!
    function withdraw(uint256 amount) public onlyArtist {
        require(_totalShares != 0, "nobody to withdraw");
        for (uint256 i=0; i<_payees.length ; i++) {
            address payee = _payees[i];
            uint256 payment = amount * _shares[payee] / _totalShares;
            AddressUpgradeable.sendValue(payable(payee), payment);
        }
    }

    /**
     * @dev Add a new payee to the contract or change shares for the existing one.
     * @param account The address of the payee to add.
     * @param accShare The number of shares owned by the payee.
     */
    function _setPayee(address account, uint256 accShare) public onlyOwner {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(accShare > 0, "PaymentSplitter: shares are 0");

        if (_shares[account] == 0) {
            _payees.push(account);
        }    
        _shares[account] = accShare;
        updateShares();
    }

    function updateShares() internal {
        _totalShares = 0;
        for (uint i = 0; i < _payees.length; i++) {
            _totalShares = _totalShares + _shares[_payees[i]];
        }
    }

}