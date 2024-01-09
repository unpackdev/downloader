/**  
 SPDX-License-Identifier: GPL-3.0
  __        __          __  __
 |__)  /\  |  \ |__/ | |  \  /
 |__) /~~\ |__/ |  \ | |__/ /_

 Written by: afellanamedrob & thezman | Sage Labs
*/
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";
import "./PaymentSplitter.sol";
import "./EIP712Whitelisting.sol";
import "./ERC721A.sol";

contract BadKidz is ERC721A, ReentrancyGuard, Ownable, EIP712Whitelisting {
    using Counters for Counters.Counter;

    /** MINTING **/
    uint256 public price = 0.1 ether;
    uint256 public whitelistPrice = 0.08 ether;
    uint256 public maxSupply = 8999;
    uint256 public maxReserveSupply = 250;
    uint256 public maxMintCountPerTxn = 10;
    uint256 public maxWhitelistSupply = 2500;
    string private customBaseURI;
    bool public saleIsActive = false;
    bool public whitelistSaleIsActive = false;
    Counters.Counter private supplyCounter;
    Counters.Counter private reserveSupplyCounter;
    Counters.Counter private whitelistMintCounter;
    PaymentSplitter private splitter;

    constructor(
        string memory _customBaseURI,
        address[] memory _payees,
        uint256[] memory _shares
    )
        ERC721A("BadKidz", "BadKidz")
        EIP712Whitelisting()
    {
        customBaseURI = _customBaseURI;
        splitter = new PaymentSplitter(_payees, _shares);
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /** COUNTERS */
    function totalTokenSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    function totalReserveSupply() public view returns (uint256) {
        return reserveSupplyCounter.current();
    }

    function totalWhitelistMints() public view returns (uint256) {
        return whitelistMintCounter.current();
    }

    /** MINTING **/
    function mint(uint256 _count) public payable nonReentrant callerIsUser {
        require(_count  > 0, "Cannot mint 0 tokens");
        require(saleIsActive, "Sale not active");
        require( totalTokenSupply() + _count - 1 < maxSupply - maxReserveSupply, "Exceeds max supply");
        require(_count - 1 < maxMintCountPerTxn, "Trying to mint too many");
        require(msg.value >= price * _count, "Insufficient payment");

        for (uint256 i = 0; i < _count; i++) {
            supplyCounter.increment();
        }

        _safeMint(msg.sender, _count);
        payable(splitter).transfer(msg.value);
    }

    function mintReserve(uint256 _count) external onlyOwner {
        require(_count  > 0, "Cannot mint 0 tokens");
        require( totalReserveSupply() + _count - 1 < maxReserveSupply, "Exceeds max supply");

        for (uint256 i = 0; i < _count; i++) {
            reserveSupplyCounter.increment();
        }

        _safeMint(msg.sender, _count);

    }

    function mintReserveToAddress(uint256 _count, address _account) external onlyOwner {
        require(_count  > 0, "Cannot mint 0 tokens");
        require( totalReserveSupply() + _count - 1 < maxReserveSupply, "Exceeds max supply");

        for (uint256 i = 0; i < _count; i++) {
            reserveSupplyCounter.increment();
        }

        _safeMint(_account, _count);
    }

    function mintWhitelist(uint256 _count, bytes calldata signature) public payable
        requiresWhitelist(signature)
        nonReentrant
        callerIsUser
    {
        require(_count  > 0, "Cannot mint 0 tokens");
        require(whitelistSaleIsActive, "Sale not active");
        require( totalWhitelistMints() + _count - 1 < maxWhitelistSupply, "Exceeds whitelist supply");
        require( totalTokenSupply() < maxSupply - maxReserveSupply + _count - 1, "Exceeds max supply");
        require(_count - 1 < maxMintCountPerTxn, "Trying to mint too many");
        require(msg.value >= whitelistPrice * _count, "Insufficient payment");

        for (uint256 i = 0; i < _count; i++) {
            supplyCounter.increment();
            whitelistMintCounter.increment();
        }
        _safeMint(_msgSender(), _count);

        payable(splitter).transfer(msg.value);
    }

    /** WHITELIST **/
    function checkWhitelist(bytes calldata signature)
        public
        view
        requiresWhitelist(signature)
        returns (bool)
    {
        return true;
    }

    /** ADMIN FUNCTIONS **/
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistSaleState() external onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxWhitelistSupply(uint256 _maxSupply) external onlyOwner {
        maxWhitelistSupply = _maxSupply;
    }

    function setReserveSupply(uint256 _newReserve) external onlyOwner {
        maxReserveSupply = _newReserve;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        customBaseURI = _newBaseURI;
    }

    function setMaxSupply(uint256 _newSize) external onlyOwner {
        maxSupply = _newSize;
    }

    /** RELEASE PAYOUT **/
    function release(address payable _account) public virtual {
        if(msg.sender == 0x215De00630F5E89C3A219D2771e55dc49F28489f || msg.sender == 0xAD8849181DcF9997F3551216459aeF8a3f4eD4d6){
            splitter.release(_account);
        } else{
            revert("Only owner and Sage Labs can release payment");
        }
    }
}
