// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

interface Game {
  function startGame() external;
  function isGameStarted() external view returns (bool);
}

/**
 * @title MetaVaultKeys contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation with Enumberable standart support.
*/
contract MetaVaultKeys is ERC721Enumerable, Ownable {
    // Base URI
    string private _gameBaseURI = "ipfs://QmRSXV4CB77RxtXcAnjFzhQ8WriH3NrRyewwiJEASkocdr/";
      

    // Max number of NFTs
    uint256 public constant MAX_SUPPLY = 1551;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public tokenPrice = 0.5 ether;

    // key limits
    uint256 public constant goldKeysLimit = 1000;
    uint256 public constant silverKeysLimit = 500;
    uint256 public constant whiteKeysLimit = 50;
    uint256 public constant diamondKeysLimit = 1;

    // Royalty info
    address public royaltyAddress;
    uint256 public ROYALTY_SIZE = 500; // 5%
    uint256 public ROYALTY_DEMONINATOR = 10000;
    mapping(uint256 => address) private _royaltyReceivers;

    Game public gameContract;

    // isSaleActive
    bool public saleIsActive = true;
    
    enum Keys {
      Gold,
      Silver,
      White,
      Diamond
    }

    mapping(uint256 => Keys) private _keyTypes;
    mapping(uint256 => uint256) private _keyTypesCount;

    // Mapping from owner to operator approvals
    mapping (address => uint256) private _mintedPerAddress;

    // Stores the addresses of people who has no limit for purchasing tokens
    mapping (address => bool) public isLimitExempt;

    event tokensMinted(
      address mintedBy,
      uint256[] tokenIds
    );

    event baseUriUpdated(
      string oldBaseUri,
      string newBaseUri
    );

    event tokensMintedFor(
      address mintedFor,
      uint256 tokenId
    );


    /**
     * @dev Initializes the contract.
     */
    constructor (address _royaltyAddress) 
      ERC721("Meta Vault Keys", "MVK"){
        isLimitExempt[_msgSender()] = true;
        royaltyAddress = _royaltyAddress;
    }

    modifier onlyGame {
      require(_msgSender() == address(gameContract), "Not Authorised");
      _;
    }

    function buyKeys(uint256 tokensNumber) public payable {
      require(saleIsActive, "The mint has not started yet");
      require(tokensNumber > 0, "Wrong amount requested");
      if (!isLimitExempt[_msgSender()]) {
        require(_mintedPerAddress[_msgSender()] + tokensNumber <= MAX_PER_WALLET, "You have hit the max Keys per wallet");
      }
      require(_keyTypesCount[uint256(Keys.Gold)] + tokensNumber <= goldKeysLimit, "You tried to mint more than the max allowed");

      if (_msgSender() != owner()) {
        require(tokensNumber * tokenPrice == msg.value,
          "You have not send enough ETH"
        );
      }

      uint256 amountToGame = msg.value/3;
      (bool sent, ) = address(gameContract).call{value: amountToGame}("");
      require(sent, "Error during transfer");

      uint256[] memory mintedTokens = new uint256[](tokensNumber);

      for(uint256 i = 0; i < tokensNumber; i++) {
        uint256 mintIndex = totalSupply();
        mintedTokens[i] = mintIndex;
        _mintedPerAddress[_msgSender()]++;

        _keyTypes[mintIndex] = Keys.Gold;
        _keyTypesCount[uint256(Keys.Gold)]++;

        _safeMint(msg.sender, mintIndex);
      }

      if (_keyTypesCount[uint256(Keys.Gold)] == goldKeysLimit 
        && !gameContract.isGameStarted()
      ) {
        gameContract.startGame();
      }

      emit tokensMinted(msg.sender, mintedTokens);
    }

    function mintFor(uint256 tokenType, address receiver) external onlyGame {
      require(
        Keys(tokenType) == Keys.Silver
        || Keys(tokenType) == Keys.White
        || Keys(tokenType) == Keys.Diamond,
        "Unknown token type"
      );

      if (Keys(tokenType) == Keys.Silver) require(_keyTypesCount[tokenType] + 1 <= silverKeysLimit, "You tried to mint more than the max allowed");
      if (Keys(tokenType) == Keys.White) require(_keyTypesCount[tokenType] + 1 <= whiteKeysLimit, "You tried to mint more than the max allowed");
      if (Keys(tokenType) == Keys.Diamond) require(_keyTypesCount[tokenType] + 1 <= diamondKeysLimit, "You tried to mint more than the max allowed");
      
      uint256 mintIndex = totalSupply();

      _keyTypes[mintIndex] = Keys(tokenType);
      _keyTypesCount[tokenType]++;

      _safeMint(receiver, mintIndex);

      emit tokensMintedFor(receiver, mintIndex);
    }

    function getTokenType(uint256 tokenId) public view returns (uint256) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      return uint256(_keyTypes[tokenId]);
    }

    function getKeysCount() public view returns (uint256,uint256,uint256,uint256) {
      return (
        _keyTypesCount[uint256(Keys.Gold)],
        _keyTypesCount[uint256(Keys.Silver)],
        _keyTypesCount[uint256(Keys.White)],
        _keyTypesCount[uint256(Keys.Diamond)]
      );
    }

    function updateSaleStatus(bool status) public onlyOwner {
      require(tokenPrice != 0, "Price is not set");
      saleIsActive = status;
    }

    function limitExempt(address addressToExempt, bool shouldExampt) public onlyOwner {
      isLimitExempt[addressToExempt] = shouldExampt;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
      require(tokenPrice == 0, "Price already set");
      tokenPrice = _tokenPrice;
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
      string memory currentURI = _gameBaseURI;
      _gameBaseURI = newBaseURI;
      emit baseUriUpdated(currentURI, newBaseURI);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
       require(_exists(_tokenId), "Token does not exist.");
       return string(abi.encodePacked(_baseURI(), Strings.toString(getTokenType(_tokenId)),".json"));
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _gameBaseURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      uint256 amount = _salePrice * ROYALTY_SIZE / ROYALTY_DEMONINATOR;
      address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0) ? _royaltyReceivers[_tokenId] : royaltyAddress;
      return (royaltyReceiver, amount);
    }

    function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId) public onlyOwner {
      _royaltyReceivers[tokenId] = receiver;
    }

    /**
     * @dev Withdraw BNB from this contract (Callable by owner)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function setGameAddress(address _gameAddress) onlyOwner public {
      gameContract = Game(_gameAddress);
    }
}