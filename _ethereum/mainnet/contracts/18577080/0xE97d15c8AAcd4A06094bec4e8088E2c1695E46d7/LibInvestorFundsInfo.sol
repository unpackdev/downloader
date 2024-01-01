// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/
// Local imports - Structs
import "./StorageTypes.sol";

/// @notice Library containing investor funds info storage with getters and setters.
library LibInvestorFundsInfo {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Investor funds info storage pointer.
    bytes32 internal constant INVESTOR_FUNDS_INFO_STORAGE_POSITION = keccak256("angelblock.fundraising.investor.funds.info");

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Investor funds info storage struct.
    /// @param investorFundsInfo Mapping of raise id to investor funds info struct
    struct InvestorFundsInfoStorage {
        mapping(string => StorageTypes.InvestorFundsInfo) investorFundsInfo;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning investor funds info storage at storage pointer slot.
    /// @return ifis InvestorFundsInfoStorage struct instance at storage pointer position
    function investorFundsInfoStorage() internal pure returns (InvestorFundsInfoStorage storage ifis) {
        // declare position
        bytes32 position = INVESTOR_FUNDS_INFO_STORAGE_POSITION;

        // set slot to position
        assembly {
            ifis.slot := position
        }

        // explicit return
        return ifis;
    }

    // -----------------------------------------------------------------------
    //                              Getters / setters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: Invested amount in given raise.
    /// @param _raiseId ID of the raise
    /// @param _account Investor address
    /// @return Amount of invested base asset in the given raise
    function getInvested(string memory _raiseId, address _account) internal view returns (uint256) {
        return investorFundsInfoStorage().investorFundsInfo[_raiseId].invested[_account];
    }

    /// @dev Diamond storage getter: Is investment refunded.
    /// @param _raiseId ID of the raise
    /// @param _account Investor address
    /// @return Is invested retunded
    function getInvestmentRefunded(string memory _raiseId, address _account) internal view returns (bool) {
        return investorFundsInfoStorage().investorFundsInfo[_raiseId].investmentRefunded[_account];
    }

    /// @dev Diamond storage setter: Increase invested amount for given raise.
    /// @param _raiseId ID of the raise
    /// @param _account Investor address
    /// @param _invested Value to be increased
    function increaseInvested(string memory _raiseId, address _account, uint256 _invested) internal {
        investorFundsInfoStorage().investorFundsInfo[_raiseId].invested[_account] += _invested;
    }

    /// @dev Diamond storage setter: Is investment refunded.
    /// @param _raiseId ID of the raise
    /// @param _account Investor address
    /// @param _refunded Is invested retunded
    function setInvestmentRefunded(string memory _raiseId, address _account, bool _refunded) internal {
        investorFundsInfoStorage().investorFundsInfo[_raiseId].investmentRefunded[_account] = _refunded;
    }
}
