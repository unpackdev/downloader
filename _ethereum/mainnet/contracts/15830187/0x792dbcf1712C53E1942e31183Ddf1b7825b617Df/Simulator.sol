// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

/**

  /$$$$$$  /$$                         /$$             /$$                        
 /$$__  $$|__/                        | $$            | $$                        
| $$  \__/ /$$ /$$$$$$/$$$$  /$$   /$$| $$  /$$$$$$  /$$$$$$    /$$$$$$   /$$$$$$ 
|  $$$$$$ | $$| $$_  $$_  $$| $$  | $$| $$ |____  $$|_  $$_/   /$$__  $$ /$$__  $$
 \____  $$| $$| $$ \ $$ \ $$| $$  | $$| $$  /$$$$$$$  | $$    | $$  \ $$| $$  \__/
 /$$  \ $$| $$| $$ | $$ | $$| $$  | $$| $$ /$$__  $$  | $$ /$$| $$  | $$| $$      
|  $$$$$$/| $$| $$ | $$ | $$|  $$$$$$/| $$|  $$$$$$$  |  $$$$/|  $$$$$$/| $$      
 \______/ |__/|__/ |__/ |__/ \______/ |__/ \_______/   \___/   \______/ |__/      
                                                                                                                                                                    

*/

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IUniswapV2Router01.sol";

// Log the transfer fee
error AmntReceived_AmntExpected_Transfer(uint256 amountReceived, uint256 amountExpected);
error AmntReceived_AmntExpected_TransferSwap(uint256 amountReceived, uint256 amountExpected);
error AmntReceived_AmntExpected_Buy(
    uint256 amountReceivedBuy,
    uint256 amountExpectedBuy,
    uint256 amountReceivedTransfer,
    uint256 amountExpectedTransfer
);
error AmntReceived_AmntExpected_Sell(
    uint256 amountReceivedBuy,
    uint256 amountExpectedBuy,
    uint256 amountReceivedSell,
    uint256 amountExpectedSell,
    uint256 amountReceivedTransfer,
    uint256 amountExpectedTransfer
);

/**
    @title Simulator
    @author Vladislav Yaroshuk
    @notice Log commision percent of the token
 */
contract Simulator is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    constructor() {
        initialize();
    }

    function initialize() private initializer {
        __Ownable_init_unchained();
    }

    /**
     * @dev Log the difference of token received after _transfer to contract
     *      can be used only in case the msg.sender has allowance to this address
     * @param _tokenIn Token sent
     * @param _amount Amount sent
     */
    function simulateTransfer(address _tokenIn, uint256 _amount) external payable {
        IERC20Upgradeable(_tokenIn).transferFrom(msg.sender, address(this), _amount);

        (uint256 amountReceived, uint256 amountExpected) = checkTransferToEOA(_tokenIn, _amount);

        revert AmntReceived_AmntExpected_Transfer(
            amountReceived,
            amountExpected
        );
    }

    /**
     * @dev Log the difference of token received after _transfer to msg.sender
     * @notice Use this function to avoid using allowance by using native token
     * @param _dex Dex address performing swap logic
     * @param _checkToken token received after swap and checked for fees
     * @param _data Data with swap logic, receiver must be contract address
     */
    function simulateTransferWithSwap(
        address _dex,
        address _checkToken,
        bytes calldata _data
    ) external payable {
        AddressUpgradeable.functionCallWithValue(_dex, _data, msg.value);

        uint256 tokenAmntAfterSwap = IERC20Upgradeable(_checkToken).balanceOf(address(this));

        (uint256 amountReceived, uint256 amountExpected) = checkTransferToEOA(_checkToken, tokenAmntAfterSwap);

        revert AmntReceived_AmntExpected_TransferSwap(amountReceived, amountExpected);
    }

    /**
     * @dev Log the difference of token received after _transfer to msg.sender.
     *      Shows fees for buy and transfer. Works only with UniswapV2
     * @notice Use this function to avoid using allowance by using native token
     * @param _dex Dex address performing swap logic
     * @param _amountIn Amount of input token for calculation of amount out
     * @param _path The same path of swaps as in _data
     * @param _checkToken Token received after swap and checked for fees
     * @param _data Data with swap logic, receiver must be contract address
     */
    function simulateBuyWithSwap(
        address _dex,
        uint256 _amountIn,
        address[] calldata _path,
        address _checkToken,
        bytes calldata _data
    ) external payable {
        uint256[] memory amountsOut = IUniswapV2Router01(_dex).getAmountsOut(_amountIn, _path);

        uint256 tokenAmntBeforeBuy = IERC20Upgradeable(_checkToken).balanceOf(address(this));

        AddressUpgradeable.functionCallWithValue(_dex, _data, msg.value);

        uint256 tokenAmntAfterBuy = IERC20Upgradeable(_checkToken).balanceOf(address(this));

        (uint256 amountReceived, uint256 amountExpected) = checkTransferToEOA(_checkToken, tokenAmntAfterBuy);

        revert AmntReceived_AmntExpected_Buy(
            tokenAmntAfterBuy - tokenAmntBeforeBuy,
            amountsOut[amountsOut.length - 1],
            amountReceived,
            amountExpected
        );
    }

    /**
     * @dev Log the difference of token received after _transfer to msg.sender.
     *      Shows fees for buy, sell and transfer. Works only with UniswapV2
     * @notice Use this function to avoid using allowance by using native token
     * @param _dex Dex address performing swap logic
     * @param _amountIn Amount of input token for calculation of amount out
     * @param _path The same path of swaps as in _data
     * @param _checkToken Token received after swap and checked for fees
     * @param _dataBuy Data with swap logic, receiver must be contract address
     * @param _dataSell Data with swap logic, receiver must be contract address
     */
    function simulateSellWithSwaps(
        address _dex,
        uint256 _amountIn,
        address[] calldata _path,
        address _checkToken,
        bytes calldata _dataBuy,
        bytes calldata _dataSell
    ) external payable {
        uint256[] memory amountsOutBuy = IUniswapV2Router01(_dex).getAmountsOut(_amountIn, _path);
        uint256 tokenAmntBeforeBuy = IERC20Upgradeable(_checkToken).balanceOf(address(this));
        AddressUpgradeable.functionCallWithValue(_dex, _dataBuy, msg.value);
        uint256 tokenAmntAfterBuy = IERC20Upgradeable(_checkToken).balanceOf(address(this));

        uint256[] memory amountsOutSell = IUniswapV2Router01(_dex).getAmountsOut(_amountIn, _path);
        uint256 tokenAmntBeforeSell = IERC20Upgradeable(_checkToken).balanceOf(address(this));
        AddressUpgradeable.functionCallWithValue(_dex, _dataSell, msg.value);
        uint256 tokenAmntAfterSell = IERC20Upgradeable(_checkToken).balanceOf(address(this));

        (uint256 amountReceived, uint256 amountExpected) = checkTransferToEOA(_checkToken, tokenAmntAfterBuy);

        revert AmntReceived_AmntExpected_Sell(
            tokenAmntAfterBuy - tokenAmntBeforeBuy,
            amountsOutBuy[amountsOutBuy.length - 1],
            tokenAmntAfterSell - tokenAmntBeforeSell,
            amountsOutSell[amountsOutSell.length - 1],
            amountReceived,
            amountExpected
        );
    }

    function checkTransferToEOA(address _token, uint256 _amount)
        internal
        returns (uint256 amntReceived, uint256 amntExpected)
    {
        uint256 balanceBefore = IERC20Upgradeable(_token).balanceOf(msg.sender);
        IERC20Upgradeable(_token).transfer(msg.sender, _amount);
        // actual amount received = amount after swap - amount before swap
        return (IERC20Upgradeable(_token).balanceOf(msg.sender) - balanceBefore, _amount);
    }

    // in case someone send donation
    function sweepTokens(address _token, uint256 _amount) external onlyOwner {
        if (_token == address(0)) {
            AddressUpgradeable.sendValue(payable(msg.sender), _amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);
        }
    }
}
