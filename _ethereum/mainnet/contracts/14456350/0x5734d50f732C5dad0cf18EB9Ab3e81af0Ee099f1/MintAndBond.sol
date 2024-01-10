// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IBondDepository.sol";
import "./IERC721.sol";
import "./INFTXVault.sol";
import "./INFTXVaultFactory.sol";
import "./IMintAndBond.sol";

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./FloorAccessControlled.sol";

contract MintAndBondZap is IMintAndBond, ReentrancyGuard, FloorAccessControlled {

  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using SafeMath for uint64;

  struct Note {
    uint256 amount;
    uint256 matured;
    address vault;
    uint48 claimed;
  }

  INFTXVaultFactory public immutable nftxFactory;
  IBondDepository public immutable bondDepository;
  uint48 public timelock; // seconds
  mapping(address => mapping(address => Note[])) public notes; // user deposit data

  event CreateNote(address user, address vault, uint256 index, uint256 amount, uint48 expiry);
  event ClaimNote(address user, uint256[] indexes, address vault);

  constructor (
    address _authority,
    address _bondDepository,
    address _nftxFactory,
    uint48 _timelock
  ) FloorAccessControlled(IFloorAuthority(_authority))
  {
    bondDepository = IBondDepository(_bondDepository);
    nftxFactory = INFTXVaultFactory(_nftxFactory);
    timelock = _timelock;
  }

  /** 
   * @notice             mints into nftx and bonds maximum into floordao
   * @param _vaultId     the nftx vault id
   * @param _ids[]       the nft ids
   * @param _bondId      the floor bond id
   * @param _to          the recipient of bond payout
   * @param _maxPrice    the max bond price to account for slippage
   * @return remaining_  remaining vtokens to send back to user
   */
  function mintAndBond721(
    uint256 _vaultId, 
    uint256[] calldata _ids, 
    uint256 _bondId,
    address _to,
    uint256 _maxPrice
  ) external override nonReentrant returns (uint256 remaining_) {
    require(_to != address(0) && _to != address(this));
    require(_ids.length > 0);

    (,,,,uint64 maxPayout,,) = bondDepository.markets(_bondId);
    uint256 bondPrice = bondDepository.marketPrice(_bondId);
    // Max bond reduced by 5% to account for possible tx-failing maxBond reduction in next block
    uint256 maxBond = maxPayout.mul(bondPrice).div(100).mul(95); // 18 decimal
    uint256 amountToBond = (maxBond > _ids.length.mul(1e18))
      ? _ids.length.mul(1e18)
      : maxBond;
    
    // Get our vault by ID
    address vault = nftxFactory.vault(_vaultId);
    IERC20 vaultToken = IERC20(vault);

    // Store initial balance
    uint256 existingBalance = vaultToken.balanceOf(address(this));

    // Convert ERC721 to ERC20
    // The vault is an ERC20 in itself and can be used to transfer and manage
    _mint721(vault, _ids, _to);
    
    // Bond ERC20 in FloorDAO
    if (vaultToken.allowance(address(this), address(bondDepository)) < type(uint256).max) {
      vaultToken.approve(address(bondDepository), type(uint256).max);
    }
    bondDepository.deposit(_bondId, amountToBond, _maxPrice, _to, address(0));

    // Calculate remaining from initial balance and timelock
    remaining_ = vaultToken.balanceOf(address(this)).sub(existingBalance);
    if (remaining_ > 0) {
      _addToTimelock(vault, remaining_, _to);
    }
  }

  /**
   * @notice             claim notes for user
   * @param _user        the user to claim for
   * @param _indexes     the note indexes to claim
   * @return amount_     sum of amount sent in vToken
   */
  function claim(address _user, uint256[] memory _indexes, address _vault) external override returns (uint256 amount_) {
    uint48 time = uint48(block.timestamp);

    for (uint256 i = 0; i < _indexes.length; i++) {
      (uint256 pay, bool matured) = pendingFor(_user, _indexes[i], _vault);
      require(matured, "Depository: note not matured");
      if (matured) {
        notes[_user][_vault][_indexes[i]].claimed = time; // mark as claimed
        amount_ += pay;
      }
    }

    IERC20 vaultToken = IERC20(_vault);
    vaultToken.safeTransfer(_user, amount_);

    emit ClaimNote(_user, _indexes, _vault);
  }

  /**
   * @notice             calculate amount available to claim for a single note
   * @param _user        the user that the note belongs to
   * @param _index       the index of the note in the user's array
   * @param _vault       the nftx vault
   * @return amount_     the amount due, in vToken
   * @return matured_    if the amount can be claimed
   */
  function pendingFor(address _user, uint256 _index, address _vault) public view override returns (uint256 amount_, bool matured_) {
    Note memory note = notes[_user][_vault][_index];

    amount_ = note.amount;
    matured_ = note.claimed == 0 && note.matured <= block.timestamp && note.amount != 0;
  }

  /**
   * @notice prevents remaining vtokens from being immediately claimable
   * @param _timelock amount in 18 decimal
   */
  function setTimelock(uint48 _timelock) external override onlyGovernor {
    // protect against accidental/overflowing timelocks
    require(_timelock < 31560000, "Timelock is too long");
    timelock = _timelock;
  }

  /**
   * @notice rescues any tokens mistakenly sent to this address
   * @param _token token to be rescued
   */
  function rescue(address _token) external override onlyGovernor {
      IERC20(_token).safeTransfer(
          msg.sender,
          IERC20(_token).balanceOf(address(this))
      );
  }

  function _mint721(address vault, uint256[] memory ids, address from) internal {
    // Transfer tokens to zap and mint to NFTX
    address assetAddress = INFTXVault(vault).assetAddress();
    uint256 length = ids.length;

    IERC721 erc721 = IERC721(assetAddress);
    for (uint256 i; i < length; ++i) {
      erc721.transferFrom(from, address(this), ids[i]);
    }

    // Approve tokens to be used by vault
    erc721.setApprovalForAll(vault, true);

    // Ignored for ERC721 vaults
    uint256[] memory emptyIds;
    INFTXVault(vault).mint(ids, emptyIds);
  }

  function _addToTimelock(address _vault, uint256 _remaining, address _user) internal returns (uint256 index_) {
    uint48 expiry = uint48(block.timestamp) + timelock;

    // the index of the note is the next in the user's array
    index_ = notes[_user][_vault].length;

    // the new note is pushed to the user's array
    notes[_user][_vault].push(
      Note({
        amount: _remaining,
        matured: expiry,
        vault: _vault,
        claimed: 0
      })
    );

    emit CreateNote(_user, _vault, index_, _remaining, expiry);
  }

}
