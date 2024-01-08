pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces.sol";
import "./interfaces.sol";
import "./helpers.sol";
import "./events.sol";
import "./variables.sol";


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
                // console.log("_transferCtokens", ctokenContracts[i].allowance(userAccount, address(this)), amts[i], ctokenContracts[i].balanceOf(userAccount));
                require(ctokenContracts[i].transferFrom(userAccount, address(this), amts[i]), "ctoken-transfer-failed-allowance?");
            }
        }
    }
}

contract CompoundHelpers is CompoundResolver, Variables {
    constructor(address _instaCompoundMerkle) Variables(_instaCompoundMerkle) {}
    struct ImportData {
        uint[] supplyAmts;
        uint[] borrowAmts;
        uint[] supplySplitAmts;
        uint[] borrowSplitAmts;
        uint[] supplyFinalAmts;
        uint[] borrowFinalAmts;
        address[] ctokens;
        CTokenInterface[] supplyCtokens;
        CTokenInterface[] borrowCtokens;
        address[] supplyCtokensAddr;
        address[] borrowCtokensAddr;
    }

    struct ImportInputData {
        uint256 index;
        address userAccount;
        string[] supplyIds;
        string[] borrowIds;
        uint256 times;
        bool isFlash;
        uint256 rewardAmount;
        uint256 networthAmount;
        bytes32[] merkleProof;
    }

    function getBorrowAmounts (
        ImportInputData memory importInputData,
        ImportData memory data
    ) internal returns(ImportData memory) {
        if (importInputData.borrowIds.length > 0) {
            data.borrowAmts = new uint[](importInputData.borrowIds.length);
            data.borrowCtokens = new CTokenInterface[](importInputData.borrowIds.length);
            data.borrowSplitAmts = new uint[](importInputData.borrowIds.length);
            data.borrowFinalAmts = new uint[](importInputData.borrowIds.length);
            data.borrowCtokensAddr = new address[](importInputData.borrowIds.length);

            for (uint i = 0; i < importInputData.borrowIds.length; i++) {
                bytes32 i_hash = keccak256(abi.encode(importInputData.borrowIds[i]));
                for (uint j = i; j < importInputData.borrowIds.length; j++) {
                    bytes32 j_hash = keccak256(abi.encode(importInputData.borrowIds[j]));
                    if (j != i) {
                        require(i_hash != j_hash, "token-repeated");
                    }
                }
            }

            if (importInputData.times > 0) {
                for (uint i = 0; i < importInputData.borrowIds.length; i++) {
                    (address _token, address _ctoken) = compMapping.getMapping(importInputData.borrowIds[i]);
                    require(_token != address(0) && _ctoken != address(0), "ctoken mapping not found");

                    data.ctokens[i] = _ctoken;

                    data.borrowCtokens[i] = CTokenInterface(_ctoken);
                    data.borrowCtokensAddr[i] = (_ctoken);
                    data.borrowAmts[i] = data.borrowCtokens[i].borrowBalanceCurrent(importInputData.userAccount);

                    if (_token != ethAddr && data.borrowAmts[i] > 0) {
                        TokenInterface(_token).approve(_ctoken, data.borrowAmts[i]);
                    }

                    if (importInputData.times == 1) {
                        data.borrowFinalAmts = data.borrowAmts;
                    } else {
                        for (uint256 j = 0; j < data.borrowAmts.length; j++) {
                            data.borrowSplitAmts[j] = data.borrowAmts[j] / importInputData.times;
                            data.borrowFinalAmts[j] = sub(data.borrowAmts[j], mul(data.borrowSplitAmts[j], sub(importInputData.times, 1)));
                        }
                    }
                }
            }
        }
        return data;
    }
    
    function getSupplyAmounts (
        ImportInputData memory importInputData,
        ImportData memory data
    ) internal view returns(ImportData memory) {
        data.supplyAmts = new uint[](importInputData.supplyIds.length);
        data.supplyCtokens = new CTokenInterface[](importInputData.supplyIds.length);
        data.supplySplitAmts = new uint[](importInputData.supplyIds.length);
        data.supplyFinalAmts = new uint[](importInputData.supplyIds.length);
        data.supplyCtokensAddr = new address[](importInputData.supplyIds.length);

        for (uint i = 0; i < importInputData.supplyIds.length; i++) {
            bytes32 i_hash = keccak256(abi.encode(importInputData.supplyIds[i]));
            for (uint j = i; j < importInputData.supplyIds.length; j++) {
                bytes32 j_hash = keccak256(abi.encode(importInputData.supplyIds[j]));
                if (j != i) {
                    require(i_hash != j_hash, "token-repeated");
                }
            }
        }

        for (uint i = 0; i < importInputData.supplyIds.length; i++) {
            (address _token, address _ctoken) = compMapping.getMapping(importInputData.supplyIds[i]);
            require(_token != address(0) && _ctoken != address(0), "ctoken mapping not found");

            uint _supplyIndex = add(i, importInputData.borrowIds.length);

            data.ctokens[_supplyIndex] = _ctoken;

            data.supplyCtokens[i] = CTokenInterface(_ctoken);
            data.supplyCtokensAddr[i] = (_ctoken);
            data.supplyAmts[i] = data.supplyCtokens[i].balanceOf(importInputData.userAccount);

            if ((importInputData.times == 1 && importInputData.isFlash) || importInputData.times == 0) {
                data.supplyFinalAmts = data.supplyAmts;
            } else {
                for (uint j = 0; j < data.supplyAmts.length; j++) {
                    uint _times = importInputData.isFlash ? importInputData.times : importInputData.times + 1;
                    data.supplySplitAmts[j] = data.supplyAmts[j] / _times;
                    data.supplyFinalAmts[j] = sub(data.supplyAmts[j], mul(data.supplySplitAmts[j], sub(_times, 1)));
                }

            }
        }
        return data;
    }

}

contract CompoundImportResolver is CompoundHelpers {
    constructor(address _instaCompoundMerkle) CompoundHelpers(_instaCompoundMerkle) {}

    function _importCompound(
        ImportInputData memory importInputData
    ) internal returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(importInputData.userAccount), "user-account-not-auth");

        require(importInputData.supplyIds.length > 0, "0-length-not-allowed");

        ImportData memory data;

        uint _length = add(importInputData.supplyIds.length, importInputData.borrowIds.length);
        data.ctokens = new address[](_length);
    
        data = getBorrowAmounts(importInputData, data);
        data = getSupplyAmounts(importInputData, data);

        enterMarkets(data.ctokens);

        if (!importInputData.isFlash && importInputData.times > 0) {
            _transferCtokens(importInputData.userAccount, data.supplyCtokens, data.supplySplitAmts, importInputData.supplyIds.length);
        } else if (importInputData.times == 0) {
            _transferCtokens(importInputData.userAccount, data.supplyCtokens, data.supplyFinalAmts, importInputData.supplyIds.length);
        }
        
        for (uint i = 0; i < importInputData.times; i++) {
            if (i == sub(importInputData.times, 1)) {
                _borrow(data.borrowCtokens, data.borrowFinalAmts, importInputData.borrowIds.length);
                _paybackOnBehalf(importInputData.userAccount, data.borrowCtokens, data.borrowFinalAmts, importInputData.borrowIds.length);
                _transferCtokens(importInputData.userAccount, data.supplyCtokens, data.supplyFinalAmts, importInputData.supplyIds.length);
            } else {
                _borrow(data.borrowCtokens, data.borrowSplitAmts, importInputData.borrowIds.length);
                _paybackOnBehalf(importInputData.userAccount, data.borrowCtokens, data.borrowSplitAmts, importInputData.borrowIds.length);
                _transferCtokens(importInputData.userAccount, data.supplyCtokens, data.supplySplitAmts, importInputData.supplyIds.length);
            }
        }

        if (importInputData.index != 0) {
            instaCompoundMerkle.claim(
                importInputData.index,
                importInputData.userAccount,
                importInputData.rewardAmount,
                importInputData.networthAmount,
                importInputData.merkleProof,
                data.supplyCtokensAddr,
                data.borrowCtokensAddr,
                data.supplyAmts,
                data.borrowAmts
            );
        }

        _eventName = "LogCompoundImport(address,address[],string[],string[],uint256[],uint256[])";
        _eventParam = abi.encode(
            importInputData.userAccount,
            data.ctokens,
            importInputData.supplyIds,
            importInputData.borrowIds,
            data.supplyAmts,
            data.borrowAmts
        );
    }

    function importCompound(
        uint256 index,
        address userAccount,
        string[] memory supplyIds,
        string[] memory borrowIds,
        uint256 times,
        bool isFlash,
        uint256 rewardAmount,
        uint256 networthAmount,
        bytes32[] memory merkleProof
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        ImportInputData memory inputData = ImportInputData({
            index: index,
            userAccount: userAccount,
            supplyIds: supplyIds,
            borrowIds: borrowIds,
            times: times,
            isFlash: isFlash,
            rewardAmount: rewardAmount,
            networthAmount: networthAmount,
            merkleProof: merkleProof
        });

        (_eventName, _eventParam) = _importCompound(inputData);
    }

    function migrateCompound(
        uint256 index,
        string[] memory supplyIds,
        string[] memory borrowIds,
        uint256 times,
        bool isFlash,
        uint256 rewardAmount,
        uint256 networthAmount,
        bytes32[] memory merkleProof
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        ImportInputData memory inputData = ImportInputData({
            index: index,
            userAccount: msg.sender,
            supplyIds: supplyIds,
            borrowIds: borrowIds,
            times: times,
            isFlash: isFlash,
            rewardAmount: rewardAmount,
            networthAmount: networthAmount,
            merkleProof: merkleProof
        });

        (_eventName, _eventParam) = _importCompound(inputData);
    }
}

contract ConnectV2CompoundMerkleImport is CompoundImportResolver {
    constructor(address _instaCompoundMerkle) public CompoundImportResolver(_instaCompoundMerkle) {}

    string public constant name = "Compound-Merkle-Import-v1";
}
