// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Mixer.sol";
import "./Wallet.sol";

contract Proxy {
    event Created(address newMixer, address recipient, uint divRate, uint delayTime, uint srcChainId, uint dscChainId);

    function createMixer(
        address _recipient,
        uint _divRate,
        uint _delayTime,
        uint _srcChainId,
        uint _dscChainId
    ) public {
        address walletA = address(new Wallet(_recipient, _dscChainId));
        address walletB = address(new Wallet(_recipient, _dscChainId));
        address newMixer = address(new Mixer(walletA, walletB, _divRate, _delayTime));

        emit Created(newMixer, _recipient, _divRate, _delayTime, _srcChainId, _dscChainId);
    }
}
