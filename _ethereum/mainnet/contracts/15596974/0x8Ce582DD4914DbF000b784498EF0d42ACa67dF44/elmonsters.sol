// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";


contract ElMonster is  ERC721A,  Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public constant Max_Supply = 3333;
    uint256 public price = 0.0099 ether;
    uint256 public pstep = 0.005 ether;
    string contractmeta = "ipfs://QmWc64tszJwTbLPEGJJHgadoh7o1H5RnYRjWa9swietueV";

    string private _baseTokenURI = "ipfs://QmZJP7MdiBiw24jXvaqAn53fyNWKsxq3zMC6CWP38KDdA2/";

    bool public isActive = true;


    constructor ()  ERC721A("EL Monsters Tale", "EMT")    {}

    event Minted(
        address minter,
        uint256 quantity
    );
    
    function contractURI() public view returns (string memory) {
        return contractmeta;
    }

    function setContractMeta(string memory _md) public onlyOwner {
        contractmeta = _md;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        _baseTokenURI = _URI;
    }
     
    function setPriceStep(uint256 _price, uint256 _pstep) external onlyOwner {
        price = _price;
        pstep = _pstep;
    }

    function setActive(bool _state) external onlyOwner {
        isActive = _state;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require( _exists(_tokenId),"no token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : "";
    }

    function findprice (uint256 _quantity) public view  returns (uint256 value) {
         if (_quantity == 1 ) {
            value = price;
        } else {
            value = price + ((_quantity -1) * pstep);}

        return value;
    }

    function mint(uint256 _quantity) external payable nonReentrant {
        require(isActive, "Not active");
        require(_quantity > 0, "No 0 mint"); 
        require(_quantity < 11, "10 max mint");
        require((totalSupply() + _quantity) <= Max_Supply, "Max supply");
        if (_quantity == 1) {
            require(msg.value >= price , "Check Eth"); 
        } else {
            require(msg.value >= price + ((_quantity -1) * pstep) , "Check Eth");}

        _safeMint(msg.sender, _quantity);

        emit Minted (
            msg.sender,
            _quantity
        );
    }

    function mint2(uint256 _quantity) external payable nonReentrant {
        require(isActive, "Not active");
        require(_quantity > 0, "No 0 mint");
        require(_quantity < 11, "10 max mint");
        require((totalSupply() + _quantity) <= Max_Supply, "Max supply");
        if (_quantity == 1) {
            require(msg.value >= price , "Check Eth"); 
        } else {
            require(msg.value >= price + ((_quantity -1) * pstep) , "Check Eth");}

        _safeMint(msg.sender, _quantity +1);

        emit Minted (
            msg.sender,
            _quantity + 1
        );
    }


    function adminMint(address _recp, uint256 _quantity) external nonReentrant onlyOwner{
         require((totalSupply() + _quantity) <= Max_Supply, "Max supply");
        _safeMint(_recp, _quantity);
            emit Minted (
                _recp,
                _quantity
        );
    }

    function withdraw(address _address, uint256 amount) public onlyOwner nonReentrant {
        (bool os, ) = payable(_address).call{value: amount}("");
        require(os);
    }
}