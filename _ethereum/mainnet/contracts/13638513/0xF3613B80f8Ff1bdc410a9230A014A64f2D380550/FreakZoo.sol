// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./ERC721.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./Ownable.sol";

contract FreakZoo is ERC721, Ownable { 
    
    string internal baseTokenURI = 'https://freakzoo.io/api/asset/';

    uint public price = 0.07 ether;
    uint public totalSupply = 3333;
    
    uint public nonce = 0;

    bool public mintOpen = false;
    bool public presaleOpen = true;
    
    mapping(address => uint[]) private ownership;
    mapping(address => bool) public whitelist;

    IERC20 public bnn;
    uint public bSupply = 333;
    uint public bnnNonce = 0;

    uint public bnnPrice = 6 ether;
    
    event Mint(address owner, uint qty);
    event Withdraw(uint amount);

    string private _phrase;
    
    constructor() ERC721("Freak Zoo", "FKZ") {

    }

    // setters

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function togglePresale() external onlyOwner {
        presaleOpen = !presaleOpen;
    }

    function setPhrase(string calldata phrase) external onlyOwner {
        _phrase = phrase;
    }
    
    function addToPresale(address[] calldata whitelist_) external onlyOwner {
        for(uint i=0; i<whitelist_.length; i++){
            whitelist[whitelist_[i]] = true;
        }
    }
    
    function removeFromPresale(address[] calldata whitelist_) external onlyOwner {
        for(uint i=0; i<whitelist_.length; i++){
            whitelist[whitelist_[i]] = false;
        }
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }
    
    function getTokenIdsByOwner(address _owner) public view returns(uint[] memory) {
        return ownership[_owner];
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    // mint

    function giveaway(address to, uint qty) external onlyOwner {
        _mintTo(to, qty);
    }

    function buyPresale(uint qty) external payable {
        require(presaleOpen, "presale closed");
        require(whitelist[_msgSender()], "not in whitelist");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        _buy(qty);
    }
    
    function buy(uint qty, string calldata phrase) external payable {
        require(mintOpen, "mint closed");
        require(msg.value >= price * qty, "PAYMENT: invalid value");
        require(keccak256(bytes(phrase)) == keccak256(bytes(_phrase)), "mint error");
        _buy(qty);
    }

    function _buy(uint qty) internal {
        require(qty > 0, "TRANSACTION: qty of mints not alowed");
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        for(uint i = 0; i < qty; i++){
            nonce++;
            _safeMint(to, nonce);
        }
    }

    // banana

    function setBnnAddress(address newAddress) public onlyOwner{
        bnn = IERC20(newAddress);
    }

    function setBnnPrice(uint newPrice) external onlyOwner {
        bnnPrice = newPrice;
    }

    function setBSupply(uint newSupply) external onlyOwner {
        bSupply = newSupply;
    }

    function buyUsingBnn(uint qty) external {
        require(mintOpen || presaleOpen, "closed");
        require(bnn.balanceOf(_msgSender()) >= qty * bnnPrice, "insufficient funds");
        require(bnn.allowance(_msgSender(), address(this)) >= qty * bnnPrice, "not allowed");
        require((qty + bnnNonce) <= bSupply, "sold out");
        bnnNonce += qty;
        bnn.transferFrom(_msgSender(), 0x3E4c18eb3a9115510d4Dbf0c9Cce015C6cacEC51, qty * bnnPrice);
        _mintTo(_msgSender(), qty);
    }

    // team
    
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(0xEd8fe1BB60036855895812e627B82161f4C5529e).transfer((balance * 35) / 100);
        payable(0xf99f2DF8fB2b8B873cFbD316296bA82ff55E03db).transfer((balance * 35) / 100);
        payable(0x3E4c18eb3a9115510d4Dbf0c9Cce015C6cacEC51).transfer((balance * 10) / 100);
        payable(0x0e1297F9014D0456492311884A0145FF0568808D).transfer((balance * 10) / 100);
        payable(0xdFeE4a9d467170a99D3dc34DFB6C041c4c803732).transfer(address(this).balance);
    }

    // ownership control
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if(from != address(0)){
            uint[] memory tokens = ownership[from];
            for(uint i=0;i<tokens.length;i++){
                if(tokens[i] == tokenId){
                    ownership[from][i] = 999999999;
                    break;
                }
            }
        }
        if(to != address(0)){
            ownership[to].push(tokenId);
        }
    }
    
}
