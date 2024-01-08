// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract OnTheRoad is ERC721, Ownable {

    uint public price = 0.06 ether;
    uint public totalSupply = 10000;
    uint public mintSupply = 9000;
    uint public claimSupply = 1000;
    uint public nonce = 0;
    uint public maxTx = 10;
    
    bool public saleActive = false;
    bool public claimActive = false;

    string internal baseTokenURI;
    
    mapping(address => uint) public holders;
    
    event Mint(address owner, uint qty);
    event Withdraw(uint amount);
    
    struct Holders {
        address wallet;
        uint qty;
    }
    
    modifier onlyHolders() {
        require(holders[_msgSender()] > 0, "Only NotARug Owners");
        _;
    }
    
    constructor() ERC721("OnTheRoad", "OTR") {}
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }

    function setMintSupply(uint newSupply) external onlyOwner {
        mintSupply = newSupply;
    }

    function setClaimSupply(uint newSupply) external onlyOwner {
        claimSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setClaimActive(bool val) public onlyOwner {
        claimActive = val;
    }
    
    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function getAssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < nonce; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    
    function mint(uint qty) external payable {
        require(saleActive, 'Sale is not active');
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        require(mintSupply >= qty, "Sold out");
        mintSupply -= qty;
        _create(_msgSender(), qty);
        emit Mint(_msgSender(), qty);
    }
    
    function addHolders(address[] calldata holders_, uint[] calldata qty) external onlyOwner {
        for(uint i=0; i< holders_.length; i++){
            holders[holders_[i]] = qty[i];
        }
    }
    
    function claim() external onlyHolders {
        require(claimActive, 'Claim is not active');
        uint qty = holders[_msgSender()];
        require(claimSupply > qty, "Claim over");
        require(nonce + qty <= totalSupply, "sold out");
        holders[_msgSender()] = 0;
        claimSupply -= qty;
        _create(_msgSender(), qty);
    }
    
    function giveaway(address to, uint qty, bool fromHolders) external onlyOwner {
        require(nonce + qty <= totalSupply, "sold out");
        if(fromHolders){
             require(claimSupply >= qty, "claim over");
             claimSupply -= qty;
        }
        _create(to,qty);
        
    }
    
    function _create(address to, uint qty) internal {
        for(uint i = 0; i < qty; i++){
            nonce++;
            _safeMint(to, nonce);
        }
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}