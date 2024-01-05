pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces.sol";
import "./interfaces.sol";
import "./helpers.sol";
import "./events.sol";

abstract contract AaveResolver is Helpers, Events {
    function _TransferAtokens(
        uint _length,
        AaveInterface aave,
        ATokenInterface[] memory atokenContracts,
        uint[] memory amts,
        address[] memory tokens,
        address userAccount
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                require(atokenContracts[i].transferFrom(userAccount, address(this), amts[i]), "allowance?");
                
                if (!getIsColl(tokens[i], address(this))) {
                    aave.setUserUseReserveAsCollateral(tokens[i], true);
                }
            }
        }
    }

    function _borrowOne(AaveInterface aave, address token, uint amt, uint rateMode) private {
        aave.borrow(token, amt, rateMode, referalCode, address(this));
    }

    function _paybackBehalfOne(AaveInterface aave, address token, uint amt, uint rateMode, address user) private {
        aave.repay(token, amt, rateMode, user);
    }

    function _BorrowStable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _borrowOne(aave, tokens[i], amts[i], 1);
            }
        }
    }

    function _BorrowVariable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _borrowOne(aave, tokens[i], amts[i], 2);
            }
        }
    }

    function _PaybackStable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts,
        address user
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _paybackBehalfOne(aave, tokens[i], amts[i], 1, user);
            }
        }
    }

    function _PaybackVariable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts,
        address user
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _paybackBehalfOne(aave, tokens[i], amts[i], 2, user);
            }
        }
    }
}

contract AaveImportResolver is AaveResolver {
    struct ImportData {
        uint[] supplyAmts;
        uint[] variableBorrowAmts;
        uint[] stableBorrowAmts;
        uint[] totalBorrowAmts;
        address[] supplyTokens;
        address[] borrowTokens;
        ATokenInterface[] aTokens;
    }

    function importAave(
        address userAccount,
        address[] calldata supplyTokens,
        address[] calldata borrowTokens,
        bool convertStable
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(userAccount), "user-account-not-auth");

        require(supplyTokens.length > 0, "0-length-not-allowed");

        ImportData memory data;

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        data.supplyAmts = new uint[](supplyTokens.length);
        data.supplyTokens = new address[](supplyTokens.length);
        data.aTokens = new ATokenInterface[](supplyTokens.length);

        for (uint i = 0; i < supplyTokens.length; i++) {
            address _token = supplyTokens[i] == ethAddr ? wethAddr : supplyTokens[i];
            (address _aToken, ,) = aaveData.getReserveTokensAddresses(_token);
            data.supplyTokens[i] = _token;
            data.aTokens[i] = ATokenInterface(_aToken);
            data.supplyAmts[i] = data.aTokens[i].balanceOf(userAccount);
        }

        if (borrowTokens.length > 0) {
            data.variableBorrowAmts = new uint[](borrowTokens.length);
            data.stableBorrowAmts = new uint[](borrowTokens.length);
            data.totalBorrowAmts = new uint[](borrowTokens.length);
            data.borrowTokens = new address[](borrowTokens.length);

            for (uint i = 0; i < borrowTokens.length; i++) {
                address _token = borrowTokens[i] == ethAddr ? wethAddr : borrowTokens[i];
                data.borrowTokens[i] = _token;

                (
                    ,
                    data.stableBorrowAmts[i],
                    data.variableBorrowAmts[i],
                    ,,,,,
                ) = aaveData.getUserReserveData(_token, userAccount);

                data.totalBorrowAmts[i] = add(data.stableBorrowAmts[i], data.variableBorrowAmts[i]);

                if (data.totalBorrowAmts[i] > 0) {
                    TokenInterface(_token).approve(address(aave), data.totalBorrowAmts[i]);
                }
            }

            if (convertStable) {
                _BorrowVariable(borrowTokens.length, aave, data.borrowTokens, data.totalBorrowAmts);
            } else {
                _BorrowStable(borrowTokens.length, aave, data.borrowTokens, data.stableBorrowAmts);
                _BorrowVariable(borrowTokens.length, aave, data.borrowTokens, data.variableBorrowAmts);
            }

            _PaybackStable(borrowTokens.length, aave, data.borrowTokens, data.stableBorrowAmts, userAccount);
            _PaybackVariable(borrowTokens.length, aave, data.borrowTokens, data.variableBorrowAmts, userAccount);
        }

        _TransferAtokens(supplyTokens.length, aave, data.aTokens, data.supplyAmts, data.supplyTokens, userAccount);

        _eventName = "LogAaveV2Import(address,bool,address[],address[],uint256[],uint256[],uint256[])";
        _eventParam = abi.encode(
            userAccount,
            convertStable,
            supplyTokens,
            borrowTokens,
            data.supplyAmts,
            data.stableBorrowAmts,
            data.variableBorrowAmts
        );
    }
}

contract ConnectV2AaveV2Import is AaveImportResolver {
    string public constant name = "V2-AaveV2-Import-v1";
}