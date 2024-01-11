// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract OwnableDelegateProxy { }
contract ProxyRegistry { mapping(address => OwnableDelegateProxy) public proxies; }

contract LemonParty is ERC721A, Ownable, ReentrancyGuard {
    bool publicMintState;
    string public baseURI;
    uint256 public mintPrice;
    uint256 public MAX_SUPPLY;
    uint256 public maxMintPerTx;
    address private proxyRegistryAddress;

    constructor() ERC721A("LemonParty", "LEMON") {
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
        mintPrice = 0.03 ether;
        MAX_SUPPLY = 10000;
        maxMintPerTx = 5;
    }

    /**
     * @dev Sets Base URI
     */
    function _setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    /**
     * @dev Sets Proxy Registry Address
     */
    function _setProxyAddress(address _addr) public onlyOwner {
        proxyRegistryAddress = _addr;
    }

    /**
     * @dev Returns the baseURI value
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Mint a Reserved amount
     */
    function mintReserved(uint256 _amount) public nonReentrant onlyOwner {
        require(tx.origin == msg.sender, "Bad.");
        require(tx.origin == owner(), "Not the owner of the contract.");
        uint256 _totalSupply = totalSupply();
        require((_totalSupply + _amount) <= MAX_SUPPLY, "Amount to mint would exceed Max Supply.");
        require(_amount > 0, "Amount must be greater than zero.");

        _safeMint(msg.sender, _amount);
    }

    /**
     * @dev Public Mint Function
     */
    function publicMint(uint256 _amount) public payable nonReentrant {
        require(tx.origin == msg.sender, "Bad.");
        require(publicMintState == true, "Public mint is disabled.");
        require(_amount > 0, "Must mint at least one NFT.");
        require(_amount <= maxMintPerTx, "Maximum 5 NFT's per transaction.");
        require(msg.value >= (mintPrice * _amount), "Not enough ether sent to mint.");
        uint256 _totalSupply = totalSupply();
        require((_totalSupply + _amount) <= MAX_SUPPLY, "Amount to mint would exceed Max Supply.");

        _safeMint(msg.sender, _amount);

        // Send any ether that exceeds the total cost of the amount to mint back to the message sender.
        if (msg.value > (mintPrice * _amount)) {
            Address.sendValue(payable(msg.sender), msg.value - (mintPrice * _amount));
        }
    }

    /**
     * @dev Set Mint Price
     */
    function setMintPrice(uint256 _price) public onlyOwner {
        require(_price >= 0, "Price must be greater than or equal to 0.");
        mintPrice = _price;
    }

    /**
     * @dev Toggles Public Mint
     */
    function togglePublicMint() external onlyOwner {
        publicMintState = !publicMintState;
    }

    /**
     * @dev Withdraws Ether From Contract To Contract Owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
     * @dev Withdraws Ether From Contract To Specified Address
     */
    function withdrawTo(address _addr, uint256 _amountInWei) external onlyOwner 
    {
        Address.sendValue(payable(_addr), _amountInWei);
    }

    /**
     * @dev Override Is Approved For All
     */
    function isApprovedForAll(address account, address operator) override public view returns (bool) 
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(account)) == operator) { return true; }
        return ERC721A.isApprovedForAll(account, operator);
    }

}