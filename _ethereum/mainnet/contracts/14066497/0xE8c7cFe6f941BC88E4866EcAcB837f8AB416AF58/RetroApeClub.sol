// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract RetroApeClub is  Ownable, ERC721Burnable, ERC721Pausable{
    //using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenCounter;

    string private _baseTokenUri;
    string public placeholder;

    uint256 public RetroApeClubPrice = 5 * 10 ** 16;

    bool public isRevealed;
    
    address financeAddress = 0x77d2A16DCe85372a37719754BFfEbDd4266a5e2d; // address testnet 0x1655147A35e6Cafc1d6E587414286e6287698B7f

    mapping(address => uint256) public walletMintCount;
    mapping(address => bool) public isFreeMintClaimed;
    mapping(address => bool)public freeMintList;

    event mintRetroApeClub(uint256 indexed id, address minter);

    constructor(string memory baseUri, string memory _placeholder) ERC721("RetroApeClub", "RAC"){
        setBaseUri(baseUri);
        placeholder = _placeholder;
        pause(true);
    }

    function totalSupply() public view returns(uint){
        return _tokenCounter.current();
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(!isRevealed){
            return placeholder;
        }
        //string memory baseURI = _baseURI();
        return bytes(_baseTokenUri).length > 0 ? string(abi.encodePacked(_baseTokenUri, tokenId.toString())) : "";
    }

    function setFreeMintList(address[] memory _freeMintList) public onlyOwner{
        for(uint256 index = 0; index < _freeMintList.length; index++){
            freeMintList[_freeMintList[index]] = true;
        }
        return;
    }

    function unsetFreeMintList(address[] memory _freeMintList) public onlyOwner{
        for(uint256 index = 0; index < _freeMintList.length; index++){
            freeMintList[_freeMintList[index]] = false;
        }
        return;
    }

    function setFinanceAddress(address _financeAddress)public onlyOwner{
        financeAddress = _financeAddress;
        return;
    }

    function setPlaceholder(string memory _placeholder)public onlyOwner{
        placeholder = _placeholder;
        return;
    }

    function setRevealed(bool _isRevealed) public onlyOwner{
        isRevealed = _isRevealed;
        return;
    }

    function mint(uint256 _quantity) public payable{
        require((totalSupply() + _quantity) <= 5000 , "RetroApeClub: Cannot mint beyond max supply!");
        require(msg.value >= (RetroApeClubPrice * _quantity), "RetroApeClub: Payment is below the Price!");

        payable(financeAddress).transfer(msg.value);
        //_mintARetroApeClub(msg.sender, _tokenCounter.current());
        for(uint256 pointer = 0; pointer < _quantity; pointer++){
            walletMintCount[msg.sender] ++;
            _safeMint(msg.sender, totalSupply());
            _tokenCounter.increment();
        }
        return;
    }

    function freeMint() public payable{
        require(freeMintList[msg.sender], "RetroApeClub: You aren't eligible for free mints!");
        require(!isFreeMintClaimed[msg.sender], "RetroApeClub: You Already Claimed Your Free Mints!");
        require((totalSupply() + 3) <= 5000, "RetroApeClub: Cannot Mint Free Mints");
        
        isFreeMintClaimed[msg.sender] = true;
        walletMintCount[msg.sender] = 3;

        for(uint256 index; index < 3; index++){
            _safeMint(msg.sender, totalSupply());
            _tokenCounter.increment();
        }

        return;
    }

    function setBaseUri(string memory baseUri) public onlyOwner{
        _baseTokenUri = baseUri;
    }

    function pause(bool isPaused)public onlyOwner{
        if(isPaused == true){
            _pause();
            return;
        }
        
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}