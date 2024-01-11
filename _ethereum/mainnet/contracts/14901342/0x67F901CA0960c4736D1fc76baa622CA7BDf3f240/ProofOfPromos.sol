// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721AWithRoyalties.sol";



contract ProofOfPromos is Ownable, ERC721AWithRoyalties,Pausable{

    string public _baseTokenURI;

    uint256 public _price;
    uint256 public _maxSupply;
    uint256 public _maxPerAddress;
    uint256 public _publicSaleTime;
    uint256 public _maxTxPerAddress;

    address payable immutable buybackAddress;

    mapping(address => uint256) private _purchases;
    event Purchase(address indexed addr, uint256 indexed atPrice, uint256 indexed count);
    
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 price,
        uint256 maxSupply,
        uint256 maxPerAddress,
        uint256 publicSaleTime,
        uint256 maxTxPerAddress, // price - 0, maxSupply - 1, maxPerAddress - 2, publicSaleTime - 3, _maxTxPerAddress - 4
        address royaltyRecipient,
        uint256 royaltyAmount,
        address _buybackAddress
    ) ERC721AWithRoyalties(
       name, 
       symbol,
       maxSupply, 
       royaltyRecipient, 
       royaltyAmount){
       _baseTokenURI = baseTokenURI;
       _price = price;
       _maxSupply = maxSupply;
       _maxPerAddress = maxPerAddress;
       _publicSaleTime = publicSaleTime;
       _maxTxPerAddress = maxTxPerAddress;
       buybackAddress = payable(_buybackAddress);
    }

   function setSaleInformation(
    uint256 publicSaleTime,
    uint256 maxPerAddress,
    uint256 price,
    uint256 maxTxPerAddress
  ) external onlyOwner {
    _publicSaleTime = publicSaleTime;
    _maxPerAddress = maxPerAddress;
    _price = price;
    _maxTxPerAddress = maxTxPerAddress;
  }

  function setBaseUri(
    string memory baseUri
  ) external onlyOwner {
    _baseTokenURI = baseUri;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return string(
      abi.encodePacked(
        _baseTokenURI,
        Strings.toHexString(uint256(uint160(address(this))), 20),
        '/'
      )
    );
  }

  function mint(address to, uint256 count) external payable onlyOwner {
    ensureMintConditions(count);

    _safeMint(to, count);
  }

  function purchase(uint256 count) external payable whenNotPaused {
    ensurePublicMintConditions(msg.sender, count, _maxPerAddress);
    require(isPublicSaleActive(), "BASE_COLLECTION/CANNOT_MINT");
    require(msg.value >= _price * count,"The price is not match.");
    _purchases[msg.sender] += count;
    _safeMint(msg.sender, count);
    emit Purchase(msg.sender, _price, count);
  }


  receive() external payable {
        revert("Please use the purchase function");
  }

  function ensureMintConditions(uint256 count) internal view {
    require(totalSupply() + count <= _maxSupply, "BASE_COLLECTION/EXCEEDS_MAX_SUPPLY");
  }

  function ensurePublicMintConditions(address to, uint256 count, uint256 maxPerAddress) internal view {
    ensureMintConditions(count);

    require((_maxTxPerAddress == 0) || (count <= _maxTxPerAddress), "BASE_COLLECTION/EXCEEDS_MAX_PER_TRANSACTION");
    uint256 totalMintFromAddress = _purchases[to] + count;
    require ((maxPerAddress == 0) || (totalMintFromAddress <= maxPerAddress), "BASE_COLLECTION/EXCEEDS_INDIVIDUAL_SUPPLY");
  }

  function isPublicSaleActive() public view returns (bool) {
    return (_publicSaleTime == 0 || _publicSaleTime < block.timestamp);
  }

  function isPreSaleActive() public pure returns (bool) {
    return false;
  }

  function MAX_TOTAL_MINT() public view returns (uint256) {
    return _maxSupply;
  }

  function PRICE() public view returns (uint256) {
    return _price;
  }

  function MAX_TOTAL_MINT_PER_ADDRESS() public view returns (uint256) {
    return _maxPerAddress;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function buyback() external onlyOwner{
    (bool sent, ) = buybackAddress.call{value: address(this).balance}("");
    require(sent, "Failed to withdraw");
  }

}
