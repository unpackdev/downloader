// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

contract Skillett is ERC721Enumerable, Ownable, AccessControl {

    bytes32 public constant WHITE_LIST_ROLE = keccak256("WHITE_LIST_ROLE");
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant TOTAL_NUMBER_OF_SKILLETT = 1000;
    uint256 public constant MAXMINT_PUBLIC = 10;
    uint256 public constant MAXMINT_PRIVATE = 10;
    
    uint256 public presale_left = 501;
    uint256 public airdrop_left = 51;

    string private _baseTokenURI = "https://api.skillettgang.io/token/";

    address private _artistAddress = 0xabe9ACCE140a2D338A5df5F08b6dC87366e34d31;

    mapping(address => bool) private _preSaleWhitelist;

    bool public saleOpen = false;
    bool public presaleOpen = false;

    modifier isSaleOpen() {
        require(saleOpen, "Skillett: public sale not open");
        _;
    }

    modifier isPresaleOpen() {
        require(presaleOpen, "Skillett: presale not open");
        _;
    }

    modifier preSaleAllowedAccount(address account) {
        require(preSaleAllowed(account), "Skillett: account is not allowed for presale");
        _;
    }

    constructor(

    )
        ERC721("Skillett", "SKILLETT")
    {
        _setupRole(WHITE_LIST_ROLE, msg.sender);
    }

    fallback() external payable { }

    receive() external payable { }

    function mintTokens(uint256 num) public payable isSaleOpen(){
        uint256 supply = totalSupply();
        require( num <= MAXMINT_PUBLIC, "Skillett: You can mint a maximum of 10 Skilletts per transaction");
        require( supply + num <= TOTAL_NUMBER_OF_SKILLETT, "Skillett: Exceeds maximum Skilletts supply");
        require( msg.value >= PRICE * num, "Skillett: Ether sent is less than PRICE * num");
        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i);
        }
    }

    function presale_mintTokens(uint256 num) public payable isPresaleOpen() preSaleAllowedAccount(msg.sender){
        uint256 supply = totalSupply();
        require(presale_left > num, "Skillett: Exceeds presale reserved Skilletts supply");
        require(supply + num <= TOTAL_NUMBER_OF_SKILLETT, "Skillett: Exceeds maximum Skilletts supply");
        require(num <= MAXMINT_PRIVATE, "Skillett: You can mint a maximum of 10 Skilletts per transaction");
	    require(msg.value >= PRICE * num, "Skillett: Ether sent is less than PRICE * num");
        _preSaleWhitelist[msg.sender] = false;
        presale_left -= num;
        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function airdrop(address[] calldata _addresses) external onlyRole(WHITE_LIST_ROLE) {
        uint256 supply = totalSupply();
        require(airdrop_left > _addresses.length, "Skillett: Exceeds airdrop reserved Skilletts supply");
        require(supply + _addresses.length <= TOTAL_NUMBER_OF_SKILLETT, "Skillett: Exceeds maximum Skilletts supply");
        airdrop_left -= _addresses.length;
        for(uint256 i; i < _addresses.length; i++){
            _safeMint(_addresses[i], supply + i);
        }
    }

    function withdraw() external onlyRole(WHITE_LIST_ROLE) {
        payable(_artistAddress).transfer(address(this).balance * 3 / 5);
        payable(msg.sender).transfer(address(this).balance);
    }

    function tooglePublicSaleState() public onlyRole(WHITE_LIST_ROLE) {
        saleOpen = !saleOpen;
    }

    function tooglePreSaleState() public onlyRole(WHITE_LIST_ROLE) {
        presaleOpen = !presaleOpen;
    }

    function setPreSaleRoleBatch(address[] calldata _addresses) external onlyRole(WHITE_LIST_ROLE) {
        for(uint256 i; i < _addresses.length; i++){
            _preSaleWhitelist[_addresses[i]] = true;
        }
    }

    function setBaseURI(string memory baseURI) public onlyRole(WHITE_LIST_ROLE) {
        _baseTokenURI = baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function preSaleAllowed(address account) public view  returns (bool) {
        return _preSaleWhitelist[account];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}