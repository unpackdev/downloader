// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ITroveManager.sol";
import "./ICollateralManager.sol";
import "./ISortedTroves.sol";
import "./ERDBase.sol";
import "./Errors.sol";

contract HintHelpers is ERDBase, OwnableUpgradeable {
    string public constant NAME = "HintHelpers";
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    ISortedTroves public sortedTroves;
    ITroveManager public troveManager;

    // --- Events ---

    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event TroveManagerAddressChanged(address _troveManagerAddress);
    event CollateralManagerAddressChanged(address _collateralManagerAddress);

    // --- Dependency setters ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setAddresses(
        address _sortedTrovesAddress,
        address _troveManagerAddress,
        address _collateralManagerAddress
    ) external onlyOwner {
        _requireIsContract(_sortedTrovesAddress);
        _requireIsContract(_troveManagerAddress);
        _requireIsContract(_collateralManagerAddress);

        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        troveManager = ITroveManager(_troveManagerAddress);
        collateralManager = ICollateralManager(_collateralManagerAddress);

        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit CollateralManagerAddressChanged(_troveManagerAddress);
    }

    // --- Functions ---

    /* getRedemptionHints() - Helper function for finding the right hints to pass to redeemCollateral().
     *
     * It simulates a redemption of `_USDEamount` to figure out where the redemption sequence will start and what state the final Trove
     * of the sequence will end up in.
     *
     * Returns three hints:
     *  - `firstRedemptionHint` is the address of the first Trove with ICR >= MCR (i.e. the first Trove that will be redeemed).
     *  - `partialRedemptionHintNICR` is the final nominal ICR of the last Trove of the sequence after being hit by partial redemption,
     *     or zero in case of no partial redemption.
     *  - `truncatedUSDEamount` is the maximum amount that can be redeemed out of the the provided `_USDEamount`. This can be lower than
     *    `_USDEamount` when redeeming the full amount would leave the last Trove of the redemption sequence with less net debt than the
     *    minimum allowed value (i.e. MIN_NET_DEBT).
     *
     * The number of Troves to consider for redemption can be capped by passing a non-zero value as `_maxIterations`, while passing zero
     * will leave it uncapped.
     */

    function getRedemptionHints(
        uint256 _USDEamount,
        uint256 _price,
        uint256 _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint256 partialRedemptionHintICR,
            uint256 truncatedUSDEamount
        )
    {
        ISortedTroves sortedTrovesCached = sortedTroves;

        uint256 remainingUSDE = _USDEamount;
        address currentTroveuser = sortedTrovesCached.getLast();
        uint256 price = _price;
        uint256 mcr = collateralManager.getMCR();

        while (
            currentTroveuser != address(0) &&
            troveManager.getCurrentICR(currentTroveuser, price) < mcr
        ) {
            currentTroveuser = sortedTrovesCached.getPrev(currentTroveuser);
        }

        firstRedemptionHint = currentTroveuser;

        if (_maxIterations == 0) {
            _maxIterations = type(uint256).max;
        }

        uint256 gas = collateralManager.getUSDEGasCompensation();
        while (
            currentTroveuser != address(0) &&
            remainingUSDE > 0 &&
            _maxIterations-- > 0
        ) {
            (
                uint256[] memory colls,
                address[] memory collaterals,
                uint256 currUSDEDebt
            ) = troveManager.getCurrentTroveAmounts(currentTroveuser);
            uint256 netUSDEDebt = currUSDEDebt.sub(gas);
            if (netUSDEDebt > remainingUSDE) {
                uint256 minNetDebt = collateralManager.getMinNetDebt();
                if (netUSDEDebt > minNetDebt) {
                    uint256 maxRedeemableUSDE = ERDMath._min(
                        remainingUSDE,
                        netUSDEDebt.sub(minNetDebt)
                    );
                    {
                        (uint256 currValue, ) = collateralManager.getValue(
                            collaterals,
                            colls,
                            price
                        );
                        currValue = currValue.sub(maxRedeemableUSDE);
                        netUSDEDebt = netUSDEDebt.sub(maxRedeemableUSDE);

                        uint256 compositeDebt = _getCompositeDebt(
                            netUSDEDebt,
                            gas
                        );
                        partialRedemptionHintICR = ERDMath._computeCR(
                            currValue,
                            compositeDebt
                        );
                    }

                    remainingUSDE = remainingUSDE.sub(maxRedeemableUSDE);
                }
                break;
            } else {
                remainingUSDE = remainingUSDE.sub(netUSDEDebt);
            }

            currentTroveuser = sortedTrovesCached.getPrev(currentTroveuser);
            if (_maxIterations == 0) {
                break;
            }
        }

        truncatedUSDEamount = _USDEamount.sub(remainingUSDE);
    }

    /* getApproxHint() - return address of a Trove that is, on average, (length / numTrials) positions away in the 
    sortedTroves list from the correct insert position of the Trove to be inserted. 
    
    Note: The output address is worst-case O(n) positions away from the correct insert position, however, the function 
    is probabilistic. Input can be tuned to guarantee results to a high degree of confidence, e.g:

    Submitting numTrials = k * sqrt(length), with k = 15 makes it very, very likely that the ouput address will 
    be <= sqrt(length) positions away from the correct insert position.
    */
    function getApproxHint(
        uint256 _CR,
        uint256 _numTrials,
        uint256 _inputRandomSeed,
        uint256 _price
    )
        external
        view
        returns (address hintAddress, uint256 diff, uint256 latestRandomSeed)
    {
        uint256 arrayLength = troveManager.getTroveOwnersCount();

        if (arrayLength == 0) {
            return (address(0), 0, _inputRandomSeed);
        }
        uint256 price = _price;

        hintAddress = sortedTroves.getLast();
        diff = ERDMath._getAbsoluteDifference(
            _CR,
            troveManager.getCurrentICR(hintAddress, price)
        );
        latestRandomSeed = _inputRandomSeed;

        uint256 i = 1;

        while (i < _numTrials) {
            latestRandomSeed = uint256(
                keccak256(abi.encodePacked(latestRandomSeed))
            );

            uint256 arrayIndex = latestRandomSeed % arrayLength;
            address currentAddress = troveManager.getTroveFromTroveOwnersArray(
                arrayIndex
            );
            uint256 currentNICR = troveManager.getCurrentICR(
                currentAddress,
                price
            );

            // check if abs(current - CR) > abs(closest - CR), and update closest if current is closer
            uint256 currentDiff = ERDMath._getAbsoluteDifference(
                currentNICR,
                _CR
            );

            if (currentDiff < diff) {
                diff = currentDiff;
                hintAddress = currentAddress;
            }
            ++i;
        }
    }

    function computeCR(
        address[] memory _colls,
        uint256[] memory _amounts,
        uint256 _debt,
        uint256 _price
    ) external view returns (uint256) {
        (uint256 totalValue, ) = collateralManager.getValue(
            _colls,
            _amounts,
            _price
        );
        return ERDMath._computeCR(totalValue, _debt, _price);
    }

    function computeCR(
        uint256 _collValue,
        uint256 _debt
    ) external pure returns (uint256) {
        return ERDMath._computeCR(_collValue, _debt);
    }

    function _requireIsContract(address _contract) internal view {
        if (!_contract.isContract()) {
            revert Errors.NotContract();
        }
    }
}
