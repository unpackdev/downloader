// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC165.sol";

interface IERC2981RoyaltiesInterface {
    
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

abstract contract ERC2981BaseContract is ERC165, IERC2981RoyaltiesInterface {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981RoyaltiesInterface).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

contract MorphicBeast is ERC1155, Ownable, Pausable, ERC2981BaseContract {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string public name;
    string public symbol;
    string public baseUri;

    uint256 public MAX_ELEMENTS = 8888;
    uint256 public MAX_GENESIS_ELEMENTS = 888; 
    uint256 public MAX_PRESALE_ELEMENTS = 888;
    uint256 public constant PRICE = 8 * 10**16; // 0.08 ETH
    uint256 public MAX_BY_MINT = 2;
    uint256 public MAX_PER_ADDRESS = 2;    
    bool public IS_GENESIS_SALE = true;
    bool public IS_PRESALE = true;
    address public adminAddress = 0x72dF887f6c2F3a1448405E8B84f3423c584C6A6e;
    address public teamAddress = 0x42F82209Cb32bE802cA4C2821f1345ECbC038F17;
    address public companyAddress = 0xE9454428D1a66cA2874309221951Cb29E6dCABE1;
    RoyaltyInfo private _royalties;
    mapping(address => bool) public whitelisted;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    ) ERC1155(_baseUri) {
        name = _name;
        symbol = _symbol;
        baseUri = _baseUri;

        _setRoyalties(0x27556CaD4cf4D2bA8ec2E0AF0CaD6D4E155c89a2, 300);

        pause(true);
    }    

    function contractURI() public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmSCipq9P2fpKEMvUQRjcDuePHELDFBpw8xXCQ7TwN75XE";
    }  

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function mint(uint256 amount) public payable saleIsOpen {
        uint256 _tokenId = _totalSupply();

        if(IS_GENESIS_SALE == true){
            require(_tokenId + amount <= MAX_GENESIS_ELEMENTS, "Mint: over Max Genesis limit");
        }else{
            require(_tokenId + amount <= MAX_ELEMENTS, "Mint: over Max limit");
        }
        
        require(amount <= MAX_BY_MINT, "Exceeds number");
        require(_amountof(msg.sender, _tokenId) + amount <= MAX_PER_ADDRESS, "Exceeds balance");
        require(msg.value >= price(amount), "Value below price");

        if(IS_PRESALE == true){
            require(whitelisted[msg.sender] == true, "Not presale member");
            require(_tokenId + amount <= MAX_PRESALE_ELEMENTS, "Mint: over Max Presale limit");
        }

        for (uint256 i = 0; i < amount; i++) {
            _mintAnElement();
        }
    }

    // mint one Token to sender
    function _mintAnElement() private {
        _tokenIdTracker.increment();
        uint256 _tokenId = _totalSupply();
        _mint(msg.sender, _tokenId, 1, "");
    }

    // get token amount per walletAddress
    function _amountof(address _owner, uint256 _mintSupply) internal view returns (uint256) {  
        uint256 total_amount = 0;
        for (uint256 i = 1; i <= _mintSupply; i++) {
            uint256 eachtokenBalance = balanceOf(_owner, i);
            if (eachtokenBalance > 0) {                
                total_amount += 1;
            }
        }
        return total_amount;
    }

    function teamPresale(address _to) public saleIsOpen {
        require(msg.sender == adminAddress, "Not Admin");
        _tokenIdTracker.increment();
        uint256 _tokenId = _totalSupply();
        _mint(_to, _tokenId, 1, "");
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    // check if it is paused
    function isPaused() public view returns (bool) {
        return paused();
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json")
            );
    }

    // set the state of market
    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    // the total price of token amounts which the sender will mint
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    // withdraw all coins
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "There is no balance to withdraw");
        uint256 percent = balance / 100;
        // 25% team wallet,
        _widthdraw(teamAddress, percent * 25);
        // 75% company wallet,
        _widthdraw(companyAddress, percent * 75);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }    

    // set Name
    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    // set Symbol
    function setSymbol(string memory _symbol) public onlyOwner {
        symbol = _symbol;
    }

    // set BaseURL
    function setBaseURL(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    // set MAX_ELEMENTS
    function setMaxElements(uint256 _count) public onlyOwner {
        MAX_ELEMENTS = _count;
    }

    // set MAX_GENESIS_ELEMENTS
    function setMaxGenesisElements(uint256 _count) public onlyOwner {
        MAX_GENESIS_ELEMENTS = _count;
    }

    // set MAX_PRESALE_ELEMENTS
    function setMaxPresaleElements(uint256 _count) public onlyOwner {
        MAX_PRESALE_ELEMENTS = _count;
    }

    // set MAX_BY_MINT
    function setMAXBYMINT(uint256 _count) public onlyOwner {
        MAX_BY_MINT = _count;
    }

    // set MAX_PER_ADDRESS
    function setMAXPERADDRESS(uint256 _count) public onlyOwner {
        MAX_PER_ADDRESS = _count;
    }

    // set IS_PRESALE
    function setIsPresale(bool val) public onlyOwner {
        IS_PRESALE = val;
    }

    // set IS_GENESIS_SALE
    function setIsGenesisSale(bool val) public onlyOwner {
        IS_GENESIS_SALE = val;
    }

    // set Admin Wallet
    function setAdminWallet(address _new_admin) public onlyOwner {
        adminAddress = _new_admin;
    }

    // set Team Wallet
    function setTeamWallet(address _new_team) public onlyOwner {
        teamAddress = _new_team;
    }

    // set Company Wallet
    function setCompanyWallet(address _new_company) public onlyOwner {
        companyAddress = _new_company;
    }

    // add user's address to whitelist
    function addWhitelistUser(address[] memory _user) public onlyOwner {
        for(uint256 idx = 0; idx < _user.length; idx++) {
            require(whitelisted[_user[idx]] == false, "already set");
            whitelisted[_user[idx]] = true;
        }
    }

    // remove user's address to whitelist
    function removeWhitelistUser(address[] memory _user) public onlyOwner {
        for(uint256 idx = 0; idx < _user.length; idx++) {
            require(whitelisted[_user[idx]] == true, "not exist");
            whitelisted[_user[idx]] = false;
        }
    }

    // Value is in basis points so 10000 = 100% , 100 = 1% etc
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981BaseContract) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}