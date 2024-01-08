//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./uniswap.sol";
import "./FlashLoanReceiverBaseV2.sol";

contract Lego is Ownable, IUniswapV2Callee, FlashLoanReceiverBaseV2 {
    event Zinnion(string message, uint256 val);

    constructor(address _addressProvider) FlashLoanReceiverBaseV2(_addressProvider) {}

	function withdraw() external onlyOwner {
		uint256 amount = address(this).balance;
		payable(owner()).transfer(amount);
	}

	function withdrawToken(address _token) external onlyOwner {
		uint256 amount = IERC20(_token).balanceOf(address(this));
		IERC20(_token).transfer(owner(), amount);
	}

    function getTokenBalance(address token) public view returns (uint256){
        return IERC20(token).balanceOf(address(this));
    }

	function execBatch(bytes memory _data, uint amount) public {
		address[][] memory _legos = abi.decode(_data, (address[][]));
		_executeBatch(_legos, amount);
	}

	function execBatchWithLoanUniSushiSwap(bytes memory _legos, address pairAddr, uint amount0, uint amount1) public {
	   IUniswapV2Pair(pairAddr).swap(amount0, amount1, address(this), _legos);
	}	

    function execBatchWithLoanAave(address[] memory assets, uint256[] memory amounts, bytes memory _legos) public {
        address receiverAddress = address(this);
        address onBehalfOf = address(this);
        uint16 referralCode = 0;
        uint256[] memory modes = new uint256[](assets.length);
        // 0 = no debt (flash), 1 = stable, 2 = variable
        for (uint256 i = 0; i < assets.length; i++) {
            modes[i] = 0;
        }
        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            _legos,
            referralCode
        );
    }

	function testSimulateBatch(bytes memory _legos, uint _amount) public view returns(int) {
		uint io = _amount;
		uint sub;
		address[][] memory data = abi.decode(_legos, (address[][]));
		for (uint i = 0; i < data.length; i++) {	
			io = _simulateBlockOutcome(data[i], io);
		}
		return int(io) - int(sub);
	}

	function _executeBlock(address[] memory _lego, uint _in) internal returns(uint out) {
		address[] memory path = new address[](2);
		path[0] = _lego[1];
		path[1] = _lego[2];
		IERC20(path[0]).approve(_lego[0], _in);
		uint[] memory outputs = UniSushiSwap(_lego[0]).swapExactTokensForTokens(_in, 0, path, address(this), block.timestamp + 100);
		out = outputs[outputs.length - 1]; 
	}

	function _simulateBlockOutcome(address[] memory _lego, uint _in) internal view returns (uint out){
		address[] memory path = new address[](2);
		path[0] = _lego[1];
		path[1] = _lego[2];
		uint[] memory outputs = UniSushiSwap(_lego[0]).getAmountsOut(_in, path);
		out = outputs[outputs.length - 1];
	}

	function _executeBatch(address[][] memory data , uint amount) internal {
		uint io = amount;
		for (uint i = 0; i < data.length; i++) {
			io = _executeBlock(data[i], io);
		}
	}

	// Uniswap / SushiSwap Flash Loan
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external override {
        require(_sender == address(this), "only this contract may initiate");
		
        uint amountToken = _amount0 == 0 ? _amount1 : _amount0;

        // compute amount of tokens that need to be paid back
    	uint256 fee = ((amountToken * 3) / 997) + 1;		
    	uint256 amountToRepay = amountToken + fee;
		
		address[][] memory _legos = abi.decode(_data, (address[][]));

		_executeBatch(_legos, amountToken);

        // Pay back the flash-borrow to the pool
        IERC20(_legos[0][1]).transfer(msg.sender, amountToRepay);	
	}	

	// Aave Flash Swap
    function executeOperation(address[] calldata assets, uint256[] calldata amounts, uint256[] calldata premiums, address, bytes calldata _data) external override returns (bool) {
		uint256 tradeVolume = amounts[0];

		address[][] memory _legos = abi.decode(_data, (address[][]));
		_executeBatch(_legos, tradeVolume);

        tradeVolume =  amounts[0] + premiums[0];
        IERC20(assets[0]).approve(address(LENDING_POOL), tradeVolume);
        return true;
	}
	//	receive() payable external {}
}
