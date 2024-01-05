pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces.sol";
import "./interfaces.sol";
import "./helpers.sol";
import "./events.sol";

contract CompoundResolver is Helpers, Events {
    function _borrow(CTokenInterface[] memory ctokenContracts, uint[] memory amts, uint _length) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                require(ctokenContracts[i].borrow(amts[i]) == 0, "borrow-failed-collateral?");
            }
        }
    }

    function _paybackOnBehalf(
        address userAddress,
        CTokenInterface[] memory ctokenContracts,
        uint[] memory amts,
        uint _length
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                if (address(ctokenContracts[i]) == address(ceth)) {
                    ceth.repayBorrowBehalf{value: amts[i]}(userAddress);
                } else {
                    require(ctokenContracts[i].repayBorrowBehalf(userAddress, amts[i]) == 0, "repayOnBehalf-failed");
                }
            }
        }
    }

    function _transferCtokens(
        address userAccount,
        CTokenInterface[] memory ctokenContracts,
        uint[] memory amts,
        uint _length
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                require(ctokenContracts[i].transferFrom(userAccount, address(this), amts[i]), "ctoken-transfer-failed-allowance?");
            }
        }
    }
}

contract CompoundImportResolver is CompoundResolver {

    struct ImportData {
        uint[] supplyAmts;
        uint[] borrowAmts;
        address[] ctokens;
        CTokenInterface[] supplyCtokens;
        CTokenInterface[] borrowCtokens;
    }

    function importCompound(
        address userAccount,
        string[] calldata supplyIds,
        string[] calldata borrowIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(userAccount), "user-account-not-auth");

        require(supplyIds.length > 0, "0-length-not-allowed");

        ImportData memory data;

        uint _length = add(supplyIds.length, borrowIds.length);
        data.ctokens = new address[](_length);
        data.supplyAmts = new uint[](supplyIds.length);
        data.supplyCtokens = new CTokenInterface[](supplyIds.length);

        if (borrowIds.length > 0) {
            data.borrowAmts = new uint[](borrowIds.length);
            data.borrowCtokens = new CTokenInterface[](borrowIds.length);

            for (uint i = 0; i < borrowIds.length; i++) {
                (address _token, address _ctoken) = compMapping.getMapping(borrowIds[i]);
                require(_token != address(0) && _ctoken != address(0), "ctoken mapping not found");

                data.ctokens[i] = _ctoken;

                data.borrowCtokens[i] = CTokenInterface(_ctoken);
                data.borrowAmts[i] = data.borrowCtokens[i].borrowBalanceCurrent(userAccount);

                if (_token != ethAddr && data.borrowAmts[i] > 0) {
                    TokenInterface(_token).approve(_ctoken, data.borrowAmts[i]);
                }
            }
        }

        for (uint i = 0; i < supplyIds.length; i++) {
            (address _token, address _ctoken) = compMapping.getMapping(supplyIds[i]);
            require(_token != address(0) && _ctoken != address(0), "ctoken mapping not found");

            uint index = add(i, borrowIds.length);

            data.ctokens[index] = _ctoken;

            data.supplyCtokens[i] = CTokenInterface(_ctoken);
            data.supplyAmts[i] = data.supplyCtokens[i].balanceOf(userAccount);
        }

        enterMarkets(data.ctokens);
        _borrow(data.borrowCtokens, data.borrowAmts, borrowIds.length);
        _paybackOnBehalf(userAccount, data.borrowCtokens, data.borrowAmts, borrowIds.length);
        _transferCtokens(userAccount, data.supplyCtokens, data.supplyAmts, supplyIds.length);

        _eventName = "LogCompoundImport(address,address[],string[],string[],uint256[],uint256[])";
        _eventParam = abi.encode(userAccount, data.ctokens, supplyIds, borrowIds, data.supplyAmts, data.borrowAmts);
    }
}

contract ConnectV2CompoundImport is CompoundImportResolver {
    string public constant name = "V2-Compound-Import-v1";
}