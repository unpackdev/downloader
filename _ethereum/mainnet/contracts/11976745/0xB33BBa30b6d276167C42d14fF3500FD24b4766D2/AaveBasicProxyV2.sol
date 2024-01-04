pragma solidity ^0.6.0;

import "./GasBurner.sol";
import "./TokenInterface.sol";
import "./IAToken.sol";
import "./ILendingPoolV2.sol";
import "./AaveHelperV2.sol";

import "./SafeERC20.sol";

/// @title Basic compound interactions through the DSProxy
contract AaveBasicProxyV2 is GasBurner, AaveHelperV2 {

    using SafeERC20 for ERC20;

    /// @notice User deposits tokens to the Aave protocol
    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @param _market address provider for specific market
    /// @param _tokenAddr The address of the token to be deposited
    /// @param _amount Amount of tokens to be deposited
    function deposit(address _market, address _tokenAddr, uint256 _amount) public burnGas(5) payable {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();

        if (_tokenAddr == ETH_ADDR) {
            require(msg.value == _amount);
            TokenInterface(WETH_ADDRESS).deposit{value: _amount}();
            _tokenAddr = WETH_ADDRESS;
        } else {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);
        }

        approveToken(_tokenAddr, lendingPool);
        ILendingPoolV2(lendingPool).deposit(_tokenAddr, _amount, address(this), AAVE_REFERRAL_CODE);

        setUserUseReserveAsCollateralIfNeeded(_market, _tokenAddr);
    }

    /// @notice User withdraws tokens from the Aave protocol
    /// @param _market address provider for specific market
    /// @param _tokenAddr The address of the token to be withdrawn
    /// @param _amount Amount of tokens to be withdrawn -> send -1 for whole amount
    function withdraw(address _market, address _tokenAddr, uint256 _amount) public burnGas(8) {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        _tokenAddr = changeToWeth(_tokenAddr);

        if (_tokenAddr == WETH_ADDRESS) {
            // if weth, pull to proxy and return ETH to user
            ILendingPoolV2(lendingPool).withdraw(_tokenAddr, _amount, address(this));
            // needs to use balance of in case that amount is -1 for whole debt
            TokenInterface(WETH_ADDRESS).withdraw(TokenInterface(WETH_ADDRESS).balanceOf(address(this)));
            msg.sender.transfer(address(this).balance);
        } else {
            // if not eth send directly to user
            ILendingPoolV2(lendingPool).withdraw(_tokenAddr, _amount, msg.sender);
        }
    }

    /// @notice User borrows tokens to the Aave protocol
    /// @param _market address provider for specific market
    /// @param _tokenAddr The address of the token to be borrowed
    /// @param _amount Amount of tokens to be borrowed
    /// @param _type Send 1 for stable rate and 2 for variable
    function borrow(address _market, address _tokenAddr, uint256 _amount, uint256 _type) public burnGas(8) {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        _tokenAddr = changeToWeth(_tokenAddr);

        ILendingPoolV2(lendingPool).borrow(_tokenAddr, _amount, _type, AAVE_REFERRAL_CODE, address(this));

        if (_tokenAddr == WETH_ADDRESS) {
            // we do this so the user gets eth instead of weth
            TokenInterface(WETH_ADDRESS).withdraw(_amount);
            _tokenAddr = ETH_ADDR;
        }

        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _market address provider for specific market
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _amount Amount of tokens to be payed back
    function payback(address _market, address _tokenAddr, uint256 _amount, uint256 _rateMode) public burnGas(3) payable {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        _tokenAddr = changeToWeth(_tokenAddr);

        if (_tokenAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).deposit{value: msg.value}();
        } else {
            uint amountToPull = min(_amount, ERC20(_tokenAddr).balanceOf(msg.sender));
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), amountToPull);
        }

        approveToken(_tokenAddr, lendingPool);
        ILendingPoolV2(lendingPool).repay(_tokenAddr, _amount, _rateMode, payable(address(this)));

        if (_tokenAddr == WETH_ADDRESS) {
            // Pull if we have any eth leftover
            TokenInterface(WETH_ADDRESS).withdraw(ERC20(WETH_ADDRESS).balanceOf(address(this)));
            _tokenAddr = ETH_ADDR;
        }

        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _market address provider for specific market
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _amount Amount of tokens to be payed back
    function paybackOnBehalf(address _market, address _tokenAddr, uint256 _amount, uint256 _rateMode, address _onBehalf) public burnGas(3) payable {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        _tokenAddr = changeToWeth(_tokenAddr);

        if (_tokenAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).deposit{value: msg.value}();
        } else {
            uint amountToPull = min(_amount, ERC20(_tokenAddr).allowance(msg.sender, address(this)));
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), amountToPull);
        }

        approveToken(_tokenAddr, lendingPool);
        ILendingPoolV2(lendingPool).repay(_tokenAddr, _amount, _rateMode, _onBehalf);

        if (_tokenAddr == WETH_ADDRESS) {
            // we do this so the user gets eth instead of weth
            TokenInterface(WETH_ADDRESS).withdraw(_amount);
            _tokenAddr = ETH_ADDR;
        }

        withdrawTokens(_tokenAddr);
    }


    /// @notice Helper method to withdraw tokens from the DSProxy
    /// @param _tokenAddr Address of the token to be withdrawn
    function withdrawTokens(address _tokenAddr) public {
        uint256 amount = _tokenAddr == ETH_ADDR ? address(this).balance : ERC20(_tokenAddr).balanceOf(address(this));

        if (amount > 0) {
            if (_tokenAddr != ETH_ADDR) {
                ERC20(_tokenAddr).safeTransfer(msg.sender, amount);
            } else {
                msg.sender.transfer(amount);
            }
        }
    }

    function setUserUseReserveAsCollateralIfNeeded(address _market, address _tokenAddr) public {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        IAaveProtocolDataProviderV2 dataProvider = getDataProvider(_market);

        (,,,,,,,,bool collateralEnabled) = dataProvider.getUserReserveData(_tokenAddr, address(this));

        if (!collateralEnabled) {
            ILendingPoolV2(lendingPool).setUserUseReserveAsCollateral(_tokenAddr, true);
        }
    }

    function setUserUseReserveAsCollateral(address _market, address _tokenAddr, bool _true) public {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();

        ILendingPoolV2(lendingPool).setUserUseReserveAsCollateral(_tokenAddr, _true);
    }

    // stable = 1, variable = 2
    function swapBorrowRateMode(address _market, address _reserve, uint _rateMode) public {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();

        ILendingPoolV2(lendingPool).swapBorrowRateMode(_reserve, _rateMode);
    }

    function changeToWeth(address _token) private view returns(address) {
        if (_token == ETH_ADDR) {
            return WETH_ADDRESS;
        }

        return _token;
    }


    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}
