// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract SavageBaskets is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_WHITELIST_SUPPLY = 333;
    uint256 public constant PUBLIC_SALE_PRICE = .11 ether;

    string private baseTokenUri;
    string public  placeholderTokenUri;
    
    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    //2 days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bool public pause;

    address[] private whitelistAddresses;
    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => uint256) public maxWhitelistMint;

    constructor() ERC721A("Savage Baskets", "SBSKT"){}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "SBSKT :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "SBSKT :: Not Yet Active.");
        require((_totalMinted() + _quantity) <= MAX_SUPPLY, "SBSKT :: Beyond Max Supply");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "SBSKT :: Below Ether Value");

        _mint(msg.sender, _quantity);
    }

    function whitelistMint(uint256 _quantity) external callerIsUser{
        require(whiteListSale, "SBSKT :: Minting is on Pause");
        require((_totalMinted() + _quantity) <= MAX_WHITELIST_SUPPLY, "SBSKT :: Cannot mint beyond whitelist max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= maxWhitelistMint[msg.sender], "SBSKT :: Cannot mint beyond whitelist max mint");
        if (whitelistAddresses.length > 0) {
            require(isAddressWhitelisted(msg.sender), "SBSKT :: Not on the whitelist");
        }

        totalWhitelistMint[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setTokenUri(string calldata _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string calldata _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setWhitelist(address[] calldata _addressArray, uint[] calldata _quantityArray) public onlyOwner {
        delete whitelistAddresses;
        whitelistAddresses = _addressArray;
        uint i = 0;
        while(i < _addressArray.length) {
            maxWhitelistMint[_addressArray[i]] = _quantityArray[i];
            ++i;
        }
    }

    function isAddressWhitelisted(address _user) private view returns (bool) {
        uint i = 0;
        while(i < whitelistAddresses.length) {
            if(whitelistAddresses[i] == _user) {
                return true;
            }
            ++i;
        }
        return false;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}