//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./IERC721.sol";
import "./Ownable.sol";

contract ArkipelPass is ERC1155, ERC1155Burnable, ERC1155Supply, Ownable {
  uint256 public CURRENT_PASS_ID;
  uint256 public CURRENT_PASS_MAX_AMOUNT;
  uint256 public CURRENT_PASS_PRICE;
  uint256 public CURRENT_PASS_MAX_PURCHASE;
  uint256 public CURRENT_PASS_PRESALE_MAX_AMOUNT;
  uint256 public CURRENT_PASS_PRESALE_PRICE;

  address public ARTEFACT_PASS_ADDRESS;

  mapping(uint256 => uint256) public amountMinted;
  mapping(uint256 => uint256) public presaleAmountMinted;
  mapping(uint256 => mapping(address => bool)) public presaleList;
  mapping(uint256 => mapping(address => bool)) public freeMintList;
  mapping(uint256 => mapping(address => uint256))
    public presaleListMaxPurchases;
  mapping(uint256 => mapping(address => uint256)) public presaleListPurchases;
  mapping(uint256 => mapping(address => uint256)) public freeMintListMaxMint;
  mapping(uint256 => mapping(address => uint256)) public freeMintListMinted;
  mapping(uint256 => address) public redeemedArtefactPass;

  bool public isPresaleActive;
  bool public isSaleActive;
  bool public isArtefactPassAllowed;
  bool public isFreeMintActive;

  string public name = "Arkipel Pass";
  string public symbol = "ArkiPass";

  string private _contractURI;

  constructor() ERC1155("ipfs://") {}

  function presaleMint(uint256 quantity) public payable {
    require(quantity > 0, "QUANTITY_NEEDED");
    require(isPresaleActive && !isSaleActive, "PRESALE_CLOSED");
    require(presaleList[CURRENT_PASS_ID][msg.sender], "NOT_QUALIFIED");
    require(
      amountMinted[CURRENT_PASS_ID] < CURRENT_PASS_MAX_AMOUNT,
      "OUT_OF_STOCK"
    );
    require(
      amountMinted[CURRENT_PASS_ID] + quantity <= CURRENT_PASS_MAX_AMOUNT,
      "EXCEED_STOCK"
    );
    require(
      presaleAmountMinted[CURRENT_PASS_ID] + quantity <=
        CURRENT_PASS_PRESALE_MAX_AMOUNT,
      "EXCEED_PRESALE"
    );
    require(
      presaleListPurchases[CURRENT_PASS_ID][msg.sender] + quantity <=
        presaleListMaxPurchases[CURRENT_PASS_ID][msg.sender],
      "EXCEED_ALLOCATION"
    );
    require(
      CURRENT_PASS_PRESALE_PRICE * quantity <= msg.value,
      "INSUFFICIENT_ETH"
    );

    amountMinted[CURRENT_PASS_ID] += quantity;
    presaleAmountMinted[CURRENT_PASS_ID] += quantity;
    presaleListPurchases[CURRENT_PASS_ID][msg.sender] += quantity;

    _mint(msg.sender, CURRENT_PASS_ID, quantity, "");
  }

  function mint(uint256 quantity) public payable {
    require(quantity > 0, "QUANTITY_NEEDED");
    require(!isPresaleActive && isSaleActive, "SALE_CLOSED");
    require(
      amountMinted[CURRENT_PASS_ID] < CURRENT_PASS_MAX_AMOUNT,
      "OUT_OF_STOCK"
    );
    require(
      amountMinted[CURRENT_PASS_ID] + quantity <= CURRENT_PASS_MAX_AMOUNT,
      "EXCEED_STOCK"
    );
    require(quantity <= CURRENT_PASS_MAX_PURCHASE, "EXCEED_MAX_PURCHASE");
    require(CURRENT_PASS_PRICE * quantity <= msg.value, "INSUFFICIENT_ETH");

    amountMinted[CURRENT_PASS_ID] += quantity;

    _mint(msg.sender, CURRENT_PASS_ID, quantity, "");
  }

  function freeMint(uint256 quantity) public {
    require(isFreeMintActive, "FREE_MINT_CLOSED");
    require(isPresaleActive || isSaleActive, "SALE_CLOSED");
    require(freeMintList[CURRENT_PASS_ID][msg.sender], "NOT_QUALIFIED");
    require(
      amountMinted[CURRENT_PASS_ID] < CURRENT_PASS_MAX_AMOUNT,
      "OUT_OF_STOCK"
    );
    require(
      amountMinted[CURRENT_PASS_ID] + quantity <= CURRENT_PASS_MAX_AMOUNT,
      "EXCEED_STOCK"
    );
    require(
      freeMintListMinted[CURRENT_PASS_ID][msg.sender] + quantity <=
        freeMintListMaxMint[CURRENT_PASS_ID][msg.sender],
      "EXCEED_ALLOCATION"
    );

    amountMinted[CURRENT_PASS_ID] += quantity;
    freeMintListMinted[CURRENT_PASS_ID][msg.sender] += quantity;

    _mint(msg.sender, CURRENT_PASS_ID, quantity, "");
  }

  function mintByHoldArtefactPass(uint256 tokenId) public {
    require(!isPresaleActive && isSaleActive, "SALE_CLOSED");
    require(isArtefactPassAllowed, "ARTEFACT_FREE_MINT_CLOSED");
    require(
      amountMinted[CURRENT_PASS_ID] < CURRENT_PASS_MAX_AMOUNT,
      "OUT_OF_STOCK"
    );
    require(redeemedArtefactPass[tokenId] == address(0), "EXCEED_FREE_MINT");
    require(
      msg.sender == IERC721(ARTEFACT_PASS_ADDRESS).ownerOf(tokenId),
      "ONLY_ARTEFACT_OWNER"
    );

    amountMinted[CURRENT_PASS_ID]++;
    redeemedArtefactPass[tokenId] = msg.sender;

    _mint(msg.sender, CURRENT_PASS_ID, 1, "");
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setBaseURI(string memory uri) external onlyOwner {
    _setURI(uri);
  }

  function setContractURI(string memory uri) external onlyOwner {
    _contractURI = uri;
  }

  function setCurrentPass(
    uint256 tokenId,
    uint256 amount,
    uint256 price,
    uint256 maxPurchase,
    uint256 presaleAmount,
    uint256 presalePrice
  ) external onlyOwner {
    CURRENT_PASS_ID = tokenId;
    CURRENT_PASS_MAX_AMOUNT = amount;
    CURRENT_PASS_PRICE = price;
    CURRENT_PASS_MAX_PURCHASE = maxPurchase;
    CURRENT_PASS_PRESALE_MAX_AMOUNT = presaleAmount;
    CURRENT_PASS_PRESALE_PRICE = presalePrice;
  }

  function setArtefactPass(address tokenAddress) external onlyOwner {
    ARTEFACT_PASS_ADDRESS = tokenAddress;
  }

  function togglePresale() external onlyOwner {
    isPresaleActive = !isPresaleActive;
  }

  function toggleSale() external onlyOwner {
    isSaleActive = !isSaleActive;
  }

  function toggleFreeMint() external onlyOwner {
    isFreeMintActive = !isFreeMintActive;
  }

  function toggleArtefactPass() external onlyOwner {
    isArtefactPassAllowed = !isArtefactPassAllowed;
  }

  function addToPresaleList(
    address[] calldata entries,
    uint256[] calldata purchases
  ) external onlyOwner {
    for (uint256 i; i < entries.length; i++) {
      require(entries[i] != address(0), "NULL_ADDRESS");
      require(!presaleList[CURRENT_PASS_ID][entries[i]], "DUPLICATE_ENTRY");

      presaleList[CURRENT_PASS_ID][entries[i]] = true;
      presaleListMaxPurchases[CURRENT_PASS_ID][entries[i]] = purchases[i];
    }
  }

  function removeFromPresaleList(address[] calldata entries)
    external
    onlyOwner
  {
    for (uint256 i; i < entries.length; i++) {
      require(entries[i] != address(0), "NULL_ADDRESS");

      delete presaleList[CURRENT_PASS_ID][entries[i]];
      delete presaleListMaxPurchases[CURRENT_PASS_ID][entries[i]];
    }
  }

  function addToFreeMintList(
    address[] calldata entries,
    uint256[] calldata purchases
  ) external onlyOwner {
    for (uint256 i; i < entries.length; i++) {
      require(entries[i] != address(0), "NULL_ADDRESS");
      require(!freeMintList[CURRENT_PASS_ID][entries[i]], "DUPLICATE_ENTRY");

      freeMintList[CURRENT_PASS_ID][entries[i]] = true;
      freeMintListMaxMint[CURRENT_PASS_ID][entries[i]] = purchases[i];
    }
  }

  function removeFromFreeMintList(address[] calldata entries)
    external
    onlyOwner
  {
    for (uint256 i; i < entries.length; i++) {
      require(entries[i] != address(0), "NULL_ADDRESS");

      delete freeMintList[CURRENT_PASS_ID][entries[i]];
      delete freeMintListMaxMint[CURRENT_PASS_ID][entries[i]];
    }
  }

  function gift(address[] calldata receivers, uint256[] calldata amounts)
    external
    onlyOwner
  {
    require(
      amountMinted[CURRENT_PASS_ID] < CURRENT_PASS_MAX_AMOUNT,
      "OUT_OF_STOCK"
    );
    require(
      amountMinted[CURRENT_PASS_ID] + receivers.length <=
        CURRENT_PASS_MAX_AMOUNT,
      "EXCEED_STOCK"
    );

    for (uint256 i; i < receivers.length; i++) {
      require(receivers[i] != address(0), "NULL_ADDRESS");

      amountMinted[CURRENT_PASS_ID] += amounts[i];
      _mint(receivers[i], CURRENT_PASS_ID, amounts[i], "");
    }
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  // The following functions are overrides required by Solidity.

  function _burn(
    address account,
    uint256 id,
    uint256 amount
  ) internal override(ERC1155, ERC1155Supply) {
    super._burn(account, id, amount);
  }

  function _burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal override(ERC1155, ERC1155Supply) {
    super._burnBatch(account, ids, amounts);
  }

  function _mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    super._mint(account, id, amount, data);
  }

  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    super._mintBatch(to, ids, amounts, data);
  }
}
