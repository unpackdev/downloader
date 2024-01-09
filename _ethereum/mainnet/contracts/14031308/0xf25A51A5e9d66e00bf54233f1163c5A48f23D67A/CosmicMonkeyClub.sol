// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

/* Xinusu Written xinusu@gmail.com */

contract CosmicMonkeyClub is ERC721Enumerable, Ownable {

    /* Define */
    mapping(address => uint) public whitelistRemaining;
    // Maps user address to their remaining mints if they have minted some but not all of their allocation

    /* Pricing */
    uint public whitelistPrice = 0.088 ether;
    uint public mintPrice = 0.11 ether;

    /* Max's */
    uint public maxItems = 10000;
    uint public maxItemsPerTx = 6;
    uint public maxItemsPerPublicUser = 6;
    uint public maxItemsPerWLUser = 4;

    /* Team Mint Total */
    uint public teamMintTotal = 200;
    bool public teamMintComplete = false;

    /* Times */
    uint public startWlTimestamp = 1642378825;
    uint public startPublicTimestamp = 1642380025;
    uint public finalTimestamp;

    /* Revealed */
    bool public revealed = false;
    string public unrevealedURI = 'https://ipfs.infura.io/ipfs/QmZgnDxGELqSd42QwQXieMDTXe37rSJsbR89mnk9prECoh';

    /* Addtional */
    address public recipient;
    string public _baseTokenURI;

    /* State */
    bool public isPublicLive = false;
    bool public isWhitelistLive = false;

    /* Private */
    /* locked */
    bool private withdrawlLock = false;

    /* Events */
    event Mint(address indexed owner, uint indexed tokenId);

    event PermanentURI(string tokenURI, uint256 indexed _id);

    /* Constructor */
    constructor() ERC721("Cosmic Monkey Club", "COSMIC") {
      /* Transfer ownership of contract to message sender */
      /* transferOwnership(msg.sender); */

      /* Set recipient to msg.sender */
      recipient = msg.sender;
    }

    modifier whitelistMintingOpen() {
      if(block.timestamp >= startWlTimestamp && isWhitelistLive){
        isWhitelistLive = true;
      }
      /* require(finalTimestamp >= block.timestamp, "The mint has already closed"); */
      require(block.timestamp >= startWlTimestamp, "Whitelist Mint is not open yet");
      _;
    }

    modifier publicMintingOpen() {
      if(block.timestamp >= startWlTimestamp && isPublicLive){
        isPublicLive = true;
      }
      /* require(finalTimestamp >= block.timestamp, "The mint has already closed"); */
      require(block.timestamp >= startPublicTimestamp, "Public Mint is not open yet");
      _;
    }

    /* External */
    function publicMint(uint amount) external payable publicMintingOpen {
        // Require nonzero amount
        require(amount > 0, "Mint must be greater than zero");

        // Check proper amount sent
        require(msg.value == amount * mintPrice, "You need more ETH");

        _mintWithoutValidation(msg.sender, amount);
    }

    function whitelistMint(uint amount) external payable whitelistMintingOpen {
        // Require nonzero amount
        require(amount > 0, "Mint must be greater than zero");


        require(whitelistRemaining[msg.sender] >= amount, "Cant mint more than remaining allocation");

        whitelistRemaining[msg.sender] -= amount;
        _mintWithoutValidation(msg.sender, amount);
    }

    function ownerMint(uint amount) external onlyOwner {
      /* Complete Dev Mint Automatically - to stated amount */
      _mintWithoutValidation(msg.sender, amount);
    }

    function teamMint200() external onlyOwner {
      require(!teamMintComplete, "This function can only be run once, and it has already been run");
      /* Complete Dev Mint Automatically - to stated amount */
      _mintWithoutValidation(msg.sender, teamMintTotal);
      teamMintComplete = true;
    }

    /* Intenal */
    function _mintWithoutValidation(address to, uint amount) internal {
      require(totalSupply() + amount <= maxItems, "All of Monkeys are out in the Cosmo and so we are sold out");
      require(amount <= maxItemsPerTx, "Max mint amount is 6 Monkeys per Mint");

      for (uint i = 0; i < amount; i++) {
        uint currentTotal = totalSupply();
        _mint(to, currentTotal);
        emit Mint(to, currentTotal);
      }
    }

    // ADMIN FUNCTIONALITY
    // EXTERNAL

    function setMaxItems(uint _maxItems) external onlyOwner {
      maxItems = _maxItems;
    }

    function setRecipient(address _recipient) external onlyOwner {
      recipient = _recipient;
    }

    function revealData(string memory __baseTokenURI) external onlyOwner {
      require(!revealed);
      revealed = true;
      setBaseTokenURI(__baseTokenURI);

      for (uint i = 0; i <= totalSupply(); i++) {
        emit PermanentURI(string(abi.encodePacked(__baseTokenURI,'/',i)), i);
      }
    }

    function triggerWl() external onlyOwner {
        isWhitelistLive = true;
    }

    function triggerPublic() external onlyOwner {
        isPublicLive = true;
    }

    function setFinalTimestamp(uint _finalTimestamp) external onlyOwner {
      finalTimestamp = _finalTimestamp;
    }

/* require(finalTimestamp >= block.timestamp, "The mint has already closed");
      require(block.timestamp >= startPublicTimestamp, "Public Mint is not open yet"); */

    function setBaseTokenURI(string memory __baseTokenURI) internal onlyOwner {
      _baseTokenURI = __baseTokenURI;
    }

    function adjustMaxMintAmount(uint _maxMintAmount) external onlyOwner {
      require(msg.sender == recipient, "This function is an Owner only function");
      maxItemsPerTx = _maxMintAmount;
    }

    function whitelistUsers(address[] memory users) external onlyOwner {
      require(users.length > 0, "You havent entered any addresses");
      for (uint i = 0; i < users.length; i++) {
        whitelistRemaining[users[i]] = maxItemsPerWLUser;
      }
    }

    // WITHDRAWAL FUNCTIONALITY
    /**
     * @dev Withdraw the contract balance to the recipient address
     */
    function withdraw() external onlyOwner {
      require(!withdrawlLock);
      withdrawlLock = true;

      uint amount = address(this).balance;
      (bool success,) = recipient.call{value: amount}("");
      require(success, "Failed to send ether");

      withdrawlLock = false;
    }

    // METADATA FUNCTIONALITY
    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
      if(revealed){
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
      } else {
        return string(abi.encodePacked(unrevealedURI));
      }
    }
}
