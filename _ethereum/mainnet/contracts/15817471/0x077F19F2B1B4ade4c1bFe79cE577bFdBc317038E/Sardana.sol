// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

// ░██████╗░█████╗░██████╗░██████╗░░█████╗░███╗░░██╗░█████╗░
// ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗████╗░██║██╔══██╗
// ╚█████╗░███████║██████╔╝██║░░██║███████║██╔██╗██║███████║
// ░╚═══██╗██╔══██║██╔══██╗██║░░██║██╔══██║██║╚████║██╔══██║
// ██████╔╝██║░░██║██║░░██║██████╔╝██║░░██║██║░╚███║██║░░██║
// ╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝
// Powered by: https://nalikes.com

contract Sardana is ERC1155Supply, Ownable, ReentrancyGuard {

    string public uriPrefix = "";

    uint256 public constant First = 1;
    uint256 public constant Second = 2;
    uint256 public constant Third = 3;

    uint256 public constant First_Claimed = 4;
    uint256 public constant Second_Claimed = 5;
    uint256 public constant Third_Claimed = 6;

    uint[] public maxSupply = [200, 10, 50];
    uint[] public currentSupply = [0, 0, 0];
    uint[] public price = [0.20 ether, 0.70 ether, 0.33 ether];
    uint[] public priceToken = [270 ether, 950 ether, 450 ether];

    uint256 public maxMintAmountPerTx = 5;

    bool public paused = false;
    bool public claimEnabled = true;

    IERC20 public tokenAddress;

    constructor(address _tokenAddress) ERC1155("") {

        tokenAddress = IERC20(_tokenAddress);
    }

    // MODIFIERS

    modifier notPaused() {
        require(!paused, "The contract is paused!");
        _;
    }

    modifier canClaim() {
        require(claimEnabled, "Claim is paused!");
        _;
    }

    modifier mintCompliance(uint256 _mintAmount, uint256 _tier) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(currentSupply[_tier - 1] + _mintAmount <= maxSupply[_tier - 1], "Max supply exceeded!");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount, uint256 _tier) {
        uint256 _mintPrice = getPrice(_tier);
        require(msg.value >= _mintPrice * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier claimCompliance(uint256 _claimAmount, uint256 _tier) {
        require(_tier > 0 && _tier <= 3, "Non-claimable token ID.");
        require(balanceOf(msg.sender, _tier) > 0, "No tokens to claim.");
        require(_claimAmount > 0 && _claimAmount <= balanceOf(msg.sender, _tier), "Incorrect amount of tokens to claim.");
        _;
    }

    // MINT Functions

    function mintAdmin(address to, uint256 amount, uint256 tier) public onlyOwner 
        mintCompliance(amount, tier) {

            currentSupply[tier - 1] += amount;
            _mint(to, tier, amount, "");
    }

    function mintClaimedAdmin(address to, uint256 amount, uint256 tier) public onlyOwner 
        mintCompliance(amount, tier) {

            currentSupply[tier - 1] += amount;
            _mint(to, tier + 3, amount, "");
    }

    function mint(address to, uint256 amount, uint256 tier) public payable notPaused 
        mintCompliance(amount, tier) 
        mintPriceCompliance(amount, tier) {

            currentSupply[tier - 1] += amount;
            _mint(to, tier, amount, "");
    }

    function mintwToken(uint256 amount, uint256 tier) public nonReentrant notPaused 
        mintCompliance(amount, tier) {

            uint256 _mintPrice = getPriceToken(tier);

            bool success = tokenAddress.transferFrom(msg.sender, address(this), _mintPrice * amount);
            require(success, "Token transfer unsuccessful.");

            currentSupply[tier - 1] += amount;
            _mint(msg.sender, tier, amount, "");
    }

    // CLAIM Functions

    function claimToken(uint256 amount, uint256 tier) public nonReentrant notPaused canClaim 
        claimCompliance(amount, tier) {
        
            _burn(msg.sender, tier, amount);
            _mint(msg.sender, tier + 3, amount, "");
    }

    // VIEW Functions

    function getPrice(uint256 _tier) public view returns(uint256) {
        return price[_tier - 1];
    }

    function getPriceToken(uint256 _tier) public view returns(uint256) {
        return priceToken[_tier - 1];
    }
    
    function uri(uint256 _tokenid) override public view returns (string memory) {
        return string(
            abi.encodePacked(uriPrefix, Strings.toString(_tokenid), ".json")
        );
    }

    function contractTokenBalance() public view returns (uint256) {
        return tokenAddress.balanceOf(address(this));
    }

    // CRUD Functions

    function setMaxMintAmountPerTx(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmount;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setClaimEnabled(bool _state) public onlyOwner {
        claimEnabled = _state;
    }

    function setToken(address _tokenAddress) public onlyOwner {
        require(tokenAddress.balanceOf(address(this)) == 0, "Contract already holds other token. Withdraw first.");
        tokenAddress = IERC20(_tokenAddress);
    }

    function setMaxSupply(uint[] calldata _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrice(uint[] calldata _price) public onlyOwner {
        price = _price;
    }

    function setPriceToken(uint[] calldata _priceToken) public onlyOwner {
        priceToken = _priceToken;
    }

    // WITHDRAW

    function withdraw() public onlyOwner nonReentrant {
        
        uint256 balance = address(this).balance;

        bool success;
        (success, ) = payable(0x8aBe083B315484a0C75D9011E465e2fCaFd77066).call{value: ((balance * 100) / 100)}("");
        require(success, "Transaction Unsuccessful");
    }

    function withdrawToken() public nonReentrant {

        uint256 tokenBalance = tokenAddress.balanceOf(address(this));
        tokenAddress.transfer(0x8aBe083B315484a0C75D9011E465e2fCaFd77066, (tokenBalance * 100) / 100);
    }
}