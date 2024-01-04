pragma solidity 0.6.12;

import "./Ownable.sol";
import "./MasterCaller.sol";
import "./ERC1967Proxy.sol";
import "./GatlingStorage.sol";



contract StakeGatlingProxy is GatlingStorage, Ownable, MasterCaller, ERC1967Proxy {

    constructor (address _pair, address _delegate) ERC1967Proxy(_delegate, '')  public {
        stakeLpPair = _pair;
        createAt = now;
    }
}