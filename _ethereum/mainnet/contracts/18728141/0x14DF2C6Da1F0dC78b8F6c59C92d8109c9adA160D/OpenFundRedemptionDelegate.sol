// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FCFSMultiRepayableDelegate.sol";
import "./SFTValueIssuableDelegate.sol";
import "./IOpenFundRedemptionDelegate.sol";
import "./IOpenFundRedemptionConcrete.sol";

contract OpenFundRedemptionDelegate is IOpenFundRedemptionDelegate, SFTValueIssuableDelegate, FCFSMultiRepayableDelegate {

	bytes32 internal constant CONTRACT_OPEN_FUND_MARKET = "OpenFundMarket"; 

    bool private __allowRepayWithBalance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
	function initialize(
        address resolver_, string calldata name_, string calldata symbol_, uint8 decimals_, 
		address concrete_, address descriptor_, address owner_, bool allowRepayWithBalance_
    ) external initializer {
		__SFTIssuableDelegate_init(resolver_, name_, symbol_, decimals_, concrete_, descriptor_, owner_);
        __allowRepayWithBalance = allowRepayWithBalance_;
	}

	function setRedeemNavOnlyMarket(uint256 slot_, uint256 nav_) external virtual override {
		require(_msgSender() == _issueMarket(), "OFRD: only market");
		IOpenFundRedemptionConcrete(concrete()).setRedeemNavOnlyDelegate(slot_, nav_);
	}

    function allowRepayWithBalance() public view virtual override returns (bool) {
        return __allowRepayWithBalance;
    }

	function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525SlotEnumerableUpgradeable, FCFSMultiRepayableDelegate) {
        FCFSMultiRepayableDelegate._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

	function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory addressNames) {
		addressNames = new bytes32[](1);
		addressNames[0] = CONTRACT_OPEN_FUND_MARKET;
	}

	function _issueMarket() internal view virtual override returns (address) {
		return getRequiredAddress(CONTRACT_OPEN_FUND_MARKET, "OFRD: OpenFundMarket not set");
	}

	function contractType() external view virtual override returns (string memory) {
        return "Open Fund Redemptions";
    }
}