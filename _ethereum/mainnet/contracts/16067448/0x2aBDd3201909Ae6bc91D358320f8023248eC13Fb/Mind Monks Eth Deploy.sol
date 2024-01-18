// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;   

// ███    ███ ██ ███    ██ ██████      ███    ███  ██████  ███    ██ ██   ██ ███████ 
// ████  ████ ██ ████   ██ ██   ██     ████  ████ ██    ██ ████   ██ ██  ██  ██      
// ██ ████ ██ ██ ██ ██  ██ ██   ██     ██ ████ ██ ██    ██ ██ ██  ██ █████   ███████ 
// ██  ██  ██ ██ ██  ██ ██ ██   ██     ██  ██  ██ ██    ██ ██  ██ ██ ██  ██       ██ 
// ██      ██ ██ ██   ████ ██████      ██      ██  ██████  ██   ████ ██   ██ ███████ 
//                                                                                   
//                                                                                   
//  ██████  ███████ ███    ██ ███████ ███████ ██ ███████                             
// ██       ██      ████   ██ ██      ██      ██ ██                                  
// ██   ███ █████   ██ ██  ██ █████   ███████ ██ ███████                             
// ██    ██ ██      ██  ██ ██ ██           ██ ██      ██                             
//  ██████  ███████ ██   ████ ███████ ███████ ██ ███████                             
                                                                                                                                                                   
import "./ERC721A.sol";
import "./Ownable.sol";
import "./OperatorFilterer.sol";

contract MindMonks is ERC721A, Ownable, OperatorFilterer {

    uint256 public monkPrice = 5 ether; // 5 eth - adjustable
    uint256 public constant maxMonkMint = 8;
    uint256 public maxMonks = 888; 
    uint256 public foundersReserve = 50; // Reserve up to 50 Monks for founders, marketing etc. - adjustable

     // Allowlist
    mapping(address => uint256) private availableMonksToMint;
    
    // Discounts
    mapping(address => uint256) public addressToDiscountMap;

    // Withdraw addresses
    address t1 = 0xa7cdef1e63f92544C9a5C45796F45d11003A64BB; // Wallet 1
    address t2 = 0xEa2173747157570f37D472FdBDEa93301F09dcA5; // Wallet 2

    bool public saleIsActive = false;
    bool public publicSaleIsActive = false;

    string private _baseTokenURI;

    constructor() ERC721A("Mind Monks Genesis", "Monks") OperatorFilterer(address(0), false) { }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPublicSaleState() public onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }
    
    function withdraw() public onlyOwner {
        uint256 _total = address(this).balance;
        require(payable(t1).send(((_total)/100)*50));
        require(payable(t2).send(((_total)/100)*50));
    }

    function updateWithdrawAddresses (address _t1, address _t2) public onlyOwner {
        t1 = _t1;
        t2 = _t2;
    }
    
    function reserveMonks(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount <= foundersReserve, "Not Possible");
        require(totalSupply() + _reserveAmount <= maxMonks, "Max Supply would be exceeded");
        foundersReserve -= _reserveAmount;
        _safeMint(_to, _reserveAmount);
    }

    function updateFoundersReserve(uint256 newReserve) public onlyOwner {
        foundersReserve = newReserve;
    }

    function setTheMonkPrice(uint256 newPrice) public onlyOwner {
        monkPrice = newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Utility

    function remainingMonks(address _address) external view returns (uint256) {
    return availableMonksToMint[_address];
    }

    function showDiscount() public view returns (uint256) {
        return addressToDiscountMap[msg.sender];
    }   

    // Allowlist and Discount Update - Insert discount amount, i.e. 30% discount = 30

    function updateAllowlist(address[] memory _addresses, uint256 _newAmount, uint256 _discount) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            availableMonksToMint[_addresses[i]] = _newAmount;
            addressToDiscountMap[_addresses[i]] = _discount;
        }
    }

    // Minting 

    function allowlistMint(uint256 monksToMint) public payable {
        require(saleIsActive, "Allowlist Sale is not active");
        require(monksToMint <= maxMonkMint, "Max Monks per mint exceeded");
        require(monksToMint <= availableMonksToMint[msg.sender], "You are not eligible to mint / have already max minted");
        require(totalSupply() + monksToMint <= maxMonks, "Max Supply would be exceeded");
        require((msg.value >= monkPrice * monksToMint * (100 - addressToDiscountMap[msg.sender]) / 100), "Ether value sent is incorrect");
                availableMonksToMint[msg.sender] -= monksToMint;
                _safeMint(msg.sender, monksToMint);
    }  

    function publicMint(uint256 monksToMint) public payable {
        require(publicSaleIsActive, "Public Sale is not active");
        require(monksToMint <= maxMonkMint, "Max Monks per mint exceeded");
        require(totalSupply() + monksToMint <= maxMonks, "Max Supply would be exceeded");
        require(msg.value >= monkPrice * monksToMint, "Ether value sent is incorrect");
                _safeMint(msg.sender, monksToMint);
    }  

    // OpenSea Royalty Register

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}