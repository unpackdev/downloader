// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibUtil.sol";
import "./IERC20Decimals.sol";
import "./GenericErrors.sol";

/// @title Lib Fee Collector
/// @author FormalCrypto
/// @notice Provides functionality to manages fees and take it
library LibFeeCollector {
    bytes32 internal constant FEE_STORAGE_POSITION =
        keccak256("fee.collector.storage.position");

    struct FeeStorage {
        address mainPartner;
        uint256 mainFee;
        uint256 defaultPartnerFeeShare;
        mapping(address => bool) isPartner;
        mapping(address => uint256) partnerFeeSharePercent;
        //partner -> token -> amount
        mapping(address => mapping(address => uint256)) feePerToken;
    }

    /// @dev Fetch local storage
    function _getStorage()
        internal
        pure
        returns (FeeStorage storage fs)
    {
        bytes32 position = FEE_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            fs.slot := position
        }
    }

    /**
     * @dev Updates main partner
     * @param _mainPartner Address of main partner
     */
    function updateMainPartner(address _mainPartner) internal {
        FeeStorage storage fs = _getStorage();

        fs.mainPartner = _mainPartner;
    }

    /**
     * @dev Updates mainFee
     * @param _mainFee Main fee
     */
    function updateMainFee(uint256 _mainFee) internal {
        FeeStorage storage fs = _getStorage();

        fs.mainFee = _mainFee;
    }

    /**
     * @dev Update default partner fe
     * @param _defaultPartnerFeeShare default partner fee
     */
    function updateDefaultPartnerFeeShare(uint256 _defaultPartnerFeeShare) internal {
        FeeStorage storage fs = _getStorage();

        fs.defaultPartnerFeeShare = _defaultPartnerFeeShare;
    }

    /**
     * @dev Adds new partner with custom fee
     * @param _partner Partner address
     * @param _partnerFeeShare partner fee
     */
    function addPartner(address _partner, uint256 _partnerFeeShare) internal {
        FeeStorage storage fs = _getStorage();

        fs.isPartner[_partner] = true;
        fs.partnerFeeSharePercent[_partner] = _partnerFeeShare;
    }

    /**
     * @dev Removes registred partner
     * @param _partner Partner address
     */
    function removePartner(address _partner) internal {
        FeeStorage storage fs = _getStorage();
        if (!fs.isPartner[_partner]) return;

        fs.isPartner[_partner] = false;
        fs.partnerFeeSharePercent[_partner] = 0;
    }

    /**
     * @dev Returns main fee
     */
    function getMainFee() internal view returns (uint256) {
        return _getStorage().mainFee;
    }

    /**
     * @dev Returns main partner
     */
    function getMainPartner() internal view returns (address) {
        return _getStorage().mainPartner;
    }

    /**
     * @dev Returns partner info
     * @param _partner Partner address
     * @return isPartner true if partner exists
     * @return partnerFeeSharePercent Partner fee (if exist)
     */
    function getPartnerInfo(address _partner) internal view returns (bool isPartner, uint256 partnerFeeSharePercent) {
        FeeStorage storage fs = _getStorage();
        return (fs.isPartner[_partner], fs.partnerFeeSharePercent[_partner]);
    }

    /**
     * @dev Returns fee amount that partner has accumulated 
     * @param _token Address of the token
     * @param _partner Partner address
     */
    function getFeeAmount(address _token, address _partner) internal view returns (uint256) {
        return(_getStorage().feePerToken[_partner][_token]);
    }

    /**
     * @dev Decrease fee amount of partner
     * @param _amount Amount of  tokens
     * @param _partner Partner address
     * @param _token Token address
     */
    function decreaseFeeAmount(uint256 _amount, address _partner, address _token) internal {
        FeeStorage storage fs = _getStorage();

        fs.feePerToken[_partner][_token] -= _amount;
    } 

    /**
     * @dev Takes fee when swaps token
     * @param _amount Total amount of token to be swapped
     * @param _token Address of the token to be swapped
     * @param _partner Partner address
     */
    function takeFromTokenFee(uint256 _amount, address _token, address _partner) internal returns (uint256 newAmount) {
        FeeStorage storage fs = _getStorage();

        (uint256 mainFee, uint256 partnerFee) = _calcFees(_amount, _partner);
        registerFee(mainFee, fs.mainPartner, _token);
        if (partnerFee != 0) registerFee(partnerFee, _partner, _token);
        
        newAmount = _amount - (mainFee + partnerFee);
    }

    /**
     * @dev Take fee when crosschain tokens
     * @param _amount Total amount of the tokens to be send to another network
     * @param _partner Address of the partner
     * @param _token Address of the token to be send to another network 
     * @param _crosschainFee Crosschain fee
     * @param _minFee Minimum crosschain fee
     */
    function takeCrosschainFee(
        uint256 _amount,
        address _partner,
        address _token,
        uint256 _crosschainFee,
        uint256 _minFee
    ) internal returns (uint256 newAmount) {
        FeeStorage storage fs = _getStorage();

        (uint256 mainFee, uint256 partnerFee) = _calcCrosschainFees(_amount, _crosschainFee, _minFee, _token, _partner);
        if ((mainFee + partnerFee) > _amount) revert FeeMoreThanFee(_amount, mainFee + partnerFee);
        registerFee(mainFee, fs.mainPartner, _token);
        if (partnerFee != 0) registerFee(partnerFee, _partner, _token);
        
        newAmount = _amount - (mainFee + partnerFee);
    }  

    /**
     * @dev Calculate fee to be paid
     * @param _amount Amount to be swapped
     * @param _partner Address of the partner
     */
    function _calcFees(uint256 _amount, address _partner) private view returns (uint256, uint256){
        FeeStorage storage fs = _getStorage();
        uint256 totalFee = _amount * fs.mainFee / 10000;

        return _splitFee(totalFee, _partner);
    }

    /**
     * @dev Calculate fee to be paid
     * @param _amount Amount to be send to anothe network 
     * @param _crosschainFee Crosschain fee
     * @param _minFee Minimum crosschain fee
     * @param _token Token to be send to another network
     * @param _partner Address of the partner
     */
    function _calcCrosschainFees(
        uint256 _amount, 
        uint256 _crosschainFee, 
        uint256 _minFee, 
        address _token,
        address _partner
    ) internal view returns (uint256, uint256) {
        uint256 percentFromAmount = _amount * _crosschainFee / 10000;
        
        uint256 decimals = IERC20Decimals(_token).decimals();
        uint256 minFee = _minFee * 10**decimals / 10000;

        uint256 totalFee = percentFromAmount < minFee ? minFee : percentFromAmount;

        return _splitFee(totalFee, _partner);
    }

    /**
     * @dev Splits fee between main partner and additional partner
     */
    function _splitFee(uint256 totalFee, address _partner) private view returns (uint256, uint256) {
        FeeStorage storage fs = _getStorage();

        uint256 mainFee;
        uint256 partnerFee;

        if (LibUtil.isZeroAddress(_partner)) {
            mainFee = totalFee;
            partnerFee = 0;
        } else {
            uint256 partnerFeePercent = fs.isPartner[_partner] 
                ? fs.partnerFeeSharePercent[_partner]
                : fs.defaultPartnerFeeShare;
            partnerFee = totalFee * partnerFeePercent / 10000;
            mainFee = totalFee - partnerFee;
        }  

        return (mainFee, partnerFee);
    }

    /**
     * @dev Registers fee to partner
     */
    function registerFee(uint256 _fee, address _partner, address _token) private {
        FeeStorage storage fs = _getStorage();
        
        fs.feePerToken[_partner][_token] += _fee;
    }
}
