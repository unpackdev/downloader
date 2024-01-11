//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./CountersUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./Initializable.sol";

contract Names is Initializable, OwnableUpgradeable, PausableUpgradeable, ERC721EnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter; 

    CountersUpgradeable.Counter private _numberMinted;

    uint public maxSupply;
    uint256 public price;
    string private _baseTokenURI;
    bool private _isPresaleActive;

    mapping(uint => bool) public minted_ids;
    mapping(uint => bool) public reserved_ids;
    mapping(uint => address) public reserved_by_addresses;
    mapping(address => bool) public is_on_presale_list;

    modifier check(uint _id){
        require(            
            _numberMinted.current() < maxSupply, "Not enough NFTs!"
        );
        require(
            _id <= maxSupply, "Invalid ID - must be less than max supply"
        );
        require(
            _id > 0, "Invalid ID - must be greater than 0"
        );
        require(
            !minted_ids[_id], "This NFT has already been minted"
        );
        _;
    }

    function initialize(string memory _baseUri, uint256 _price, uint _maxSupply, string memory _name, string memory _symbol ) public initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        _baseTokenURI = _baseUri;
        price = _price;
        maxSupply = _maxSupply;
        _isPresaleActive = true;
    }

    // override _baseURI
    function _baseURI() internal 
                        view 
                        virtual 
                        override 
                        returns (string memory) {
        return _baseTokenURI;
    }

    function _ownerReserveSingleNFT(uint _id) check(_id) private {
        reserved_ids[_id] = true;
    }

    function reserveNFTs(uint[] memory _ids) public onlyOwner {
        for (uint j = 0; j < _ids.length; j++) {
            _ownerReserveSingleNFT(_ids[j]);
        }
    }

    function reserveSingleNFT(address recipient, uint _id) check(_id) public onlyOwner {
        reserved_by_addresses[_id] = recipient;
    }

    function mintSingleNFT(uint _id) check(_id) whenNotPaused public payable {
        if (reserved_by_addresses[_id] == msg.sender ) {
            _mintSingleNFT(_id);
        } else {
            if( _isPresaleActive ){
              require(is_on_presale_list[msg.sender], "Only for presale-approved addresses");
            }
            require(
                !reserved_ids[_id], "This NFT is reserved"
            );
            require(
                reserved_by_addresses[_id] == address(0), "This NFT is reserved"
            );
            require(
                msg.value >= price,
                "Not enough ether to purchase NFTs."
            );
            
            _mintSingleNFT(_id);
        }
    }

    function ownerMintNFT(uint _id) check(_id) public onlyOwner {
         _mintSingleNFT(_id);
    }

    function _mintSingleNFT(uint _id) private {
        _safeMint(msg.sender, _id);
        _numberMinted.increment();
        minted_ids[_id] = true;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function stopPresale() public onlyOwner {
        _isPresaleActive = false;
    }

    function startPresale() public onlyOwner {
        _isPresaleActive = true;
    }

    function approveAddress(address recipient) public onlyOwner {
        is_on_presale_list[recipient] = true;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setBaseURI(string calldata _newBaseTokenURI) external onlyOwner {
        _baseTokenURI = _newBaseTokenURI;
    }
}
