// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";

import "./helpers.sol";
import "./interface.sol";
import "./TokenInterface.sol";

/**
 * It helps to stake to Polido.
 */
contract PoLidoAdapter is Helpers, Initializable, OwnableUpgradeable {
    using SafeMath for uint256;

    event Deposited(address _beneficiary, uint256 _matic, uint256 _stMatic);

    uint256 public feePercentage;

    function initialize(uint256 _feePercentage) external initializer {
        feePercentage = _feePercentage;
        __Ownable_init_unchained();
    }

    function changeFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        feePercentage = _newFeePercentage;
    }

    /**
     * @notice It accepts matic token and performs staking to Polido.
     *         Received stMatic token is sent back to caller address.
     *
     * @param _amount Amount to be staked.
     */
    function deposit(uint256 _amount) external payable {
        uint256 stTokenAmount = _stake(_amount);
        TokenInterface(address(stMaticProxy)).transfer(
            msg.sender,
            stTokenAmount
        );

        emit Deposited(msg.sender, _amount, stTokenAmount);
    }

    /**
     * @notice It accepts matic token and performs staking to Polido.
     *         Received stMatic token is sent back to `_beneficiary` address.
     *
     * @param _amount Amount to be staked.
     */
    function depositFor(address _beneficiary, uint256 _amount)
        external
        payable
    {
        require(_beneficiary != address(0), "Invalid user address");
        uint256 stTokenAmount = _stake(_amount);
        TokenInterface(address(stMaticProxy)).transfer(
            _beneficiary,
            stTokenAmount
        );

        emit Deposited(_beneficiary, _amount, stTokenAmount);
    }

    /**
     * @notice It accepts any token, swaps using 1inch and performs staking
     *         to Polido. Received stMatic token is sent back to caller address.
     *
     * @param _buyAddr The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _sellAddr The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _sellAmt The amount of the token to sell.
     * @param _unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param _callData Data from 1inch API.
     */
    function swapAndStake(
        address _buyAddr,
        address _sellAddr,
        uint256 _sellAmt,
        uint256 _unitAmt,
        bytes calldata _callData
    ) external payable {
        uint256 stMaticAmount = _swapAndStake(
            _buyAddr,
            _sellAddr,
            _sellAmt,
            _unitAmt,
            _callData
        );

        TokenInterface(address(stMaticProxy)).transfer(
            msg.sender,
            stMaticAmount
        );
    }

    /**
     * @notice It performs staking to Polido and using bridge sends stMatic to
     *         Polygon network using bridge.
     *
     * @param _beneficiary Beneficiary address which will receive stMatic token.
     * @param _amount Amount to be staked.
     */
    function depositForAndBridge(address _beneficiary, uint256 _amount)
        external
        payable
        returns (uint256)
    {
        uint256 stTokenAmount = _stake(_amount);
        _bridgeToMatic(stTokenAmount, _beneficiary);

        return stTokenAmount;
    }

    /**
     * @dev Sell ETH/ERC20_Token using 1Inch, stake and send stMatic token to matic network.
     * @notice Swap tokens from exchanges like kyber, 0x etc, with calculation done off-chain.
     * @param _buyAddr The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _sellAddr The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _sellAmt The amount of the token to sell.
     * @param _unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param _callData Data from 1inch API.
     * @param _beneficiary ID stores the amount of token brought.
     */
    function swapStakeAndBridge(
        address _buyAddr, // TODO: make it constant
        address _sellAddr,
        uint256 _sellAmt,
        uint256 _unitAmt,
        bytes calldata _callData,
        address _beneficiary
    ) external payable {
        uint256 stMaticAmount = _swapAndStake(
            _buyAddr,
            _sellAddr,
            _sellAmt,
            _unitAmt,
            _callData
        );

        _bridgeToMatic(stMaticAmount, _beneficiary);
    }

    /**
     *  @notice Send stMatic tokens to _beneficiary in matic network.
     */
    function _bridgeToMatic(uint256 _stTokenAmount, address _beneficiary)
        private
    {
        TokenInterface(address(stMaticProxy)).approve(
            mintableERC20Proxy,
            _stTokenAmount
        );

        bytes memory depositData = abi.encode(_stTokenAmount);

        rootChainManagerProxy.depositFor(
            _beneficiary,
            address(stMaticProxy),
            depositData
        );
    }

    function calculateFee(uint256 _amt) public view returns (uint256) {
        return (_amt.mul(feePercentage)).div(FEE_DENOMINATOR);
    }

    /**
     * @dev 1inch API swap handler
     * @param oneInchData - contains data returned from 1inch API. Struct defined in interfaces.sol
     * @param ethAmt - Eth to swap for .value()
     */
    function oneInchSwap(OneInchData memory oneInchData, uint256 ethAmt)
        internal
        returns (uint256 buyAmt)
    {
        TokenInterface buyToken = oneInchData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(
            buyToken,
            oneInchData.sellToken
        );

        uint256 fees = calculateFee(oneInchData._sellAmt);
        uint256 finalSellAmt = oneInchData._sellAmt.sub(fees);
        uint256 _sellAmt18 = convertTo18(_sellDec, finalSellAmt);
        uint256 _slippageAmt = convert18ToDec(
            _buyDec,
            wmul(oneInchData.unitAmt, _sellAmt18)
        );

        uint256 initalBal = getTokenBal(buyToken);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = oneInchAddr.call{value: ethAmt}(
            oneInchData.callData
        );
        if (!success) revert("1Inch-swap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    /**
     * @dev Gets the swapping data from 1inch's API.
     * @param oneInchData Struct with multiple swap data defined in interfaces.sol
     */
    function _sell(OneInchData memory oneInchData)
        internal
        returns (OneInchData memory)
    {
        TokenInterface _sellAddr = oneInchData.sellToken;

        uint256 ethAmt;
        if (address(_sellAddr) == ethAddr) {
            ethAmt = oneInchData._sellAmt;
        } else {
            require(
                TokenInterface(address(_sellAddr)).transferFrom(
                    msg.sender,
                    address(this),
                    oneInchData._sellAmt
                ),
                "Matic not approved"
            );
            approve(
                TokenInterface(_sellAddr),
                oneInchAddr,
                oneInchData._sellAmt
            );
        }

        oneInchData._buyAmt = oneInchSwap(oneInchData, ethAmt);

        return oneInchData;
    }

    /**
     * @dev Sell ETH/ERC20_Token using 1Inch and stake to Polido.
     * @notice Swap tokens from exchanges like kyber, 0x etc, with calculation done off-chain.
     * @param buyAddr The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt The amount of the token to sell.
     * @param unitAmt The amount of buyAmt/sellAmt with slippage.
     * @param callData Data from 1inch API.
     */
    function _swapAndStake(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt,
        bytes calldata callData
    ) private returns (uint256) {
        OneInchData memory oneInchData = OneInchData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        oneInchData = _sell(oneInchData);

        maticToken.approve(address(stMaticProxy), oneInchData._buyAmt);
        uint256 stTokenAmount = stMaticProxy.submit(oneInchData._buyAmt);

        emit Deposited(msg.sender, oneInchData._buyAmt, stTokenAmount);

        return stTokenAmount;
    }

    /**
     * @notice Perform staking to polido and returns amount of stMatic tokens.
     */
    function _stake(uint256 _amount) private returns (uint256) {
        require(_amount > 0, "Invalid amount");
        require(
            maticToken.transferFrom(msg.sender, address(this), _amount),
            "Matic not approved"
        );

        maticToken.approve(address(stMaticProxy), _amount);
        uint256 stTokenAmount = stMaticProxy.submit(_amount);

        return stTokenAmount;
    }
}
