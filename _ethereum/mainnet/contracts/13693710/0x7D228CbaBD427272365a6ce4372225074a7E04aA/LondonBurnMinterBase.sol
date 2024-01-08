// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC721.sol";
import "./LondonBurn.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Signature.sol";

contract LondonBurnMinterBase is Ownable, Signature {
    using Strings for uint256;

    // sushi swap router
    IUniswapV2Router02 public immutable sushiswap;

    // LONDON GIFT
    LondonBurn public immutable londonBurn;

    // $LONDON
    ERC20 public immutable payableErc20;

    // LONDON GIFT
    ERC721 public immutable externalBurnableERC721;

    // addresses
    address public treasury;

    // block numbers
    uint256 public ultraSonicForkBlockNumber = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 public revealBlockNumber = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 public burnRevealBlockNumber = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // token types
    uint256 constant NOBLE_TYPE =    0x8000000000000000000000000000000100000000000000000000000000000000;
    uint256 constant GIFT_TYPE =     0x8000000000000000000000000000000200000000000000000000000000000000;
    uint256 constant PRISTINE_TYPE = 0x8000000000000000000000000000000300000000000000000000000000000000;
    uint256 constant ETERNAL_TYPE =  0x8000000000000000000000000000000400000000000000000000000000000000;
    uint256 constant ASHEN_TYPE =    0x8000000000000000000000000000000500000000000000000000000000000000;
    uint256 constant ULTRA_SONIC_TYPE =   0x8000000000000000000000000000000600000000000000000000000000000000;

    constructor (
      address _mintableNFT, 
      address _payableErc20,
      address _externalBurnableERC721,
      address _sushiswap
    ) {
      londonBurn = LondonBurn(_mintableNFT);
      payableErc20 = ERC20(_payableErc20);
      externalBurnableERC721 = ERC721(_externalBurnableERC721);
      sushiswap = IUniswapV2Router02(_sushiswap);
    }

    function setTreasury(address _treasury) external onlyOwner {
      treasury = _treasury;
    }

    function _payLondon(address from, uint amount) internal {
      if (msg.value == 0) {
        payableErc20.transferFrom(from, treasury, amount);
      } else {
        address[] memory path = new address[](2);
        path[0] = sushiswap.WETH();
        path[1] = address(payableErc20);
        uint[] memory amounts = sushiswap.swapETHForExactTokens{value: msg.value}(amount, path, address(this), block.timestamp);
        payableErc20.transfer(treasury, amount);
        if (msg.value > amounts[0]) msg.sender.call{value: msg.value - amounts[0]}(""); // transfer any overpayment back to payer
      }
    }

    function setUltraSonicForkBlockNumber(uint256 _ultraSonicForkBlockNumber) external onlyOwner {
        ultraSonicForkBlockNumber = _ultraSonicForkBlockNumber;
    }

    function setRevealBlockNumber(uint256 _revealBlockNumber) external onlyOwner {
        revealBlockNumber = _revealBlockNumber;
    }

    function setBurnRevealBlockNumber(uint256 _burnRevealBlockNumber) external onlyOwner {
        burnRevealBlockNumber = _burnRevealBlockNumber;
    }

    fallback() external payable { 
    }
}