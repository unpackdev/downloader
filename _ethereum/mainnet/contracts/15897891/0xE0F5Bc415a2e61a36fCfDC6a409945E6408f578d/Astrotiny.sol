// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC20.sol";


contract Astrotiny is ERC721, Ownable {
    using Counters for Counters.Counter;

    struct RoyaltyInfo {
        address recipient;
        uint256 amount;
    }
    
    RoyaltyInfo private _royalties;

    //Interface for royalties
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    Counters.Counter private _tokenIds;

    //comparisons are strictly less than for gas efficiency.
    uint256 public constant MAX_SUPPLY = 151;
    uint256 private _maxReservedNfts;
    
    uint256 public price = 0.5 ether;

    string public baseTokenURI;

    event NFTMinted(uint256, uint256, address);

    //amount of mints that each address has executed.
    mapping(address => uint256) public mintsPerAddress;

    constructor(string memory baseURI) ERC721("Astrotiny", "AST") {
        baseTokenURI = baseURI;
        setRoyalties(owner(), 500);
        
    }

    //ensure that modified function cannot be called by another contract
    modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

    function _baseURI() internal view override returns (string memory) {
       return baseTokenURI;
    }
    
    function reveal(string memory _newBaseTokenURI) public onlyOwner {
        baseTokenURI = _newBaseTokenURI;
    }

    function mintNFTs(uint256 _number) public callerIsUser payable {
        uint256 totalMinted = _tokenIds.current();

        require(totalMinted + _number < MAX_SUPPLY, "Not enough NFTs!");
        require(msg.value == price * _number , "Not enough/too much ether sent");

        for (uint i = 0; i < _number; ++i) {
            _mintSingleNFT();
        }

        emit NFTMinted(_number, _tokenIds.current(), msg.sender);
    }


    function _mintSingleNFT() internal {
      uint newTokenID = _tokenIds.current();
      _tokenIds.increment();
      _safeMint(msg.sender, newTokenID);
    }

    function reservedNfts() public callerIsUser onlyOwner {
        require(_maxReservedNfts < 1, "Cannot mint more reserved NFTs");
        _maxReservedNfts += 1;

        _mintSingleNFT();
    }

    function getCurrentId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    //Withdraw money in contract to Owner
    function withdraw() external onlyOwner {
     uint256 balance = address(this).balance;
     require(balance > 0, "No ether left to withdraw");

     (bool success, ) = payable(owner()).call{value: balance}("");

     require(success, "Transfer failed.");
    }

    function withdraAllERC20(IERC20 _erc20Token) external onlyOwner {
        _erc20Token.transfer(owner(), _erc20Token.balanceOf(address(this)));
    }

    //interface for royalties
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool){

        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        require(value <= 10000, 'ERC2981Royalties: Too high');

        _royalties = RoyaltyInfo(recipient, value);
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }

    //fallback receive function
        receive() external payable { 
            revert();
    }
    
}