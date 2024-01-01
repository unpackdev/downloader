// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./D4AErrors.sol";
import "./ProtocolStorage.sol";
import "./DaoStorage.sol";
import "./SettingsStorage.sol";

abstract contract ProtocolChecker {
    function _checkPauseStatus() internal view {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (l.isProtocolPaused) {
            revert D4APaused();
        }
    }

    function _checkPauseStatus(bytes32 id) internal view {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (l.pauseStatuses[id]) {
            revert Paused(id);
        }
    }

    function _checkUriExist(string calldata uri) internal view {
        if (!_uriExist(uri)) {
            revert UriNotExist(uri);
        }
    }

    function _checkUriNotExist(string memory uri) internal view {
        if (_uriExist(uri)) {
            revert UriAlreadyExist(uri);
        }
    }

    function _checkCaller(address caller) internal view {
        if (caller != msg.sender) {
            revert NotCaller(caller);
        }
    }

    function _uriExist(string memory uri) internal view returns (bool) {
        return ProtocolStorage.layout().uriExists[keccak256(abi.encodePacked(uri))];
    }

    function _checkDaoExist(bytes32 daoId) internal view {
        if (!DaoStorage.layout().daoInfos[daoId].daoExist) revert DaoNotExist();
    }
}
