// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

// REMIX
// import "./ERC721Upgradeable.sol";
// import "./OwnableUpgradeable.sol";
// import "./Initializable.sol";
// import "./CountersUpgradeable.sol";
// import "./SafeMathUpgradeable.sol";
// import "./AddressUpgradeable.sol";
// import "./EnumerableSetUpgradeable.sol";
// import "./EnumerableMapUpgradeable.sol";

// TRUFFLE
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";

// NFTParentImpl SMART CONTRACT
contract NFTParentImpl is
  Initializable,
  ERC721Upgradeable,
  OwnableUpgradeable
{
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter private _tokenIds;
  using SafeMathUpgradeable for *;
  mapping(string => uint8) public hashes;
  // user address => admin? mapping
  mapping(address => bool) private _admins;
  address private _nftSaleAddress = address(0);

  event AdminAccessSet(address _admin, bool _enabled);

  /**
   * This function acts as the constructor
   *
   */
  function initialize() external initializer {
    __Ownable_init();
    __ERC721_init("Non Fungible Token", "NFT");
    _admins[msg.sender] = true;
  }

  /**
   * Set Admin Access
   *
   * @param admin - Address of Minter
   * @param enabled - Enable/Disable Admin Access
   */
  function setAdmin(address admin, bool enabled) external onlyOwner {
    _admins[admin] = enabled;
    emit AdminAccessSet(admin, enabled);
  }

  /**
   * Check Admin Access
   *
   * @param admin - Address of Admin
   * @return whether minter has access
   */
  function isAdmin(address admin) public view returns (bool) {
    return _admins[admin];
  }

  /**
   * Override isApprovedForAll to allow our NFT sale
   */
  // function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
  //   return _operatorApprovals[owner][operator] || operator == _nftSaleAddress;
  // }

  /**
   * Set sale address
   *
   * @param nftSaleAddress Sale contract
   */
  function setNftSaleAddress(address nftSaleAddress) public onlyAdmin {
    require(_nftSaleAddress == address(0));
    _nftSaleAddress = nftSaleAddress;
  }

  /**
   * Mint + Issue NFT
   *
   * @param recipient - NFT will be issued to recipient
   * @param hash - Artwork IPFS hash
   * @param data - Artwork URI/Data
   */
  function issueToken(
    address recipient,
    string memory hash,
    string memory data
  ) public onlyAdmin returns (uint256) {
    require(hashes[hash] != 1);
    hashes[hash] = 1;
    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();
    _mint(recipient, newTokenId);
    _setTokenURI(newTokenId, data);
    return newTokenId;
  }

  /**
   * Get Holder Token IDs
   *
   * @param holder - Holder of the Tokens
   */
  function getHolderTokenIds(address holder)
    public
    view
    returns (uint256[] memory)
  {
    uint256 count = balanceOf(holder);
    uint256[] memory result = new uint256[](count);
    uint256 index;
    for (index = 0; index <= count - 1; index++) {
      result[index] = tokenOfOwnerByIndex(holder, index);
    }
    return result;
  }

  /**
   * Throws if called by any account other than the Admin.
   */
  modifier onlyAdmin() {
    require(
      _admins[msg.sender] || msg.sender == owner(),
      "Caller does not have Admin Access"
    );
    _;
  }
}
