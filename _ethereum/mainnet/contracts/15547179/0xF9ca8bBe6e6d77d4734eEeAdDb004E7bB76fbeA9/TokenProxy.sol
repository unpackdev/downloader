pragma solidity 0.4.24;

import "./Proxy.sol";
import "./IBridgeMediator.sol";
/**
* @title TokenProxy
* @dev Helps to reduces the size of the deployed bytecode for automatically created tokens, by using a proxy contract.
*/

contract TokenProxy is Proxy {
    bytes4 internal constant INITIALIZE = 0x1624f6c6; // bytes4(keccak256("initialize(string,string,uint8)"))

    /**
    * @dev Creates an upgradeable token proxy for PermittableToken.sol, initializes its storage by using delegatecall
    * @param _name token name.
    * @param _symbol token symbol.
    */
    constructor(address _tokenImage, string _name, string _symbol, uint8 _decimals) public {
        bool result = _tokenImage.delegatecall(abi.encodeWithSelector(INITIALIZE, _name, _symbol, _decimals));
        require(result, "failed to initialize token storage");
    }

    /**
    * @dev Retrieves the implementation contract address, mirrored token image.
    * @return token image address.
    */
    function implementation() public view returns (address) {
        return IBridgeMediator(bridgeContractAddr()).tokenImage();
    }

    function bridgeContractAddr() public view returns (address _bridgeContractAddr) {
        // The bridge contract is stored at address slot 7. It needs to be read from the storage because it's initialized
        // by the initialize function using delegatecall in the constructor.

        // It has to be stored in slot 7 to maintain compatibility with legacy bridged tokens on-chain.
        // Ideally it would be stored at a slot like keccak256("bridgeContractAddr"), which could
        // still work for newly deployed proxies but would leave the possibility of old proxies
        // getting out of sync, so this compromise was chosen to minimise complexity and keep the
        // bridge contract address stored in a single known slot.

        // The population of slot 7 is tested explicitly in bridged_tokens.test.js
        assembly {
            _bridgeContractAddr := sload(0x07)
        }
    }

}
