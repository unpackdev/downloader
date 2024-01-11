// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./AccessControl.sol";
import "./FEEVMembershipNFT.sol";
import "./console.sol";

/// @dev Smart contract to handle sale of several NFT collections
contract SalesContract is AccessControl {
  /// @dev It is emitted when new purchase will be made
  /// @param user Account of buyer
  /// @param nftCollection Address of collection's NFT contract
  /// @param price Amount of payment token
  /// @param boughtNFTs Amount of bought NFT tokens
  event Purchase(
    address indexed user,
    address indexed nftCollection,
    uint256 price,
    uint256 boughtNFTs
  );

  /// @dev It is emitted when new address is added to whitelist
  /// @param account Acounts on whitelist
  event AddToWhitelist(address indexed account);

  /// @dev It is emitted when address is removed from whitelist
  /// @param account Accounts removed  from whitelist
  event RemoveFromWhitelist(address indexed account);

  /// @dev it is emitted when raised funds will be withdrawn
  /// @param caller Address of administrator
  /// @param amount Amount of withdrawn ETH
  /// @param account Address of wallet where tokens were sent
  event WithdrawFunds(address indexed caller, uint256 amount, address indexed account);

  /// @dev user address => NFT collection address => amount of bought NFTs
  mapping(address => mapping(address => uint256)) private boughtNFTs;
  /// @dev NFT collection address => amount of sold NFTs
  mapping(address => uint256) private soldNFTs;
  /// @dev amount of available tokens per collection to buy by one wallet
  uint8 public constant LIMIT_PER_USER = 3;
  /// @dev user address => has access to buy
  mapping(address => bool) private whitelist;

  uint256 public whitelistedSaleStart;
  uint256 public publicSaleStart;
  uint256 public saleEnd;

  /// @dev Contructor of sales contract
  /// @param administrator Address of administrator's wallet
  /// @param _whitelistedSaleStart Timestamp of whitelisted start sale
  /// @param _publicSaleStart Timestamp of start public sale
  /// @param _saleEnd Timestamp of end sale
  constructor(
    address administrator,
    uint256 _whitelistedSaleStart,
    uint256 _publicSaleStart,
    uint256 _saleEnd
  ) {
    _grantRole(DEFAULT_ADMIN_ROLE, administrator);
    whitelistedSaleStart = _whitelistedSaleStart;
    publicSaleStart = _publicSaleStart;
    saleEnd = _saleEnd;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only for admin");
    _;
  }

  /// @dev Function to buy tokens from NFT collections
  /// @param nftCollection Address of NFT collection contract
  /// @param nftsAmount Amount NFTs to buy
  function buyNFT(FEEVMembershipNFT nftCollection, uint256 nftsAmount) external payable {
    validateAccessToSale(msg.sender);

    require(nftsAmount > 0, "Invalid NFTs amount");
    require(
      getBoughtNFTs(msg.sender, address(nftCollection)) + nftsAmount <= LIMIT_PER_USER,
      "Tokens limit per collection (3) is reached by user"
    );
    uint256 nftSupply = nftCollection.totalSupply();
    uint256 nftMaxSupply = nftCollection.maxSupply();

    require(nftSupply + nftsAmount <= nftMaxSupply, "NFT max supply limit is reached");

    uint256 price = nftCollection.getPrice(nftsAmount);

    require(msg.value == price, "Insufficient ETH amount");

    nftCollection.safeMint(msg.sender, nftsAmount);
    boughtNFTs[msg.sender][address(nftCollection)] += nftsAmount;
    soldNFTs[address(nftCollection)] += nftsAmount;

    emit Purchase(msg.sender, address(nftCollection), price, nftsAmount);
  }

  /// @dev Getter for bought nft from given collection by user
  /// @param user Address of user
  /// @param nftCollectionAddress Address of NFT collection contract
  /// @return uint256 Amount of bought NFTs
  function getBoughtNFTs(address user, address nftCollectionAddress) public view returns (uint256) {
    return boughtNFTs[user][nftCollectionAddress];
  }

  /// @dev Getter for total amount of sold NFT from specific collection
  /// @param nftCollectionAddress Address of NFT collection contract
  /// @return uint256 Amount of sold NFTs
  function getSoldNFTs(address nftCollectionAddress) external view returns (uint256) {
    return soldNFTs[nftCollectionAddress];
  }

  /// @dev Function to withdraw raised funds
  /// @param account Address of wallet where tokens will be sent
  /// @param amount Amount of token to withdraw
  /// @notice It can be called only by administrator
  function withdrawFunds(address account, uint256 amount) external onlyAdmin {
    uint256 balance = address(this).balance;

    require(balance >= amount, "Insufficient balance on sales contract");

    (bool success, ) = payable(account).call{value: amount}("");

    require(success, "Failed to sent ETH");
    emit WithdrawFunds(msg.sender, amount, account);
  }

  /// @dev Function to set whitelisted sale start
  /// @param start Timestamp of whitelisted sale start date
  /// @notice It can be called only by administrator
  function setWhitelistedSaleStart(uint256 start) external onlyAdmin {
    require(start > block.timestamp, "The date needs to be future");
    require(start < publicSaleStart, "The date needs to be before public sale start");
    whitelistedSaleStart = start;
  }

  /// @dev Function to set public sale start
  /// @param start Timestamp of public sale start date
  /// @notice It can be called only by administrator
  function setPublicSaleStart(uint256 start) external onlyAdmin {
    require(start > block.timestamp, "The date needs to be future");
    require(
      start > whitelistedSaleStart,
      "The date needs to be after start date of whitelisted sale"
    );
    require(start < saleEnd, "The date needs to be before public sale end");
    publicSaleStart = start;
  }

  /// @dev Function to set sale end date
  /// @param end Timestamp of end sale date
  /// @notice It can be called only by administrator
  function setSaleEnd(uint256 end) external onlyAdmin {
    require(end > block.timestamp, "The date needs to be future");
    require(end > publicSaleStart, "The date needs to be after start date of public sale");
    saleEnd = end;
  }

  /// @dev Checking is wallet address is on the whitelist or have at least one NFT from defined collections
  /// @param _address particular wallet address
  function isWhitelisted(address _address) public view returns (bool) {
    if (
      whitelist[_address] ||
      IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D).balanceOf(_address) > 0 || // Bored Ape Yacht Club
      IERC721(0x60E4d786628Fea6478F785A6d7e704777c86a7c6).balanceOf(_address) > 0 || // Mutant Ape Yacht Club
      IERC721(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB).balanceOf(_address) > 0 || // Crypto Punks
      IERC721(0x3598Fff0f78Dd8b497e12a3aD91FeBcFC8F49d9E).balanceOf(_address) > 0 || // Private Jet Pyjama Party
      IERC721(0xe785E82358879F061BC3dcAC6f0444462D4b5330).balanceOf(_address) > 0 || // World of Women
      IERC721(0x75E95ba5997Eb235F40eCF8347cDb11F18ff640B).balanceOf(_address) > 0 || // Psychedelics Anonymous
      IERC1155(0x28472a58A490c5e09A238847F66A68a47cC76f0f).balanceOf(_address, 0) > 0 // Adidas Originals Into the Metaverse
    ) {
      return true;
    }

    return false;
  }

  /// @dev Adding array of addresses to whitelist
  /// @param addresses array of addresses
  /// @notice It can be called only by admin
  function addToWhitelist(address[] memory addresses) public onlyAdmin {
    for (uint16 i = 0; i < addresses.length; i++) {
      if (!whitelist[addresses[i]]) {
        whitelist[addresses[i]] = true;
        emit AddToWhitelist(addresses[i]);
      }
    }
  }

  /// @dev Remove array of addresses from whitelist
  /// @param addresses array of addresses
  /// @notice It can be called only by admin
  function removeFromWhitelist(address[] memory addresses) public onlyAdmin {
    for (uint16 i = 0; i < addresses.length; i++) {
      if (whitelist[addresses[i]]) {
        whitelist[addresses[i]] = false;
        emit RemoveFromWhitelist(addresses[i]);
      }
    }
  }

  function validateAccessToSale(address user) private view {
    require(block.timestamp >= whitelistedSaleStart, "Sale is not opened");
    require(block.timestamp <= saleEnd, "Sales is closed");

    if (publicSaleStart > block.timestamp) {
      require(isWhitelisted(user), "You are not whitelisted to buy NFT");
    }
  }
}
