// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Alchileverso is ERC721A, Ownable {

    using Address for address;
    address public paymentAddress = 0x27b474E9d076218F89c82506b6f7092a64e99125;

    // Starting and stopping sale, presale and whitelist
    bool public saleActive = false;
    bool public whitelistActive = true;

    // Price of each token
    uint256 public priceWhitelist = 0.04 ether; 
    uint256 public pricePublic = 0.05 ether; 

    // Maximum limit of tokens that can ever exist
    uint256 public constant MAX_SUPPLY = 2500;
    uint256 public constant MAX_SUPPLY_WHITELIST = 43;
    uint256 public constant MAX_MINT_PER_TX = 5;

    // The base link that leads to the image / video of the token
    string public baseURI = "https://alchileverso.s3.amazonaws.com/";
    bool public revealed = false;

    address[] public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;

    constructor () ERC721A ("Alchileverso", "ACV") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function changeRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI_ = _baseURI();

        if (revealed) {
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";
        } else {
            return string(abi.encodePacked(baseURI_, "hidden.json"));
        }
    }
    
    // Exclusive whitelist minting
    function mintWhitelist(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require( whitelistActive,                           "La whitelist no esta activa." );
        require( _amount > 0 && _amount <= MAX_MINT_PER_TX, "Solo pudes mintear de 1 a 5 tokens por transaccion." );
        require( supply + _amount <= MAX_SUPPLY_WHITELIST,  "No puedes mintar mas que la cantidad destinada al whitelist." );
        require( msg.value == priceWhitelist * _amount,     "Cantidad incorrecta de ETH." );
        _safeMint( msg.sender, _amount);
    }

    // Standard mint function
    function mintToken(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require( saleActive,                                "La venta publica no esta activa." );
        require( _amount > 0 && _amount <= MAX_MINT_PER_TX, "Solo pudes mintear de 1 a 5 tokens por transaccion." );
        require( supply + _amount <= MAX_SUPPLY,            "No puedes mintar mas que la cantidad destinada al publico." );
        require( msg.value == pricePublic * _amount,        "Cantidad incorrecta de ETH." );
        _safeMint( msg.sender, _amount);
    }

    /**
     * @notice return number of tokens minted by owner
     */
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

     // Start and stop whitelist
    function setWhitelistActive(bool val) public onlyOwner {
        whitelistActive = val;
    }

    // Start and stop sale
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    

    /**
     * @notice set payment address
     */
    function setPaymentAddress(address _paymentAddress) external onlyOwner {
        paymentAddress = _paymentAddress;
    }

    /**
     * @notice transfer funds
     */
    function transferFunds() external onlyOwner {
        (bool success, ) = payable(paymentAddress).call{value: address(this).balance}("");
        require(success, "TRANSFER_FAILED");
    }

}