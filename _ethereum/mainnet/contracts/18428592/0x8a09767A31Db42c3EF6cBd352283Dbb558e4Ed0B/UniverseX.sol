//SPDX-License-Identifier: MIT



pragma solidity ^0.8.19;

import "./Address.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./PreSale.sol";

/**
 * @title UniverseX
 * @dev The UniverseX contract is an ERC20 token contract with fee-based transfers.
 */
contract UniverseX is ERC20, ReentrancyGuard {

    uint256 constant public TOTAL_EMIT=100_000_000 ether;
    uint256 constant public PRESALE_EMIT=3_000_000 ether;

    address[2] private _feeOwners=[
      0xc46b48737D2cA939F2a0B3fCc298912312716CD4,
      0x068B9b6e211766E3Bdd7211f6Adcaa327B1371a2
    ];

    IUniswapV2Router02 private immutable _router;
    address private immutable _weth9;
    address private immutable _pair;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => uint256) private _lastBuyBlock;
    UniverseXPreSale private immutable presale_contract;
    
    constructor() ERC20("Universe X","UNIX"){
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Mainnet
        
        _isExcludedFromFees[0xE097c249FB2B2442cCFDB6628648b2d79ee91478] = true;
        _isExcludedFromFees[0xc46b48737D2cA939F2a0B3fCc298912312716CD4] = true;
        _isExcludedFromFees[0x068B9b6e211766E3Bdd7211f6Adcaa327B1371a2] = true;
        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true;
        _router = IUniswapV2Router02(router);
        _weth9 = _router.WETH();
        _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _weth9);
        _mint(0xc46b48737D2cA939F2a0B3fCc298912312716CD4, TOTAL_EMIT - PRESALE_EMIT);
        presale_contract=new UniverseXPreSale(address(this));
        _isExcludedFromFees[address(presale_contract)] = true;
        _mint(address(presale_contract), PRESALE_EMIT);
    }

    function getPresaleContract() external view returns(address){
        return address(presale_contract);
    }

    receive() external payable{
    }

    function _transfer
    (
        address sender_,
        address recipient_,
        uint256 amount_
    ) internal virtual override {
        if (_isExcludedFromFees[sender_] || _isExcludedFromFees[recipient_]) {
            super._transfer(sender_, recipient_, amount_);
        } else {
            uint256 wethLiqudity = IERC20(_weth9).balanceOf(address(_pair));
            uint256 fee_level=0;
            if ( wethLiqudity < 20 ether) {
              fee_level=60;
            }else{
              fee_level=40;
            }

            uint fee = amount_ * fee_level / 1000 ;
            uint tokens = amount_ - fee;
            
            super._transfer(sender_, address(this), fee);

            if (sender_ != _pair) {
                _distributeFee();
            }
            super._transfer(sender_, recipient_, tokens);
        }
        if (recipient_ != _pair){
                _lastBuyBlock[recipient_]=block.number;
        }
    }

    function _distributeFee() internal nonReentrant {
        uint amount = balanceOf(address(this));
        if (amount >= 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _weth9;
            _approve(address(this), address(_router), amount);
            _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        uint eth_amount=address(this).balance;
        if ( eth_amount> 0) {
            for(uint256 i;i<2;){
                uint fee=eth_amount / 2;
                (bool success, ) = payable(_feeOwners[i]).call{value: fee}("");
                if (!success) {
                    revert("Error send ETH");
                }
            }
        }
    }
}