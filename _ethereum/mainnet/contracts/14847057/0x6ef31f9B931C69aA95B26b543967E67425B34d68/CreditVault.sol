// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20.sol";
import "./ERC721.sol";

contract CreditVault is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  address public authProvider;
  IERC20Upgradeable public loreToken;

  mapping(bytes32 => bool) public claimedTickets;
  mapping(bytes32 => bool) public Tickets;
  mapping(address => mapping (uint256 => bool)) public claimedNfts;

  event AuthProviderChanged(address indexed authProvider);
  event Claimed(address indexed user, address[] nftCollections, uint256[] tokenIds, uint256 amount);
  event Withdrawn (address indexed user, uint256 amount);
  event Deposited(address indexed user, uint256 amount);

  address public treasuryAddress;

  /// @notice Initializer function
  function initialize(
    IERC20Upgradeable _loreToken,
    address _authProvider,
    address  _treasuryAddress
  ) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();

    require(_treasuryAddress != address(0), "treasury address incorrect");
    require(_authProvider != address(0), "auth provider address incorrect");
    require(address(_loreToken) != address(0), "lore token address incorrect");

    loreToken = _loreToken;
    treasuryAddress = _treasuryAddress;
    updateAuthProvider(_authProvider);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function updateAuthProvider(address _authProvider) public onlyOwner {
    authProvider = _authProvider;
    emit AuthProviderChanged(authProvider);
  }

  /// To authorize the owner to upgrade the contract we implement 
  /// _authorizeUpgrade with the onlyOwner modifier.
  function _authorizeUpgrade(address) internal override onlyOwner {}

  /// @notice Accepts the (v,r,s) signature and the message and returns the
  /// address that signed the signature. It accounts for malleability issue
  /// with the native ecrecover.
  function getSigner(
    bytes32 message,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) private pure returns (address) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
    require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hashMessage(message), v, r, s);
    require(signer != address(0), "ECDSA:invalid signature");

    return signer;
  }

  function hashMessage(bytes32 message) private pure returns (bytes32) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    return keccak256(abi.encodePacked(prefix, message));
  }

  /// @notice Allows owner to set treasury address
  function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
    treasuryAddress = _treasuryAddress;
  }

  /// @notice Allows anyone with a valid access ticket to claim the designated LORE tokens
  /// @param tokenIds the token ids that user is claiming the LORE tokens for
  /// @param amount the total amount of LORE to be claimed
  /// @param nftCollections the nft collections each tokenId corresponds to
  function claim(
    uint256[] memory tokenIds,
    uint256 amount,
    uint256 nonce,
    address[] memory nftCollections,
    bytes32 _r,
    bytes32 _s,
    uint8 _v
  ) public nonReentrant whenNotPaused {
    
    require(nftCollections.length == tokenIds.length, "incorrect number of token and collections");

    bytes32 message = keccak256(abi.encodePacked(address(this), _msgSender(), nftCollections, tokenIds, amount, nonce));
    address signer = getSigner(message, _v, _r, _s);

    require(signer == authProvider, "invalid claim ticket");
    require(!claimedTickets[message], "ticket already used");

    claimedTickets[message] = true;
    
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(IERC721(nftCollections[i]).ownerOf(tokenIds[i]) == _msgSender(), "nft not owned by user");
      require(!claimedNfts[nftCollections[i]][tokenIds[i]], "nft already claimed");
      
      claimedNfts[nftCollections[i]][tokenIds[i]] = true;
    }
    
    loreToken.safeTransferFrom(treasuryAddress, _msgSender(), amount);
    emit Claimed(_msgSender(), nftCollections, tokenIds, amount);
  }

 /**
   * Allows users to exchange off-chain game credits for LORE tokens
   * ERC20 smart contract. This covers any mistakes from the end-user side
   * @param amount the total amount of credits to be exchanged for LORE tokens
   */
   function withdraw(
    uint256 amount,
    uint256 nonce,
    bytes32 _r,
    bytes32 _s,
    uint8 _v
  ) public nonReentrant whenNotPaused {
    bytes32 message = keccak256(abi.encodePacked(address(this), _msgSender(), amount, nonce));
    address signer = getSigner(message, _v, _r, _s);

    require(signer == authProvider, "invalid withdraw ticket");
    require(!Tickets[message], "ticket already used");

    Tickets[message] = true;
        
    loreToken.safeTransferFrom(treasuryAddress, _msgSender(), amount);
    emit Withdrawn (_msgSender(), amount);
  }

  /**
   * Allows users to deposit LORE tokens in contract which are then available as off-chain game credits
   * ERC20 smart contract. This covers any mistakes from the end-user side
   * @param amount the total amount of LORE tokens to be deposited
   */
  function deposit(uint256 amount) external {
    loreToken.safeTransferFrom(_msgSender(), treasuryAddress, amount);
    emit Deposited(_msgSender(), amount);
  }
  
  /**
   * Allows the owner of the contract to release tokens that were erronously sent to this  
   * ERC20 smart contract. This covers any mistakes from the end-user side
   * @param token the token that we want to withdraw
   * @param recipient the address that will receive the tokens
   * @param amount the amount of tokens
   */
  function tokenRescue(
    IERC20 token,
    address recipient,
    uint256 amount
  ) onlyOwner external {
    token.transfer(recipient, amount);
  }

  /**
   * Allows the owner of the contract to release any ether locked inside the contract
   * @param recipient the address that will receive the tokens
   * @param amount the amount of ether
   */
  function etherRescue(
    address recipient,
    uint256 amount
  ) onlyOwner external {   
    (bool success, ) = payable(recipient).call{value: amount}("");
    require(success, "transfer failed");
  }

  /**
   * Disable renounceOwnership
   */
  function renounceOwnership() public override view onlyOwner {
    revert("Ownership cannot be renouced");
  }
}
