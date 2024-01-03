// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

// import "./console.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract NFT {
  using SafeMath for uint256;
  using Address for address;

  event Buy(address indexed from, address indexed to, uint256 id, uint256 price);
  event Mint(address indexed account, uint256 id);

  uint88 public gasCompensation; // adjusted so that early buyers may profit while price increase is below gas costs
  uint96 public initialTokenPrice;
  uint256 public nextTokenId = 0;
  uint8 public priceIncreaseTenths;

  struct TokenInfo {
    address minter;
    uint8 previousPriceIncrease;
    uint88 previousGasCompensation;
    address owner;
    uint96 previousPrice;
  }

  mapping(uint256 => TokenInfo) public tokenInfo;

  function _beforeTokenTransfer() internal virtual {}

  /**
   * @dev checks if transfer is allowed and emits Buy
   */
  function _bought(
    address from,
    address to,
    uint256 id,
    uint256 price
  ) internal {
    require(to != address(0), 'Transfer to the zero address');

    _beforeTokenTransfer();
    emit Buy(from, to, id, price);
  }

  /**
   * @dev Creates 1 token and assigns minter, price increase, gas compensation and price
   *
   * Emits a {Mint} event.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account) internal virtual {
    require(account != address(0), 'NFT: mint to the zero address');
    _beforeTokenTransfer();

    tokenInfo[nextTokenId] = TokenInfo(account, priceIncreaseTenths, gasCompensation, account, initialTokenPrice);

    emit Mint(msg.sender, nextTokenId);
    nextTokenId++;
  }

  function _toUint96(uint256 value) internal pure returns (uint96) {
    require(value < 2**96, "_toUint96: value doesn't fit in 96 bits");
    return uint96(value);
  }
}
