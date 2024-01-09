// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ECDSA.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";



contract ApeSoldiers is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;

        // Base URI
    string private _nftBaseURI = 'https://soldierapes.io/api/meta/';

    // Token Supply
    uint private constant _totalSupply = 10025;
    uint private currentSupply = 0;

    // Date of release;
    uint public releaseTimestamp = 1644944400; 

    // Public sale start timestamp

    uint public publicSaleStartTimestamp;

    // Token Price
    uint256 public tokenPrice = 120000000000000000;
    uint256 public constant presalePrice = 80000000000000000;

    // Contract Owner
    address private _contractOwner;
    address private _signer;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    mapping (address => uint256) private _mintedTokens;

    bool public preSaleActive = true;
    bool public publicSaleActive = false;

    // events
    event tokensMinted(
        address mintedBy,
        uint numberOfTokensMinted
    );

     event baseUriUpdated(
      string oldBaseUri,
      string newBaseUri
    );

    constructor()ERC721("Soldier Apes Army", "SAA"){
        _contractOwner = _msgSender();
        _signer = _msgSender();
    }

    function mintPurchasedTokens(uint256 tokensNumber) internal {
      for(uint i = 0; i<tokensNumber; i++) {
        currentSupply++;
        _mint(msg.sender, currentSupply);
      }
    }

    function getSignerAddress(address caller, bytes calldata signature) internal pure returns (address) {
      bytes32 dataHash = keccak256(abi.encodePacked(caller));

        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        return ECDSA.recover(message, signature);
    }

    function getCurrentPrice() public view returns (uint256) {
         if (preSaleActive) { 
          return presalePrice; 
         }else{
            return tokenPrice;
         }
    }

    function buyTokensOnPresale(uint256 tokensNumber, bytes calldata signature) public payable {
      require(preSaleActive, "Sale is closed at this moment");
      require(block.timestamp >= releaseTimestamp, "Purchase is not available now");
      require(tokensNumber <= 3, "You cannot purchase more than 3 tokens at once");
      require(_mintedTokens[msg.sender].add(tokensNumber) <= 3, 'You cannot purchase more then 3 tokens on Presale');
      require((tokensNumber.mul(getCurrentPrice())) == msg.value, "Received value doesn't match the requested tokens");
      require((currentSupply.add(tokensNumber)) <= _totalSupply, "You try to mint more tokens than totalSupply");

      address signer = getSignerAddress(msg.sender, signature);
      require(signer != address(0) && signer == _signer, 'claim: Invalid signature!');

      _mintedTokens[msg.sender] = _mintedTokens[msg.sender].add(tokensNumber);
      mintPurchasedTokens(tokensNumber);
    }

    function buyTokens(uint256 tokensNumber) public payable {
        require(publicSaleActive, "Sale is closed at this moment");
        require(tokensNumber <= 10, "You cannot purchase more than 10 tokens at once");
        require(_mintedTokens[msg.sender].add(tokensNumber) <= 100, 'You cannot purchase more then 100 tokens');
        require((tokensNumber.mul(getCurrentPrice())) == msg.value, "Received value doesnt match the requested tokens");
        require((currentSupply.add(tokensNumber)) <= _totalSupply, "You try to mint more tokens than totalSupply");

        mintPurchasedTokens(tokensNumber);
    }

    function sendTokensForGiveaway(address[] memory receivers) public onlyOwner {
       require(receivers.length <= 25, 'receivers quantity can not be greater than 25');
       require((currentSupply.add(receivers.length)) <= _totalSupply, "You try to mint more tokens than totalSupply");
       for(uint i = 0; i<receivers.length; i++) {
        currentSupply++;
        _mint(msg.sender, currentSupply);
        transferFrom(msg.sender, receivers[i], currentSupply);
      }
    }

    function withdraw() public onlyOwner {
      uint256 value = address(this).balance;
      bool sent = payable(_msgSender()).send(value);
      require(sent, "Error during withdraw transfer");
    }

     function setReleaseDate(uint _releaseTimestamp) public onlyOwner {
      require(_releaseTimestamp > block.timestamp, 'timestamp should be greater than block timestamp');
       releaseTimestamp = _releaseTimestamp;
    }

 
    function totalSupply() external view returns (uint256) {
      return currentSupply;
    }

    function triggerPresale() public onlyOwner{
      require(!publicSaleActive, 'Public sale already active');

      preSaleActive = !preSaleActive;
    }

    function activatePublicSale() public onlyOwner {
      require(!preSaleActive, 'Deactivate pre-sale first');
      publicSaleActive = !publicSaleActive;      
      publicSaleStartTimestamp = block.timestamp;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
      string memory currentURI = _nftBaseURI;
      _nftBaseURI = newBaseURI;
      emit baseUriUpdated(currentURI, newBaseURI);
    }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory uriEnding = (publicSaleActive && block.timestamp - publicSaleStartTimestamp > 172800) ? tokenId.toString() : 'screensaver';
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, uriEnding)) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return _nftBaseURI;
    }

    function changeSignerAddress(address newSigner) public onlyOwner {
      _signer = newSigner;
    }
}