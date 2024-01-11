// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./InterfacesMigrated.sol";
import "./CelestialPortalMessages.sol";
import "./ICelestialCastle.sol";
import "./console.sol";

/**
 * @title Celestial Castle
 * @notice Edited from EtherOrcsOfficial/etherOrcs-contracts.
 */
contract CelestialCastleMainland is Initializable, UUPSUpgradeable, OwnableUpgradeable, IERC721ReceiverUpgradeable, ICelestialCastle {
	bool public isTravelEnabled;
	/// @notice CelestialPortalMainland contract.
	PortalLike public portalMainland;
	/// @notice Freaks N Guilds token contract.
	IFnGMig public freaksNGuilds;
	/// @notice Freaks bucks token contract.
	IFBX public freaksBucks;

	address public castleMainland;

	uint256 public assetLimit;

	address public hunting; 

	/// @notice Require that the sender is the portal for bridging operations.
	modifier onlyPortal() {
		require(msg.sender == address(portalMainland) || msg.sender == owner(), "CelestialCastle: sender is not the portal");
		_;
	}

	/// @notice Initialize the contract.
	function initialize(
		address newPortalMainland,
		address newFreaksNGuilds,
		address newFreaksBucks,
		bool newIsTravelEnabled,
		uint256 newAssetLimit
	) public initializer {
		__UUPSUpgradeable_init_unchained();
		__Ownable_init_unchained();

		portalMainland = PortalLike(newPortalMainland);
		freaksNGuilds = IFnGMig(newFreaksNGuilds);
		freaksBucks = IFBX(newFreaksBucks);
		isTravelEnabled = newIsTravelEnabled;
		assetLimit = newAssetLimit;
	}

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() initializer {}

	/// @notice Travel tokens to L2.
	function travel(
		uint256[] calldata freakIds,
		uint256[] calldata celestialIds,
		uint256 fbxAmount
	) external {
		require(isTravelEnabled, "CelestialCastle: travel is disabled");
		require(freakIds.length + celestialIds.length <= assetLimit, "CelestialCastle: Too many assets");
		_travel(freakIds, celestialIds, fbxAmount, msg.sender);
	}

	function travelFromHunting(
		uint256[] calldata freakIds,
		uint256[] calldata celestialIds,
		uint256 fbxAmount,
		address owner
	) external {
		require(isTravelEnabled, "CelestialCastle: travel is disabled");
		require(freakIds.length + celestialIds.length <= assetLimit, "CelestialCastle: Too many assets");
		require(msg.sender == hunting, "CelestialCastle: sender is not hunting");
		_travel(freakIds, celestialIds, fbxAmount, owner);
	}

	function _travel(
		uint256[] calldata freakIds,
		uint256[] calldata celestialIds,
		uint256 fbxAmount,
		address owner	
	) internal {
		bytes[] memory calls = new bytes[](
			(freakIds.length > 0 ? 1 : 0) + (celestialIds.length > 0 ? 1 : 0) + (fbxAmount > 0 ? 1 : 0)
		);
		uint256 callsIndex = 0;

		if (freakIds.length > 0) {
			calls[0] = initiateFreaksTravel(freakIds);
			callsIndex++;
		}

		if (celestialIds.length > 0) {
			calls[callsIndex] = initiateCelestialsTravel(celestialIds);
			callsIndex++;
		}

		if (fbxAmount > 0) {
			calls[callsIndex] = initiateFreaksBucksTravel(fbxAmount);
		}
		portalMainland.sendMessage(abi.encode(owner, calls));
	}

	function travelFreaks(uint256[] calldata freakIds) external {
		require(isTravelEnabled, "CelestialCastle: travel is disabled");
		bytes[] memory calls = new bytes[](1);
		calls[0] = initiateFreaksTravel(freakIds);
		portalMainland.sendMessage(abi.encode(calls));
	}

	function travelCelestials(uint256[] calldata celestialIds) external {
		require(isTravelEnabled, "CelestialCastle: travel is disabled");
		bytes[] memory calls = new bytes[](1);
		calls[0] = initiateCelestialsTravel(celestialIds);
		portalMainland.sendMessage(abi.encode(calls));
	}

	function travelFreaksBucks(uint256 fbxAmount) external {
		require(isTravelEnabled, "CelestialCastle: travel is disabled");
		bytes[] memory calls = new bytes[](1);
		calls[0] = initiateFreaksBucksTravel(fbxAmount);
		portalMainland.sendMessage(abi.encode(calls));
	}

	function initiateFreaksTravel(uint256[] calldata freakIds) internal returns (bytes memory) {
		Freak[] memory freaks = new Freak[](freakIds.length);
		for (uint256 i = 0; i < freakIds.length; i++) {
			require(freaksNGuilds.isFreak(freakIds[i]), "CelestialCastle: not a freak");
			freaks[i] = freaksNGuilds.getFreakAttributes(freakIds[i]);
			freaksNGuilds.transferFrom(msg.sender, address(this), freakIds[i]);
		}
		return abi.encode(CelestialPortalMessages.RETRIEVE_FREAKS, abi.encode(freakIds, freaks));
	}

	function initiateCelestialsTravel(uint256[] calldata celestialIds) internal returns (bytes memory) {
		CelestialV2[] memory celestials = new CelestialV2[](celestialIds.length);
		for (uint256 i = 0; i < celestialIds.length; i++) {
			require(!freaksNGuilds.isFreak(celestialIds[i]), "CelestialCastle: not a celestial");
			celestials[i] = freaksNGuilds.getCelestialAttributes(celestialIds[i]);
			freaksNGuilds.transferFrom(msg.sender, address(this), celestialIds[i]);
		}
		return abi.encode(CelestialPortalMessages.RETRIEVE_CELESTIALS, abi.encode(celestialIds, celestials));
	}

	function initiateFreaksBucksTravel(uint256 fbxAmount) internal returns (bytes memory) {
		freaksBucks.burn(msg.sender, fbxAmount);
		return abi.encode(CelestialPortalMessages.RETRIEVE_FBX, abi.encode(fbxAmount));
	}

	/// @notice Retrieve freaks from castle when bridging.
	function retrieveFreaks(
		address owner,
		uint256[] memory freakIds,
		Freak[] memory freakAttributes
	) external onlyPortal {
		for (uint256 i = 0; i < freakIds.length; i++) {
			// Use ERC721:ownerOf to check if the tokenId exists
			bytes memory payload = abi.encodeWithSignature("ownerOf(uint256)", freakIds[i]);
			(bool tokenExists, ) = address(freaksNGuilds).call(payload);
			if (tokenExists) {
				require(freaksNGuilds.isFreak(freakIds[i]), "This tokenId is a Celestial");
				freaksNGuilds.transferFrom(address(this), owner, freakIds[i]);
				freaksNGuilds.updateFreakAttributes(freakIds[i], freakAttributes[i]);
			} else {
				freaksNGuilds.mintFreak(owner, freakIds[i], freakAttributes[i]);
			}
		}
	}

	function retrieveCelestials(
		address owner,
		uint256[] memory celestialIds,
		CelestialV2[] memory celestialAttributes
	) external onlyPortal {
		for (uint256 i = 0; i < celestialIds.length; i++) {
			// Use ERC721:ownerOf to check if the tokenId exists
			bytes memory payload = abi.encodeWithSignature("ownerOf(uint256)", celestialIds[i]);
			(bool tokenExists, ) = address(freaksNGuilds).call(payload);
			if (tokenExists) {
				require(!freaksNGuilds.isFreak(celestialIds[i]), "This tokenId is a Freak");
				freaksNGuilds.transferFrom(address(this), owner, celestialIds[i]);
				freaksNGuilds.updateCelestialAttributes(celestialIds[i], celestialAttributes[i]);
			} else {
				freaksNGuilds.mintCelestial(owner, celestialIds[i], celestialAttributes[i]);
			}
		}
	}

	/// @notice Retrive freaks bucks to `owner` when bridging.
	function retrieveBucks(address owner, uint256 value) external onlyPortal {
		freaksBucks.mint(owner, value);
	}

	function setAssetLimit(uint256 newAssetLimit) external onlyOwner {
		assetLimit = newAssetLimit;
	}

	function setContracts(
		address newPortalMainland, 
		address newFreaksNGuilds, 
		address newFreaksBucks,
		address newHunting
	) external onlyOwner {
		portalMainland = PortalLike(newPortalMainland);
		freaksNGuilds = IFnGMig(newFreaksNGuilds);
		freaksBucks = IFBX(newFreaksBucks);
		hunting = newHunting;
	}

	function _authorizeUpgrade(address) internal onlyOwner override {}  


	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		return this.onERC721Received.selector;
	}

	function setIsTravelEnabled(bool newIsTravelEnabled) external onlyOwner {
		isTravelEnabled = newIsTravelEnabled;
	}

	/// @notice Withdraw `amount` of ether to msg.sender.
	function withdraw(uint256 amount) external onlyOwner {
		payable(msg.sender).transfer(amount);
	}

	/// @notice Withdraw `amount` of `token` to the sender.
	function withdrawERC20(IERC20Upgradeable token, uint256 amount) external onlyOwner {
		token.transfer(msg.sender, amount);
	}

	/// @notice Withdraw `tokenId` of `token` to the sender.
	function withdrawERC721(IERC721Upgradeable token, uint256 tokenId) external onlyOwner {
		token.safeTransferFrom(address(this), msg.sender, tokenId);
	}

	/// @notice Withdraw `tokenId` with amount of `value` from `token` to the sender.
	function withdrawERC1155(
		IERC1155Upgradeable token,
		uint256 tokenId,
		uint256 value
	) external onlyOwner {
		token.safeTransferFrom(address(this), msg.sender, tokenId, value, "");
	}
}
