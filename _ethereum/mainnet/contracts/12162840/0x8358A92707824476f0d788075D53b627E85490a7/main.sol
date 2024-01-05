pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces.sol";
import "./interfaces.sol";
import "./helpers.sol";
import "./events.sol";

abstract contract AaveResolver is Helpers, Events {
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

            if (token == ethAddr) {
                ethAmt = amt;
            }

            aave.repay{value: ethAmt}(token, amt, payable(user));
        }
    }

    function _borrow(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint[] memory amts
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                bool isSmallAmt = amts[i] < minBorrowAmt;
                uint borrowAmt = isSmallAmt ? minBorrowAmt : amts[i];
                uint paybackAmt = isSmallAmt ? sub(minBorrowAmt, amts[i]) : 0;

                aave.borrow(tokens[i], borrowAmt, 2, referalCode);
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
    struct ImportData {
        uint[] supplyAmts;
        uint[] borrowAmts;
        ATokenInterface[] aTokens;
    }

    function importAave(
        address userAccount,
        address[] calldata supplyTokens,
        address[] calldata borrowTokens
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(userAccount), "user-account-not-auth");

        require(supplyTokens.length > 0, "0-length-not-allowed");

        ImportData memory data;

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());
        AaveCoreInterface aaveCore = AaveCoreInterface(aaveProvider.getLendingPoolCore());

        data.supplyAmts = new uint[](supplyTokens.length);
        data.aTokens = new ATokenInterface[](supplyTokens.length);

        for (uint i = 0; i < supplyTokens.length; i++) {
            data.aTokens[i] = ATokenInterface(aaveCore.getReserveATokenAddress(supplyTokens[i]));
            data.supplyAmts[i] = data.aTokens[i].balanceOf(userAccount);
        }

        if (borrowTokens.length > 0) {
            data.borrowAmts = new uint[](borrowTokens.length);

            for (uint i = 0; i < borrowTokens.length; i++) {
                data.borrowAmts[i] = getPaybackBalance(aave, borrowTokens[i], userAccount);

                if (borrowTokens[i] != ethAddr && data.borrowAmts[i] > 0) {
                    uint allowance = data.borrowAmts[i] < minBorrowAmt ? minBorrowAmt : data.borrowAmts[i]; 
                    TokenInterface(borrowTokens[i]).approve(address(aaveCore), allowance);
                }
            }

            _borrow(borrowTokens.length, aave, borrowTokens, data.borrowAmts);
            _payback(borrowTokens.length, aave, borrowTokens, data.borrowAmts, userAccount);
        }

        _transferAtoken(supplyTokens.length, aave, data.aTokens, supplyTokens, data.supplyAmts, userAccount);

        _eventName = "LogAaveV1Import(address,address[],address[],uint256[],uint256[])";
        _eventParam = abi.encode(userAccount, supplyTokens, borrowTokens, data.supplyAmts, data.borrowAmts);
    }
}

contract ConnectV2AaveImport is AaveImportResolver {
    string public constant name = "V2-AaveV1-Import-v1";
}