// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EarnDelegate.sol";
import "./SFTValueIssuableDelegate.sol";
import "./IOpenFundShareDelegate.sol";
import "./IOpenFundShareConcrete.sol";

contract OpenFundShareDelegate is IOpenFundShareDelegate, EarnDelegate, SFTValueIssuableDelegate {

	bytes32 internal constant CONTRACT_OPEN_FUND_MARKET = "OpenFundMarket"; 

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }

	function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525SlotEnumerableUpgradeable, EarnDelegate) {
        EarnDelegate._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

	function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory addressNames) {
		addressNames = new bytes32[](1);
		addressNames[0] = CONTRACT_OPEN_FUND_MARKET;
	}

	function _issueMarket() internal view virtual override returns (address) {
		return getRequiredAddress(CONTRACT_OPEN_FUND_MARKET, "OFSD: Market not set");
	}

	function contractType() external view virtual override(BaseSFTDelegateUpgradeable, EarnDelegate) returns (string memory) {
        return "Open Fund Shares";
    }
}