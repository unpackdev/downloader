pragma solidity ^0.7.4;pragma experimental ABIEncoderV2;

import "./ForwardingResolver.sol";
import "./StealthKeyResolver.sol";

contract ForwardingStealthKeyResolver is ForwardingResolver, StealthKeyResolver {

    constructor(ENS _ens, PublicResolver _fallbackResolver) ForwardingResolver(_ens, _fallbackResolver) { }

    function supportsInterface(bytes4 interfaceID) public virtual override(PublicResolver, StealthKeyResolver) pure returns(bool) {
        return StealthKeyResolver.supportsInterface(interfaceID);
    }
}
