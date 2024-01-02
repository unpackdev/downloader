// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ReentrancyGuard.sol";
import "./Pausable.sol";

import "./IBridge.sol";
import "./IERC20Burnable.sol";
import "./IERC1155Burnable.sol";
import "./LzApp.sol";

/**
 * @title MainnetSWPR Swapper contract for converting Pixel Vault assets into new GGT token
 *
 * @author Niftydude, Jack Chuma
 *
 * @notice Lock POW, PUNKS and / or PLANETS to redeem GG tokens or Reboot Credits on L2.
 */
contract MainnetSWPR is IBridge, LzApp, ReentrancyGuard, Pausable {
    // POW token contract address
    IERC20Burnable public POW;

    // PUNKS token contract address
    IERC20Burnable public PUNKS;

    // PLANETS token contract address
    IERC1155Burnable public PLANETS;

    // PixelVault treasury address
    address public treasury;

    constructor(
        address _powToken,
        address _punksToken,
        address _planetTokens,
        address _treasury,
        address _endpoint,
        address _admin
    ) LzApp(_admin) {
        if (
            _powToken == address(0) ||
            _punksToken == address(0) ||
            _planetTokens == address(0) ||
            _treasury == address(0) ||
            _endpoint == address(0)
        ) revert ZeroAddress();
        POW = IERC20Burnable(_powToken);
        PUNKS = IERC20Burnable(_punksToken);
        PLANETS = IERC1155Burnable(_planetTokens);
        treasury = _treasury;

        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    /**
     * @notice Admin function to set the stored treasury address
     *
     * @param _treasury PixelVault Treasury address
     */
    function setTreasury(address _treasury) external onlyRole(ADMIN_ROLE) {
        if (_treasury == address(0)) revert ZeroAddress();
        treasury = _treasury;
        emit TreasurySet(_treasury);
    }

    /**
     * @notice Admin function to pause / unpause contract functionality
     */
    function togglePause() external onlyRole(ADMIN_ROLE) {
        if (paused()) _unpause();
        else _pause();
    }

    /**
     * @notice Returns the LayerZero fee estimate for a bridge transaction
     *
     * @param _claim Claim structure containing POW / Punks / Planet amounts
     * @param _gasForDestinationLzReceive Amount of Gas units to reserve for the L2 tx
     * @param _l2ChainId Chain ID of the destination Blockchain
     */
    function estimateFees(
        Claim calldata _claim,
        uint256 _gasForDestinationLzReceive,
        uint16 _l2ChainId
    ) external view returns (uint256 messageFee) {
        (
            bytes memory _payload,
            bytes memory _adapterParams
        ) = _getPayloadAndParams(_claim, _gasForDestinationLzReceive);

        (messageFee, ) = lzEndpoint.estimateFees(
            _l2ChainId,
            address(this),
            _payload,
            false,
            _adapterParams
        );
    }

    /**
     * @notice Lock POW, PUNKS and PLANETS to redeem GGT tokens or Reboot Credits on L2.
     *
     * @param _claim Claim data structure
     * @param _gasForDestinationLzReceive Amount of Gas units to reserve for the L2 tx
     * @param _l2ChainId Chain ID of the destination Blockchain
     */
    function bridgeAndSwap(
        Claim calldata _claim,
        uint256 _gasForDestinationLzReceive,
        uint16 _l2ChainId
    ) external payable nonReentrant whenNotPaused {
        if (_claim.planetAmounts.length != _claim.planetIds.length)
            revert InvalidPlanetsArray();

        _lockTokens(_claim);

        (
            bytes memory _payload,
            bytes memory _adapterParams
        ) = _getPayloadAndParams(_claim, _gasForDestinationLzReceive);

        _lzSend(
            _l2ChainId,
            _payload,
            payable(msg.sender),
            address(0x0),
            _adapterParams,
            msg.value
        );

        uint256 _nonce = lzEndpoint.getOutboundNonce(_l2ChainId, address(this));

        emit Bridged(_nonce, _l2ChainId, msg.sender, _claim);
    }

    /**
     * @dev Function override required by solidity
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, IERC165) returns (bool) {
        return
            interfaceId == type(ILayerZeroReceiver).interfaceId ||
            interfaceId == type(ILayerZeroUserApplicationConfig).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _getPayloadAndParams(
        Claim calldata _claim,
        uint256 _gasForDestinationLzReceive
    ) private view returns (bytes memory, bytes memory) {
        bytes memory _payload = abi.encode(msg.sender, _claim);
        bytes memory _adapterParams = abi.encodePacked(
            uint16(1),
            _gasForDestinationLzReceive
        );
        return (_payload, _adapterParams);
    }

    function _lockTokens(Claim calldata _claim) private {
        if (
            _claim.powAmount == 0 &&
            _claim.punksAmount == 0 &&
            _claim.planetAmounts.length == 0
        ) revert ZeroTokens();

        if (_claim.powAmount > 0) {
            POW.burnFrom(msg.sender, _claim.powAmount);
        }

        if (_claim.punksAmount > 0) {
            PUNKS.transferFrom(msg.sender, treasury, _claim.punksAmount);
        }

        if (_claim.planetAmounts.length != 0) {
            PLANETS.burnBatch(
                msg.sender,
                _claim.planetIds,
                _claim.planetAmounts
            );
        }
    }
}
