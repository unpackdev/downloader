// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./ERC1155DeltaQueryableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

/**
 /$$$$$$$  /$$$$$$$$ /$$$$$$$  /$$$$$$$  /$$$$$$$  /$$$$$$$$
| $$__  $$| $$_____/| $$__  $$| $$__  $$| $$__  $$|_____ $$ 
| $$  \ $$| $$      | $$  \ $$| $$  \ $$| $$  \ $$     /$$/ 
| $$  | $$| $$$$$   | $$  | $$| $$$$$$$/| $$$$$$$/    /$$/  
| $$  | $$| $$__/   | $$  | $$| $$____/ | $$__  $$   /$$/   
| $$  | $$| $$      | $$  | $$| $$      | $$  \ $$  /$$/    
| $$$$$$$/| $$$$$$$$| $$$$$$$/| $$      | $$  | $$ /$$$$$$$$
|_______/ |________/|_______/ |__/      |__/  |__/|________/

www.dedprz.com
*/

/**
 * @title DEDPRZ NFT
 * @dev Contains token-gated minting, extends ERC1155Delta from ctor.xyz
 */

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

contract DEDPRZ is
  Initializable,
  ERC1155DeltaQueryableUpgradeable,
  ERC2981Upgradeable,
  DefaultOperatorFiltererUpgradeable
{
  address public owner; // contract owner
  IERC20 public whitelistToken; // whitelist token address

  uint256 public constant MAX_SUPPLY = 1776; // max supply

  bool public publicMinting; // mintable state

  event Minted(address indexed to, uint256 indexed amount); // minted event
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  ); // ownership transfer event
  event SetURI(string indexed uri); // set uri event
  event Withdraw(address indexed to, uint256 indexed amount); // withdraw event

  /// @dev Modifier for owner only functions
  modifier onlyOwner() {
    require(msg.sender == owner, 'OnlyOwner');
    _;
  }

  /// @dev Initialize contract
  function initialize(address _whitelistToken) public initializer {
    __ERC1155Delta_init('https://dedprz-1776.s3.amazonaws.com/{id}.json');
    __ERC2981_init();
    __DefaultOperatorFilterer_init();

    owner = msg.sender;

    whitelistToken = IERC20(_whitelistToken);

    publicMinting = false;

    _setDefaultRoyalty(owner, 500);
  }

  // *** SETTERS ***

  /**
   * @notice Mint tokens to address
   * @param to Address minting to
   * @param amount Amount minting
   */
  function mint(address to, uint256 amount) external {
    require(publicMinting, '!Public');
    require(_totalMinted() + amount <= MAX_SUPPLY, '!Supply');

    // Get current contract balance of whitelist token
    uint256 contractBalance = whitelistToken.balanceOf(address(this));

    // Transfer whitelist token from sender to this contract
    whitelistToken.transferFrom(msg.sender, address(this), amount);

    // Ensure the balance successfully transferred to this contract
    require(
      whitelistToken.balanceOf(address(this)) == contractBalance + amount,
      '!Whitelist'
    );

    // Mint DEDPRZ
    _mint(to, amount);

    emit Minted(to, amount);
  }

  /**
   * @notice Transfer whitelist token to owner
   */
  function withdraw() external {
    // Send whitelist token to owner
    whitelistToken.transferFrom(
      address(this),
      owner,
      whitelistToken.balanceOf(address(this))
    );

    emit Withdraw(owner, address(this).balance);
  }

  /// @notice Burn token
  /// @param tokenId Token ID to burn
  function burn(uint256 tokenId) external {
    _burn(msg.sender, tokenId);
  }

  /// @notice Burn tokens
  /// @param tokenIds Token IDs to burn
  function burnBatch(uint256[] memory tokenIds) external {
    _burnBatch(msg.sender, tokenIds);
  }

  /// @notice Get total minted
  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  /// @notice Set owner address
  function transferOwnership(address _newOwner) external onlyOwner {
    owner = _newOwner;

    emit OwnershipTransferred(owner, _newOwner);
  }

  /// @notice Set minting state
  function setMintable(bool _publicMinting) external onlyOwner {
    publicMinting = _publicMinting;
  }

  /// @notice Set URI of tokens for later reveal to protect randomness
  function setURI(string memory _newuri) external onlyOwner {
    _setURI(_newuri);

    emit SetURI(_newuri);
  }

  /// @notice Set royalty for marketplaces complying with ERC2981 standard
  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  // *** OVERRIDES ***

  /// @dev Override supportsInterface to use ERC1155 and ERC2981
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC1155DeltaUpgradeable, ERC2981Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /// @dev Override to use filter operator
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  /// @dev Override transfer to use filter operator
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  /// @dev Override batch transfer to use filter operator
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
}
