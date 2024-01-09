//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./IEthAddressWhitelist.sol";

contract EthAddressWhitelistFactory {

    event EthAddressWhitelistCloneDeployed(address indexed cloneAddress);

    address public referenceEthAddressWhitelist;
    address public cloner;

    constructor(address _referenceOpenEdition) {
      require(_referenceOpenEdition != address(0), "_referenceOpenEdition can't be zero address");
      referenceEthAddressWhitelist = _referenceOpenEdition;
    }

    function newEthAddressWhitelist(
        address _owner,
        address[] memory _whitelisters
    ) external returns (address) {
        address newEthAddressWhitelistAddress = Clones.clone(referenceEthAddressWhitelist);
        IEthAddressWhitelist ethAddressWhitelist = IEthAddressWhitelist(newEthAddressWhitelistAddress);
        ethAddressWhitelist.initialize(
          _owner,
          _whitelisters
        );
        emit EthAddressWhitelistCloneDeployed(newEthAddressWhitelistAddress);
        return newEthAddressWhitelistAddress;
    }

}