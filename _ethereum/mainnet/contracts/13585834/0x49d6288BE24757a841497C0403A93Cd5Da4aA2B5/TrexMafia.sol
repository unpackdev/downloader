// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract TrexMafia is ERC721, Ownable {  
    using Address for address;
    
    bool public saleActive = false;
    bool public vipSaleActive = false;
    bool public freeMintActive = false;

    uint256 public MAX_SUPPLY = 7777;
    uint256 public price = 0.033 ether;

    uint public supply = 0;
    uint public maxPerTx = 0;

    string public baseTokenURI;

    mapping (address => uint256) public vipSaleReserved;
    mapping (address => uint256) public claimReserved;

    constructor() ERC721("T-Rex Mafia", "TREX") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokensOfOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < supply; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function mintVipSale(uint256 _amount) public payable {
        uint256 reserved = vipSaleReserved[msg.sender];
        require( vipSaleActive,               "Vip Sale isn't active" );
        require( reserved > 0,                "No tokens reserved for your address" );
        require( _amount <= reserved,         "Can't mint more than reserved" );
        require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
        require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
        vipSaleReserved[msg.sender] = reserved - _amount;
        for(uint256 i; i < _amount; i++){
            supply++;
            _safeMint( msg.sender, supply);
        }
    }

    function mintToken(uint256 _amount) public payable {
        require( saleActive,                     "Sale isn't active" );
        require( _amount > 0 && _amount < maxPerTx,    "Can only mint between 1 and 10 tokens at once" );
        require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
        require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
        for(uint256 i; i < _amount; i++){
            supply++;
            _safeMint( msg.sender, supply);
        }
    }

    function claimToken() external {
        uint256 reserved = claimReserved[msg.sender];
        require( freeMintActive,              "Claim isn't active" );
        require( reserved > 0,                "No tokens reserved for your address" );
        require( supply + reserved <= MAX_SUPPLY, "Can't mint more than max supply" );
        vipSaleReserved[msg.sender] = 0;
        for(uint256 i; i < reserved; i++){
            supply++;
            _safeMint( msg.sender, supply);
        }
    }
    
    function editVipSaleReserved(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            vipSaleReserved[_a[i]] = _amount[i];
        }
    }

    function editClaimReserved(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            claimReserved[_a[i]] = _amount[i];
        }
    }

    function setVipSaleActive(bool val) public onlyOwner {
        vipSaleActive = val;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setFreeMintActive(bool val) public onlyOwner {
        freeMintActive = val;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}