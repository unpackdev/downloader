pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CryptoFluffs is ERC721, Ownable {
    
    using Strings for uint256;
    using Counters for Counters.Counter;

    string public _baseTokenURI;
    uint256 public _presalePrice = 0.02 ether;
    uint256 public _price = 0.03 ether;
    uint256 public _maxSupply = 1000;
    uint256 public _maxPresaleSupply = 500;
    uint256 public _series = 1;
    bool public _preSaleIsActive = false;
    bool public _saleIsActive = false;

    Counters.Counter private _tokenSupply;

    address a1 = 0xb63ca07E361587172623dC43AbC8208815C24cb2;
    address a2 = 0x5CaE7b682101Ad2697bA6fa7a1Dc0fae6aED43AF;

    constructor(string memory baseURI) ERC721("CryptoFluffs", "FLUFFS") {
        setBaseURI(baseURI);

        for (uint256 i = 0; i < 50; i++) {

            if (i < 25) {
                 _tokenSupply.increment();
                _safeMint(a1, i);
            }
            else if (i < 50) {
                 _tokenSupply.increment();
                _safeMint(a2, i);
            }
        }        
        
    }

    function preSaleMint(uint256 mintCount) public payable {
        uint256 supply = _tokenSupply.current();

        require(_preSaleIsActive,                           "presale_not_active");
        require(balanceOf(msg.sender) + mintCount <= 5,     "presale_wallet_limit_met");
        require(supply + mintCount <= _maxPresaleSupply,    "presale_supply_exceeded");
        require(msg.value >= _presalePrice * mintCount,     "insufficient_payment_value");

        for (uint256 i = 0; i < mintCount; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        } 

    }

    function mint(uint256 mintCount) public payable {
        uint256 supply = _tokenSupply.current();

        require(_saleIsActive,                              "sale_not_active");
        require(mintCount < 20,                             "max_mint_count_exceeded");
        require(supply + mintCount < _maxSupply,            "max_supply_exceeded");
        require(msg.value >= _price * mintCount,            "insufficient_payment_value");

        for (uint256 i = 0; i < mintCount; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        }

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function preSaleStart() public onlyOwner {
        _preSaleIsActive = true;
    }

    function preSaleStop() public onlyOwner {
        _preSaleIsActive = false;
    }

    function saleStart() public onlyOwner {
        _saleIsActive = true;
    }

    function saleStop() public onlyOwner {
        _saleIsActive = false;
    }

    function setSeries(uint256 series) external onlyOwner {
        _series = series;
    }

    function tokensMinted() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function newSeries(
        uint256 series,
        uint256 price,
        uint256 maxSupply
    ) external onlyOwner {
            _series = series;
            _price = price;
            _maxSupply = maxSupply;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 2;
        require(payable(a1).send(_each));
        require(payable(a2).send(_each));
    }
}