// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuardUpgradeable.sol";
import "./ERC3525SlotEnumerableUpgradeable.sol";
import "./ISFTConcreteControl.sol";
import "./SFTDelegateControl.sol";
import "./OwnControl.sol";
import "./Constants.sol";
import "./IBaseSFTDelegate.sol";
import "./IBaseSFTConcrete.sol";

abstract contract BaseSFTDelegateUpgradeable is IBaseSFTDelegate, ERC3525SlotEnumerableUpgradeable, 
	OwnControl, SFTDelegateControl, ReentrancyGuardUpgradeable {

	event CreateSlot(uint256 indexed _slot, address indexed _creator, bytes _slotInfo);
	event MintValue(uint256 indexed _tokenId, uint256 indexed _slot, uint256 _value);

	function __BaseSFTDelegate_init(
		string memory name_, string memory symbol_, uint8 decimals_, 
		address concrete_, address metadata_, address owner_
	) internal onlyInitializing {
		ERC3525Upgradeable.__ERC3525_init(name_, symbol_, decimals_);
		OwnControl.__OwnControl_init(owner_);
		ERC3525Upgradeable._setMetadataDescriptor(metadata_);

		SFTDelegateControl.__SFTDelegateControl_init(concrete_);
		__ReentrancyGuard_init();

		//address of concrete must be zero when initializing impletion contract avoid failed after upgrade
		if (concrete_ != Constants.ZERO_ADDRESS) {
			ISFTConcreteControl(concrete_).setDelegate(address(this));
		}
	}

	function delegateToConcreteView(bytes calldata data) external view override returns (bytes memory) {
		(bool success, bytes memory returnData) = concrete().staticcall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
	}

	function contractType() external view virtual returns (string memory);

	uint256[50] private __gap;
}
