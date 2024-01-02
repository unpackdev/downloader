// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EarnMetadataDescriptor.sol";

contract OpenFundShareMetadataDescriptor is EarnMetadataDescriptor {
    
    using Strings for uint256;
    using Strings for address;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
    function _formatSlotExtInfos(EarnConcrete concrete_, uint256 slot_) internal view virtual override returns (bytes memory) {
        EarnConcrete.SlotExtInfo memory extInfo = concrete_.slotExtInfo(slot_);
        uint256 slotTotalValue = concrete_.slotTotalValue(slot_);

        return 
            abi.encodePacked(
                abi.encodePacked(
                    '{"name":"supervisor",',
                    '"description":"Fund supervisor of this slot.",',
                    '"value":"', extInfo.supervisor.toHexString(), '",',
                    '"is_intrinsic":false,',
                    '"display_type":"string"},'
                ),
                abi.encodePacked(
                    '{"name":"interest_rate",',
                    '"description":"Interest rate of this slot.",',
                    '"value":', _formatInterestRate(extInfo.interestRate), ',',
                    '"is_intrinsic":false,',
                    '"display_type":"number"},'
                ),
                abi.encodePacked(
                    '{"name":"is_interest_rate_set",',
                    '"description":"Indicate if the interest rate of this slot is set.",',
                    '"value":', extInfo.isInterestRateSet ? 'true' : 'false', ',',
                    '"is_intrinsic":false,',
                    '"display_type":"boolean"},'
                ),
                abi.encodePacked(
                    '{"name":"total_value",',
                    '"description":"Total issued value of this slot.",',
                    '"value":', slotTotalValue.toString(), ',',
                    '"is_intrinsic":false,',
                    '"display_type":"number"},'
                ),
                abi.encodePacked(
                    '{"name":"external_url",',
                    '"description":"External URI of this slot.",',
                    '"value":"', extInfo.externalURI, '",',
                    '"is_intrinsic":false,',
                    '"display_type":"string"}'
                )
            );
    }

    function _tokenProperties(uint256 tokenId_) internal view virtual override returns (string memory) {
        EarnDelegate delegate = EarnDelegate(msg.sender);
        EarnConcrete concrete = EarnConcrete(delegate.concrete());

        uint256 slot = delegate.slotOf(tokenId_);
        EarnConcrete.SlotBaseInfo memory baseInfo = concrete.slotBaseInfo(slot);
        EarnConcrete.SlotExtInfo memory extInfo = concrete.slotExtInfo(slot);

        return 
            string(
                abi.encodePacked(
                    /* solhint-disable */
                    '{"issuer":"', baseInfo.issuer.toHexString(),
                    '","supervisor":"', extInfo.supervisor.toHexString(),
                    '","currency":"', baseInfo.currency.toHexString(),
                    '"}'
                    /* solhint-enable */
                )
            );
    }

}