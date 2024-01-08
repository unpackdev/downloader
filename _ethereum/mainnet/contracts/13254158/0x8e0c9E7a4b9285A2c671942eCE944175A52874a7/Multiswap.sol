// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IUniswapV2Router02.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract Multiswap is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Ownership change pending
    address private pendingOwner;

    // WETH Address
    address private immutable WETH;

    // Uniswap Router for swaps
    IUniswapV2Router02 private immutable uniswapRouter;

    // Referral data
    mapping (address => bool) private referrers;
    mapping (address => uint256) private referralFees;

    // Data struct
    struct ContractData {
        uint160 owner;
        uint16 swapFeeBase;
        uint16 swapFeeToken;
        uint16 referralFee;
        uint16 maxFee;
    }
    
    ContractData private data;

    // Modifier for only owner functions
    modifier onlyOwner {
        require(msg.sender == address(data.owner), "Not allowed");
        _;
    }

    /**
     * @dev Constructor sets values for Uniswap, WETH, and fee data
     * 
     * These values are the immutable state values for Uniswap and WETH.
     *
    */
    constructor(address _router, address _weth) {
        uniswapRouter = IUniswapV2Router02(_router);
        WETH = _weth;
        
        data.owner = uint160(msg.sender);
        // add extra two digits to percent for accuracy (30 = 0.3)
        data.swapFeeBase = uint16(30); // 0.3%
        data.swapFeeToken = uint16(20); // 0.2% per token
        data.referralFee = uint16(4500); // 45% for referrals
        data.maxFee = uint16(150); // 1.5% max fee

        // Add standard referrers
        referrers[address(this)] = true;
        referrers[address(0x1190074795DAD0E61b61270De48e108427f8f817)] = true;
    }
    
    /**
     * @dev Receive ETH
    */
    receive() external payable {}
    fallback() external payable {}

    /**
     * @dev Checks and returns expected output fom ETH swap.
    */
    function checkOutputsETH(
        address[] memory _tokens,
        uint256[] memory _percent,
        uint256[] memory _slippage,
        uint256 _total
    ) external view returns (address[] memory, uint256[] memory, uint256)
    {
        require(_tokens.length == _percent.length && _percent.length == _slippage.length, 'Multiswap: mismatch input data');

        uint256 _totalPercent;
        (uint256 valueToSend, uint256 feeAmount) = applyFeeETH(_total, _tokens.length);

        uint256[] memory _outputAmount = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            _totalPercent += _percent[i];
            (_outputAmount[i],) = calcOutputEth(
                _tokens[i],
                valueToSend.mul(_percent[i]).div(100),
                _slippage[i]
            );
        }

        require(_totalPercent == 100, 'Multiswap: portfolio not 100%');

        return (_tokens, _outputAmount, feeAmount);
    }

    /**
     * @dev Checks and returns expected output from token swap.
    */
    function checkOutputsToken(
        address[] memory _tokens,
        uint256[] memory _percent,
        uint256[] memory _slippage,
        address _base,
        uint256 _total
        ) external view returns (address[] memory, uint256[] memory)
    {
        require(_tokens.length == _percent.length && _percent.length == _slippage.length, 'Multiswap: mismatch input data');
        
        uint256 _totalPercent;
        uint256[] memory _outputAmount = new uint256[](_tokens.length);
        address[] memory path = new address[](3);
        path[0] = _base;
        path[1] = WETH;
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            _totalPercent += _percent[i];
            path[2] = _tokens[i];
            uint256[] memory expected = uniswapRouter.getAmountsOut(_total.mul(_percent[i]).div(100), path);
            uint256 adjusted = expected[2].sub(expected[2].mul(_slippage[i]).div(1000));
            _outputAmount[i] = adjusted;
        }
        
        require(_totalPercent == 100, 'Multiswap: portolio not 100%');
        
        return (_tokens, _outputAmount);
    }
    
    /**
     * @dev Checks and returns ETH value of token amount.
    */
    function checkTokenValueETH(address _token, uint256 _amount, uint256 _slippage)
        public
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;
        uint256[] memory expected = uniswapRouter.getAmountsOut(_amount, path);
        uint256 adjusted = expected[1].sub(expected[1].mul(_slippage).div(1000));
        return adjusted;
    }
    
    /**
     * @dev Checks and returns ETH value of portfolio.
    */
    function checkAllValue(address[] memory _tokens, uint256[] memory _amounts, uint256[] memory _slippage)
        external
        view
        returns (uint256)
    {
        uint256 totalValue;
        
        for (uint i = 0; i < _tokens.length; i++) {
            totalValue += checkTokenValueETH(_tokens[i], _amounts[i], _slippage[i]);
        }
        
        return totalValue;
    }
    
    /**
     * @dev Internal function to calculate the output from one ETH swap.
    */
    function calcOutputEth(address _token, uint256 _value, uint256 _slippage)
        internal
        view
        returns (uint256, address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;
        
        uint256[] memory expected = uniswapRouter.getAmountsOut(_value, path);
        uint256 adjusted = expected[1].sub(expected[1].mul(_slippage).div(1000));
        
        return (adjusted, path);
    }

    /**
     * @dev Internal function to calculate the output from one token swap.
    */
    function calcOutputToken(address[] memory _path, uint256 _value)
        internal
        view
        returns (uint256[] memory expected)
    {
        
        expected = uniswapRouter.getAmountsOut(_value, _path);
        return expected;
    }

    /**
     * @dev Execute ETH swap for each token in portfolio.
    */
    function makeETHSwap(address[] memory _tokens, uint256[] memory _percent, uint256[] memory _expected, address _referrer)
        external
        payable
        nonReentrant
    {
        require(address(0) != _referrer, 'Multiswap: referrer cannot be zero addresss');
        require(_tokens.length == _percent.length && _percent.length == _expected.length, 'Multiswap: Input data mismatch');
        (uint256 valueToSend, uint256 feeAmount) = applyFeeETH(msg.value, _tokens.length);
        uint256 totalPercent;
        address[] memory path = new address[](2);
        path[0] = WETH;

        for (uint256 i = 0; i < _tokens.length; i++) {
            totalPercent += _percent[i];
            require(totalPercent <= 100, 'Multiswap: Exceeded 100%');

            path[1] = _tokens[i];

            uint256 swapVal = valueToSend.mul(_percent[i]).div(100);
            uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapVal}(
                _expected[i],
                path,
                msg.sender,
                block.timestamp + 1200
            );
        }

        require(totalPercent == 100, 'Multiswap: Percent not 100');
        
        if (_referrer != address(this)) {
            uint256 referralFee = takeReferralFee(feeAmount, _referrer);
            (bool sent, ) = _referrer.call{value: referralFee}("");
            require(sent, 'Multiswap: Failed to send referral fee');
        }
        
    }

    /**
     * @dev Execute token swap for each token in portfolio.
    */
    function makeTokenSwap(
        address[] memory _tokens,
        uint256[] memory _percent,
        uint256[] memory _expected,
        address _referrer,
        address _base,
        uint256 _total)
        external
        nonReentrant
    {
        require(address(0) != _referrer, 'Multiswap: referrer cannot be zero addresss');
        require(_tokens.length == _percent.length && _percent.length == _expected.length, 'Multiswap: Input data mismatch');

        uint256 totalToSend = receiveToken(_total, _base, true);

        uint256 totalPercent = 0;
        address[] memory path = new address[](3);

        path[0] = _base;
        path[1] = WETH;
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            totalPercent += _percent[i];

            require(totalPercent <= 100, 'Multiswap: Exceeded 100');
            
            path[2] = _tokens[i];            
            uint256 swapVal = totalToSend.mul(_percent[i]).div(100);

            uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapVal,
                _expected[i],
                path,
                msg.sender,
                block.timestamp + 1200
            );
        }

        require(totalPercent == 100, 'Multiswap: Percent not 100');
    }

    /**
     * @dev Receive token and handle any logic required for reflection tokens
    */

    function receiveToken(uint256 _amount, address _token, bool _toSend) internal returns (uint256 amountReceived) {
        IERC20 token = IERC20(_token);
        uint256 preBalanceToken = token.balanceOf(address(this));

        token.safeTransferFrom(msg.sender, address(this), _amount);

        if (_amount > token.balanceOf(address(this)).sub(preBalanceToken)) {
            amountReceived = token.balanceOf(address(this)).sub(preBalanceToken);
        } else {
            amountReceived = _amount;
        }

        if (_toSend) require(token.approve(address(uniswapRouter), amountReceived), 'Multiswap: Uniswap approval failed');

        return amountReceived;
    }
    
    /**
     * @dev Swap tokens for ETH
    */
    function makeTokenSwapForETH(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _expected,
        address _referrer
    ) external nonReentrant
    {
        require(address(0) != _referrer, 'Multiswap: referrer cannot be zero addresss');
        require(_tokens.length == _amounts.length && _expected.length == _expected.length, 'Multiswap: Input data mismatch');
        address[] memory path = new address[](2);
        path[1] = WETH;
        uint256 preBalance = address(this).balance;
        
        for (uint i = 0; i < _tokens.length; i++) {
            path[0] = _tokens[i];
            uint256 totalToSend = receiveToken(_amounts[i], _tokens[i], true);
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(totalToSend, _expected[i], path, address(this), block.timestamp + 1200);
        }

        (uint256 valueToSend, uint256 feeAmount) = applyFeeETH(address(this).balance.sub(preBalance), _tokens.length);

        if (_referrer != address(this)) {
            uint256 referralFee = takeReferralFee(feeAmount, _referrer);
            (bool sent, ) = _referrer.call{value: referralFee}("");
            require(sent, 'Multiswap: Failed to send referral fee');
        }
        
       (bool delivered, ) = msg.sender.call{value: valueToSend}("");
       require(delivered, 'Multiswap: Failed to send swap output');
    }

    /**
     * @dev Apply fee to total value amount for ETH swap.
    */
    function applyFeeETH(uint256 _amount, uint256 _numberOfTokens)
        private
        view
        returns (uint256 valueToSend, uint256 feeAmount)
    {
        uint256 feePercent = _numberOfTokens.mul(data.swapFeeToken);
        feePercent -= data.swapFeeToken;
        feePercent += data.swapFeeBase;

        if (feePercent > data.maxFee) {
            feePercent = data.maxFee;
        }

        feeAmount = _amount.mul(feePercent).div(10000);
        valueToSend = _amount.sub(feeAmount);

        return (valueToSend, feeAmount);
    }

    /**
     * @dev Take referral fee and distribute
    */
    function takeReferralFee(uint256 _fee, address _referrer) internal returns (uint256) {
        require(referrers[_referrer], 'Multiswap: Not signed up as referrer');
        uint256 referralFee = _fee.mul(data.referralFee).div(10000);
        referralFees[_referrer] = referralFees[_referrer].add(referralFee);
        
        return referralFee;
    }

    /**
     * @dev Owner only function to update contract fees.
    */
    function updateFee(
        uint16 _newFeeBase,
        uint16 _newFeeToken,
        uint16 _newFeeReferral,
        uint16 _newMaxFee
    ) external onlyOwner returns (bool) {
        data.swapFeeBase = _newFeeBase;
        data.swapFeeToken = _newFeeToken;
        data.referralFee = _newFeeReferral;
        data.maxFee = _newMaxFee;
        
        return true;
    }

    /**
     * @dev Returns current app fees.
    */
    function getCurrentFee()
        external
        view
        returns (
            uint16,
            uint16,
            uint16,
            uint16
        )
    {
        return (data.swapFeeBase, data.swapFeeToken, data.referralFee, data.maxFee);
    }

    /**
     * @dev Owner only function to change contract owner.
    */
    function transferOwnership(address _newOwner) external onlyOwner returns (bool) {
        require(address(0) != _newOwner, "Multiswap: newOwner set to the zero address");
        pendingOwner = _newOwner;
        return true;
    }

    /**
     * @dev Function to claim ownership as pending owner.
    */
    function claimOwnership() external {
        require(msg.sender == pendingOwner, 'Multiswap: not pending owner');
        data.owner = uint160(pendingOwner);
        pendingOwner = address(0);
    }

    /**
     * @dev Owner only function to renounce ownership.
    */
    function renounceOwnership() external onlyOwner {
        pendingOwner = address(0);
        data.owner = uint160(0);
    }

    /**
     * @dev Owner only function to change contract owner.
    */
    function addReferrer(address _referrer) external onlyOwner returns (bool) {
        referrers[_referrer] = true;
        return true;
    }

    /**
     * @dev Owner only function to change contract owner.
    */
    function removeReferrer(address _referrer) external onlyOwner returns (bool) {
        referrers[_referrer] = false;
        return true;
    }

    /**
     * @dev Return owner address
    */
    function getOwner() external view returns (address) {
        return address(data.owner);
    }
    
    /**
     * @dev Function to see referral balances
    */
    function getReferralFees(address _referrer) external view returns (uint256) {
        return referralFees[_referrer];
    }

    /**
     * @dev Owner only function to retreive ETH fees
    */
    function retrieveEthFees() external onlyOwner {
        (bool sent, ) = address(data.owner).call{value: address(this).balance}("");
        require(sent, 'Multiswap: Transfer failed');
    }

}