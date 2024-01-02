// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IUSATokenV1.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract USATokenOwner is Ownable {
    address public constant USA_TOKEN_ADDRESS = 0x4FFe9CC172527DF1E40D0b2EfE1e9F05884A13dA;
    IUSATokenV1 public constant USA_TOKEN = IUSATokenV1(USA_TOKEN_ADDRESS);
    uint256 public constant MAX_SELL_TAX_FEE = 5 * 1e6; // max 5% sell fee
    uint256 public constant MAX_BUY_TAX_FEE = 5 * 1e6; // max 5% buy fee

    bool public lockSwapHelper = false;

    /**
     * This contract is the permanent owner of the USA token contract. This contract does not have the ability to change the ownership of the USA token contract (it lacks the ability to call the transferOwnership function in the USA Token contract).
     *
     * The ownership of this contract can be transferred to another address, but the ownership of the USA token contract cannot be transferred to another address.
     *
     * The purpose of this USA Owner contract is to contractlly enforce the following:
     * - That the mint() function can never be called again since this contract is the owner and it lacks the ability to call the mint() function
     *  - That the burn() function can never be called again since this contract is the owner and it lacks the ability to call the burn() function
     * - That the buy and sell taxes can never be higher than 5% (5 * 1e6)
     *  - The blacklistAddress function can never be called again since this contract is the owner and it lacks the ability to call the blacklistAddress function
     *  - This contract does have the ability to change the swapHelper, but this ability can be locked permanently by calling the lockSwapHelperForever function
     */

    constructor(address _ownerAddress) Ownable(_ownerAddress) {}

    /**
     * function that calls manual swap in the USA token contract, which sells collected taxes into the configured lp pool
     */
    function manualSwap() external onlyOwner {
        USA_TOKEN.manualSwap();
    }

    /**
     * @dev function that withdraws tokens from the contract
     * @param _token the token address to withdraw
     * @param _to the address to send the tokens to
     * @param _amount the amount of tokens to withdraw
     */
    function withdrawTokens(address _token, address _to, uint256 _amount) external onlyOwner {
        USA_TOKEN.withdrawTokens(_token, _to, _amount);
    }

    /**
     * @dev function that withdraws all available USA and sends it to the owner
     */
    function withdrawAllUsaToOwner() external onlyOwner {
        uint256 _amount = IERC20(USA_TOKEN_ADDRESS).balanceOf(USA_TOKEN_ADDRESS);
        USA_TOKEN.withdrawTokens(USA_TOKEN_ADDRESS, owner(), _amount);
    }

    /**
     * @dev Add registered swap contract, for enforcement of sell and buy taxes
     * @param _swapContract the swap contract address of the dex
     * @param _setting bool setting, true is to add, false is to remove
     */
    function addRegisteredSwapContract(address _swapContract, bool _setting) external onlyOwner {
        USA_TOKEN.addRegisteredSwapContract(_swapContract, _setting);
    }

    /**
     * @dev Set minimum swap amount for selling on a usa sell action
     * @param _minSwapAmount min swap amount for auto selling of taxes
     */
    function setMinSwapAmount(uint256 _minSwapAmount) external onlyOwner {
        USA_TOKEN.setMinSwapAmount(_minSwapAmount);
    }

    /**
     * @dev Set excluded from fee address
     * @param _address address to set / exclude from being charged taxes
     * @param _excluded true to exclude, false to (re)include
     */
    function setExcludedFromFee(address _address, bool _excluded) external onlyOwner {
        USA_TOKEN.setExcludedFromFee(_address, _excluded);
    }

    /**
     * @dev Set tax fee charged on USA buys
     * @param _taxFeeOnBuy tax fee on buy
     *  @notice tax can be max 5% (5 * 1e6)
     */
    function setTaxFeeOnBuy(uint256 _taxFeeOnBuy) external onlyOwner {
        require(_taxFeeOnBuy <= MAX_BUY_TAX_FEE, "USATokenOwner: taxFeeOnBuy is too high");
        USA_TOKEN.setTaxFeeOnBuy(_taxFeeOnBuy);
    }

    /**
     * @dev Set tax fee charged on USA sells
     * @param _taxFeeOnSell tax fee on sell
     *  @notice tax can be max 5% (5 * 1e6)
     */
    function setTaxFeeOnSell(uint256 _taxFeeOnSell) external onlyOwner {
        require(_taxFeeOnSell <= MAX_SELL_TAX_FEE, "USATokenOwner: taxFeeOnSell is too high");
        USA_TOKEN.setTaxFeeOnSell(_taxFeeOnSell);
    }

    /**
     * @dev Set swap to eth on sell action of usa token
     * @param _swapToEthOnSell bool to swap to eth on sell, false to disable 'automatic' tax swapping
     */
    function setSwapToEthOnSell(bool _swapToEthOnSell) external onlyOwner {
        USA_TOKEN.setSwapToEthOnSell(_swapToEthOnSell);
    }

    /**
     * @dev Set dao tax receiver address in the USA contract (where the dao tax in weth is sent to)
     * @param _daoTaxReceiver address to set as dao tax receiver
     */
    function setDaoTaxReceiver(address _daoTaxReceiver) external onlyOwner {
        require(_daoTaxReceiver != address(0), "USATokenOwner: daoTaxReceiver is zero address");
        USA_TOKEN.setDaoTaxReceiver(_daoTaxReceiver);
    }

    /**
     * @dev change swap helper address, the swap helper is used to swap tokens to weth
     * @param _swapHelper address of the swap helper
     * @notice this function can only be called if the swap helper is not locked permanently
     *  @notice the reason there is a configurable swap helper to begin with is that we want to be able to change the swap helper in case of a new version of uniswap (like v4). This way we can upgrade the swap helper contract and change the address in the USA contract. to make sure the swap helper address is not changed maliciously, we can lock the swap helper address permanently if we want to.
     */
    function changeSwapHelper(address _swapHelper) external onlyOwner {
        require(!lockSwapHelper, "USATokenOwner: swapHelper is locked");
        USA_TOKEN.changeSwapHelper(_swapHelper);
    }

    /**
     * @dev enable or disable fees on the USA token
     * @param _value true to enable fees, false to disable fees
     */
    function enableOrDisableFees(bool _value) external onlyOwner {
        USA_TOKEN.enableOrDisableFees(_value);
    }

    /**
     * @notice function that allows for withdrawal of tokens that are accidentally sent to this ownership contract
     * @param _token the token address to withdraw
     * @param _to the address to send the tokens to
     * @param _amount the amount of tokens to withdraw
     */
    function removeTokensFromContract(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    /**
     * @dev function that locks the swap helper address permanently so that it cannot be changed anymore
     * @notice this function can only be called once
     */
    function lockSwapHelperForever() external onlyOwner {
        lockSwapHelper = true;
    }
}
