// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EarnMetadataDescriptor.sol";
import "./OpenFundRedemptionDelegate.sol";
import "./OpenFundRedemptionConcrete.sol";

contract OpenFundRedemptionMetadataDescriptor is EarnMetadataDescriptor {
    
    using Strings for uint256;
    using Strings for address;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
    function _slotProperties(uint256 slot_) internal view virtual override returns (string memory) {
        OpenFundRedemptionDelegate delegate = OpenFundRedemptionDelegate(msg.sender);
        OpenFundRedemptionConcrete concrete = OpenFundRedemptionConcrete(delegate.concrete());
        OpenFundRedemptionConcrete.RedeemInfo memory redeemInfo = concrete.getRedeemInfo(slot_);
        
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        return 
            string(
                abi.encodePacked(
                    '[',
                        abi.encodePacked(
                            '{"name":"chain_id",',
                            '"description":"chain id",',
                            '"value":"', chainId.toString(), '",',
                            '"is_intrinsic":true,',
                            '"order":1,', 
                            '"display_type":"number"},'
                        ),
                        abi.encodePacked(
                            '{"name":"payable_token_address",',
                            '"description":"Address of this contract.",',
                            '"value":"', concrete.delegate().toHexString(), '",',
                            '"is_intrinsic":true,',
                            '"order":2,', 
                            '"display_type":"string"},'
                        ),
                        abi.encodePacked(
                            '{"name":"pool_id",',
                            '"description":"Pool ID in the Open-end Fund Market.",',
                            '"value":"', uint256(redeemInfo.poolId).toHexString(), '",',
                            '"is_intrinsic":true,',
                            '"order":3,', 
                            '"display_type":"string"},'
                        ),
                        abi.encodePacked(
                            '{"name":"currency",',
                            '"description":"Currency of this slot.",',
                            '"value":"', redeemInfo.currency.toHexString(), '",',
                            '"is_intrinsic":true,',
                            '"order":4,', 
                            '"display_type":"string"},'
                        ),
                        abi.encodePacked(
                            '{"name":"create_time",',
                            '"description":"Time when this slot is created.",',
                            '"value":"', redeemInfo.createTime.toString(), '",',
                            '"is_intrinsic":true,',
                            '"order":3,', 
                            '"display_type":"date"},'
                        ),
                        abi.encodePacked(
                            '{"name":"nav",',
                            '"description":"Settled nav of this slot.",',
                            '"value":"', redeemInfo.nav.toString(), '",',
                            '"is_intrinsic":false,',
                            '"display_type":"number"},'
                        ),
                    ']'
                )
            );
    }

    function _tokenProperties(uint256 tokenId_) internal view virtual override returns (string memory) {
        OpenFundRedemptionDelegate delegate = OpenFundRedemptionDelegate(msg.sender);
        OpenFundRedemptionConcrete concrete = OpenFundRedemptionConcrete(delegate.concrete());

        uint256 slot = delegate.slotOf(tokenId_);
        OpenFundRedemptionConcrete.RedeemInfo memory redeemInfo = concrete.getRedeemInfo(slot);

        return 
            string(
                abi.encodePacked(
                    /* solhint-disable */
                    '{"pool_id":"', uint256(redeemInfo.poolId).toHexString(),
                    '","currency":"', redeemInfo.currency.toHexString(),
                    '","create_time":"', redeemInfo.createTime.toString(),
                    '","nav":"', redeemInfo.nav.toString(),
                    '"}'
                    /* solhint-enable */
                )
            );
    }

}