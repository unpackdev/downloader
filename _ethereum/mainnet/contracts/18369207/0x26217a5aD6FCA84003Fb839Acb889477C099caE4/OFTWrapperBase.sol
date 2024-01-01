// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import "./SolidStateDiamond.sol";
import "./IPausable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ITokenBalance.sol";
import "./OFTWrapperStorage.sol";
import '../../helpers/TransferHelper.sol' as TransferHelper;
import '../../Constants.sol' as Constants;

/**
 * @title OFTWrapperBase
 * @notice The OFT wrapper base contract
 */
abstract contract OFTWrapperBase is SolidStateDiamond, Pausable, ReentrancyGuard {
    /**
     * @notice Emitted when the address of the fee collector is set
     * @param feeCollector The address of the fee collector
     */
    event SetFeeCollector(address indexed feeCollector);

    uint256 private constant SYSTEM_VERSION_ID_VALUE = uint256(keccak256('Initial'));

    /**
     * @notice Initializes the OFTWrapperBase contract
     * @param _feeCollector The initial address of the fee collector
     */
    constructor(address _feeCollector) {
        _initOFTWrapperBaseDiamond();

        _setFeeCollector(_feeCollector);
    }

    /**
     * @notice Sets the address of the fee collector
     * @param _feeCollector The address of the fee collector
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    /**
     * @notice Enter pause state
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Exit pause state
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Transfers ownership of the contract to a new account
     * @dev Can only be called by the current owner
     * @param _newOwner The address of the contract owner
     */
    function forceTransferOwnership(address _newOwner) external onlyOwner {
        _setOwner(_newOwner);
    }

    /**
     * @notice Performs the withdrawal of tokens, except for reserved ones
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @param _tokenAmount The amount of the token
     */
    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    /**
     * @notice Getter of the token balance of the current contract
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @return The token balance of the current contract
     */
    function tokenBalance(address _tokenAddress) external view returns (uint256) {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    /**
     * @notice Getter of the address of the fee collector
     * @return The address of the fee collector
     */
    function feeCollector() external view returns (address) {
        return OFTWrapperStorage.layout().feeCollector;
    }

    /**
     * @notice Getter of the system version identifier
     * @return The system version identifier
     */
    function SYSTEM_VERSION_ID() external pure returns (uint256) {
        return SYSTEM_VERSION_ID_VALUE;
    }

    function _setFeeCollector(address _feeCollector) private {
        OFTWrapperStorage.layout().feeCollector = _feeCollector;

        emit SetFeeCollector(_feeCollector);
    }

    function _initOFTWrapperBaseDiamond() private {
        bytes4[] memory selectors = new bytes4[](9);
        uint256 selectorIndex;

        // register Pausable

        selectors[selectorIndex++] = IPausable.paused.selector;

        _setSupportsInterface(type(IPausable).interfaceId, true);

        // register fee collector functions

        selectors[selectorIndex++] = OFTWrapperBase.setFeeCollector.selector;
        selectors[selectorIndex++] = OFTWrapperBase.feeCollector.selector;

        // register service functions

        selectors[selectorIndex++] = OFTWrapperBase.pause.selector;
        selectors[selectorIndex++] = OFTWrapperBase.unpause.selector;
        selectors[selectorIndex++] = OFTWrapperBase.forceTransferOwnership.selector;
        selectors[selectorIndex++] = OFTWrapperBase.cleanup.selector;
        selectors[selectorIndex++] = OFTWrapperBase.tokenBalance.selector;
        selectors[selectorIndex++] = OFTWrapperBase.SYSTEM_VERSION_ID.selector;

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({
            target: address(this),
            action: FacetCutAction.ADD,
            selectors: selectors
        });

        _diamondCut(facetCuts, address(0), '');
    }
}
