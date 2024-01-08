// SPDX-License-Identifier: MIT
// View our Original CryptoTitties Contract 2018-01-04 13:55:13 ( • )( • ) 0xb39D10435D7D0F2ea26a1C86c42Be0FD8a94f59B
pragma solidity >=0.4.22 <0.9.0;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ICryptoTittyV1.sol";

contract CryptoTittiesV3 is OwnableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIds;

    struct Titty {
        string name;
        uint256 originalPrice;
        uint256 salePrice;
        bool forSale;
    }

    mapping (uint => Titty) Titties;

    // Instance of cryptotitty smart contract
    ICryptoTittyV1 private tittyContract;

    uint256 public _max_supply;

    address payable cttWallet;
    address payable cttBoat;

    event Sellable(address _owner, uint _tittyId, bool _forSale);
    event ChangedName(address _owner, uint _tittyId, string _name);
    event ChangedPrice(address _owner, uint _tittyId, uint _price);
    event NotSellable(address _owner, uint _tittyId, bool _forSale);

    /**
     * @dev Initializes the contract settings
     */
    function initialize(address _tittyContract, address _cttWallet, address _cttBoat)
        public initializer
        
    {
        __Ownable_init();

        tittyContract = ICryptoTittyV1(_tittyContract);
        cttWallet = payable(_cttWallet);
        cttBoat = payable(_cttBoat);
        _max_supply = 144;
        
        __ERC721_init("CryptoTitties", "CT");

    }

    /**
     * @dev Gets address of cryptotitty smart contract
     */
    function getTittyContract()
        public
        view
        returns (address)
    {
        return address(tittyContract);
    }

    function totalSupply() public view returns (uint256) {
        return _max_supply;
    }

    /**
     * @dev Triggers smart contract to stopped state
     */
    function pause()
        public
        onlyOwner
    {
        _pause();
    }

    /**
     * @dev Returns smart contract to normal state
     */
    function unpause()
        public
        onlyOwner
    {
        _unpause();
    }

    /**
     * @dev Mint a new titty
     */
    function mintNew(uint256 _price, uint256 _tittyId, string memory _name, string memory _tokenURI)
        public
        whenNotPaused 
        onlyOwner
    {
        uint256 lastItemId = _tokenIds.current();
        require(lastItemId + 1 <= _max_supply, "It can only be 144");
        require(_tittyId <= _max_supply, "This id is impossible");
        _tokenIds.increment();

        Titty memory _titty = Titty({
            name: _name,
            originalPrice: _price,
            salePrice: _price,
            forSale: true
        });
        
        _tokenIds.increment();
        
        Titties[_tittyId] = _titty;

        _mint(address(this), _tittyId);
        _setTokenURI(_tittyId, _tokenURI);

    }

    /**
     * @dev Mint a wrapped titty
     */
    function mint(address _address, uint256 _price, uint256 _sale, uint _tittyId, string memory _name, string memory _tokenURI)
        public
        whenNotPaused 
        onlyOwner
    {
        require(_tittyId <= _max_supply, "It can only be 144");
        _tokenIds.increment();

        Titty memory _titty = Titty({
            name: _name,
            originalPrice: _price,
            salePrice: _sale,
            forSale: false
        });

        Titties[_tittyId] = _titty;
        
        _mint(_address, _tittyId);
        _setTokenURI(_tittyId, _tokenURI);

    }

    function changeTittyName (string memory _newName, uint256 _tittyId) public {

        require(ownerOf(_tittyId) == msg.sender, "Not the titty owner");
        Titty storage _titty = Titties[_tittyId];
        _titty.name = _newName;

        Titties[_tittyId] = _titty;
        emit ChangedName(msg.sender, _tittyId, _newName);
        
    }

    function alterTittyForSaleStatus (bool _status, uint256 _newPrice, uint256 _tittyId, address sales) public {

        require(ownerOf(_tittyId) == msg.sender, "Not the titty owner");
        Titty storage _titty = Titties[_tittyId];
        _titty.salePrice = _newPrice;
        _titty.forSale = _status;

        Titties[_tittyId] = _titty;
        setApprovalForAll(sales, true);
        
        emit Sellable(msg.sender, _tittyId, _status);

    }

    function transfer(address from, address to, uint256 _tittyId) public {
        
        safeTransferFrom(from, to, _tittyId);
        Titty storage _titty = Titties[_tittyId];
        _titty.forSale = false;

        Titties[_tittyId] = _titty;
        
        emit NotSellable(msg.sender, _tittyId, false);
    }

    function calculateFee (uint256 _price) internal pure returns(uint) {
        return (_price * 10)/100;
    }

    function calculateBoatFee (uint256 _price) internal pure returns(uint) {
        return (_price * 25)/100;
    }

    function getATitty (uint _tittyId) public view
    returns (
        uint256 originalPrice,
        uint256 salePrice,
        bool forSale 
    ){
        Titty memory titty = Titties[_tittyId];
        return (
            titty.originalPrice,
            titty.salePrice,
            titty.forSale
        );
    }

    function updateMetadata (string memory _newUri, uint tokenId) 
        public
        whenNotPaused
        onlyOwner {
        _setTokenURI(tokenId, _newUri);
    }

}

