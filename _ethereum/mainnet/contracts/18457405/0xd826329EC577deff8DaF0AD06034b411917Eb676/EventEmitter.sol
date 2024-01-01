// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IAaveOracle.sol";
import "./IAToken.sol";
import "./IChainlinkAggregator.sol";
import "./IERC20Metadata.sol";
import "./IMintableToken.sol";

contract EventEmitter is Initializable, OwnableUpgradeable {
	uint8 public constant DECIMALS = 18;

	// AAVE Oracle address
	address public aaveOracle;

	// MFD contract, who will be utilizing this contract
	address public mfd;

	// RDNT token
	IMintableToken public rdntToken;

	event NewTransferAdded(address indexed asset, uint256 lpUsdValue);

	error ZeroAddress();

	error CallerNotMFD();

	function initialize(IMintableToken _rdntToken, address _aaveOracle, address _mfd) public initializer {
		if (_aaveOracle == address(0)) revert ZeroAddress();
		if (address(_rdntToken) == address(0)) revert ZeroAddress();
		if (address(_mfd) == address(0)) revert ZeroAddress();

		__Ownable_init();

		rdntToken = _rdntToken;
		aaveOracle = _aaveOracle;
		mfd = _mfd;
	}

	/**
	 * @notice Emit event for new asset reward
	 * @param asset address of transfer assset
	 * @param lpReward amount of rewards
	 */
	function emitNewTransferAdded(address asset, uint256 lpReward) external {
		if (msg.sender != mfd) revert CallerNotMFD();
		uint256 lpUsdValue;
		if (asset != address(rdntToken)) {
			address assetAddress;

			try IAToken(asset).UNDERLYING_ASSET_ADDRESS() returns (address underlyingAddress) {
				assetAddress = underlyingAddress;
			} catch {
				assetAddress = asset;
			}

			uint256 assetPrice = IAaveOracle(aaveOracle).getAssetPrice(assetAddress);
			address sourceOfAsset = IAaveOracle(aaveOracle).getSourceOfAsset(assetAddress);

			uint8 priceDecimals;
			try IChainlinkAggregator(sourceOfAsset).decimals() returns (uint8 decimals) {
				priceDecimals = decimals;
			} catch {
				priceDecimals = 8;
			}

			// note using original asset arg here, so it uses the rToken
			uint8 assetDecimals = IERC20Metadata(asset).decimals();
			lpUsdValue = (assetPrice * lpReward * (10 ** DECIMALS)) / (10 ** priceDecimals) / (10 ** assetDecimals);
			emit NewTransferAdded(asset, lpUsdValue);
		}
	}
}
