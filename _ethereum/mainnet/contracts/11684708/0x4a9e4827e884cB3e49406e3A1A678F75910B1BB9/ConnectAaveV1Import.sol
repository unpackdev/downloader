pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface AaveInterface {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
    function redeemUnderlying(
        address _reserve,
        address payable _user,
        uint256 _amount,
        uint256 _aTokenBalanceAfterRedeem
    ) external;
    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external;
    function getUserReserveData(address _reserve, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentBorrowBalance,
        uint256 principalBorrowBalance,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint256 liquidityRate,
        uint256 originationFee,
        uint256 variableBorrowIndex,
        uint256 lastUpdateTimestamp,
        bool usageAsCollateralEnabled
    );
    function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external;
    function repay(address _reserve, uint256 _amount, address payable _onBehalfOf) external payable;
}

interface AaveProviderInterface {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
}

interface AaveCoreInterface {
    function getReserveATokenAddress(address _reserve) external view returns (address);
}

interface ATokenInterface {
    function redeem(uint256 _amount) external;
    function balanceOf(address _user) external view returns(uint256);
    function principalBalanceOf(address _user) external view returns(uint256);
    function transferFrom(address, address, uint) external returns (bool);
}

interface DSAInterface {
    function isAuth(address) external view returns(bool);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}

contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev get Referral Code
    */
    function getReferralCode() internal pure returns (uint16) {
        return 3228;
    }

    /**
     * @dev Connector Details.
     */
    function connectorID() public pure returns(uint model, uint id) {
        (model, id) = (1, 76);
    }
}

contract AaveHelpers is Helpers {

    /**
     * @dev get Aave Provider
    */
    function getAaveProvider() internal pure returns (AaveProviderInterface) {
        return AaveProviderInterface(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8); //mainnet
        // return AaveProviderInterface(0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5); //kovan
    }

    function getIsColl(AaveInterface aave, address token) internal view returns (bool isCol) {
        (, , , , , , , , , isCol) = aave.getUserReserveData(token, address(this));
    }

    function getPaybackBalance(AaveInterface aave, address token, address user) internal view returns (uint amt) {
        (, uint bal, , , , , uint fee, , , ) = aave.getUserReserveData(token, user);
        amt = add(bal, fee);
    }
}

contract AaveResolver is AaveHelpers {
    function _transferAtoken(
        uint _length,
        AaveInterface aave,
        ATokenInterface[] memory atokenContracts,
        address[] memory tokens,
        uint[] memory amts,
        address userAccount
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                require(atokenContracts[i].transferFrom(userAccount, address(this), amts[i]), "allowance?");

                if (!getIsColl(aave, tokens[i])) {
                    aave.setUserUseReserveAsCollateral(tokens[i], true);
                }
            }
        }
    }

    function _paybackOne(AaveInterface aave, address token, uint amt, address user) internal {
        if (amt > 0) {
            uint ethAmt;

            if (token == getEthAddr()) {
                ethAmt = amt;
            }

            aave.repay.value(ethAmt)(token, amt, payable(user));
        }
    }

    function _borrow(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        uint minAmt = 5000000; // 5e6
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                bool isSmallAmt = amts[i] < minAmt;
                uint borrowAmt = isSmallAmt ? minAmt : amts[i];
                uint paybackAmt = isSmallAmt ? sub(minAmt, amts[i]) : 0;

                aave.borrow(tokens[i], borrowAmt, 2, getReferralCode());
                _paybackOne(aave, tokens[i], paybackAmt, address(this));
            }
        }
    }

    function _payback(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint[] memory amts,
        address user
    ) internal {
        for (uint i = 0; i < _length; i++) {
            _paybackOne(aave, tokens[i], amts[i], user);
        }
    }
}

contract AaveImportResolver is AaveResolver {

    function importAave(address userAccount, address[] calldata tokens) external payable {
        require(DSAInterface(address(this)).isAuth(userAccount), "user-account-not-auth");

        uint minAmt = 5000000; // 5e6

        uint _length = tokens.length;
        require(_length > 0, "0-tokens-not-allowed");

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        AaveCoreInterface aaveCore = AaveCoreInterface(getAaveProvider().getLendingPoolCore());

        uint[] memory borrowAmts = new uint[](_length);
        uint[] memory atokensBal = new uint[](_length);
        ATokenInterface[] memory atokenContracts = new ATokenInterface[](_length);

        for (uint i = 0; i < _length; i++) {
            atokenContracts[i] = ATokenInterface(aaveCore.getReserveATokenAddress(tokens[i]));
            borrowAmts[i] = getPaybackBalance(aave, tokens[i], userAccount);
            atokensBal[i] = atokenContracts[i].balanceOf(userAccount);

            if (tokens[i] != getEthAddr()) {
                uint allowance = borrowAmts[i] < minAmt ? minAmt : borrowAmts[i]; 
                TokenInterface(tokens[i]).approve(address(aaveCore), allowance);
            }
        }

        _borrow(_length, aave, tokens, borrowAmts);
        _payback(_length, aave, tokens, borrowAmts, userAccount);
        _transferAtoken(_length, aave, atokenContracts, tokens, atokensBal, userAccount);
    }
}

contract ConnectAaveV1Import is AaveImportResolver {
    string public name = "AaveV1-Import-v1.1";
}