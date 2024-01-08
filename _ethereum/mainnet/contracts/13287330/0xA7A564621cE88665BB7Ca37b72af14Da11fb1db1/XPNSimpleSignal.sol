// Copyright (C) 2021 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;

import "./ISignal.sol";
import "./Ownable.sol";

contract XPNSignal is ISignal, Ownable {
    struct signalMetaData {
        string signalType;
        bool signalExist;
        bool signalActive;
    }
    mapping(address => mapping(string => bool)) ownSignals;
    mapping(string => int256[]) signalsWeight;
    mapping(string => string[]) signalsSymbol;
    mapping(string => signalMetaData) signalsMetaData;
    mapping(address => bool) signalProviderWhitelist;

    address[] assetAddress;
    event SignalProviderWhitelisted(address wallet);
    event SignalProviderDeWhitelisted(address wallet);

    constructor() {
        whitelistsignalProvider(msg.sender);
    }

    // @notice register a new signal. caller will own the signal
    // @param signalName unique identifier of the signal.
    // @param signalType general info about the signal.
    // @param symbols list of symbol that this signal will address. order sensitive. immutable
    function registerSignal(
        string memory signalName,
        string memory signalType,
        string[] memory symbols
    ) external override returns (string memory) {
        require(
            _signalProviderIsWhitelisted(msg.sender),
            "Wallet is not whitelisted"
        );

        if (signalsMetaData[signalName].signalExist) {
            revert("signal already exist");
        }

        ownSignals[msg.sender][signalName] = true;
        signalsMetaData[signalName] = signalMetaData({
            signalType: signalType,
            signalExist: true,
            signalActive: false
        });
        signalsSymbol[signalName] = symbols;
    }

    // @notice whitelist wallet by address
    // @param address of the wallet to whitelist
    // @dev only callable by owner
    function whitelistsignalProvider(address wallet) public onlyOwner {
        signalProviderWhitelist[wallet] = true;
        emit SignalProviderWhitelisted(wallet);
    }

    // @notice un-whitelist wallet by address
    // @param address of the wallet to un-whitelist
    // @dev only callable by owner
    function deWhitelistsignalProvider(address wallet) public onlyOwner {
        signalProviderWhitelist[wallet] = false;
        emit SignalProviderDeWhitelisted(wallet);
    }

    function _signalProviderIsWhitelisted(address wallet)
        private
        view
        returns (bool)
    {
        return signalProviderWhitelist[wallet];
    }

    // @notice make a signal inactive
    // @dev caller must be signal owner
    function withdrawSignal(string memory signalName) external override {
        require(ownSignals[msg.sender][signalName], "not your signal");
        signalsMetaData[signalName].signalActive = false;
    }

    // @notice signal weight setter. just store signal weight as signal.
    // @dev some of the param are just from ISignal, not really in use.
    // @param signalName unique identifier of signal
    // @param ref not in use.
    // @param weights of each asset.
    // @param data not in use.
    function submitSignal(
        string memory signalName,
        string[] memory ref,
        int256[] memory weights,
        bytes calldata data
    ) external override {
        require(ownSignals[msg.sender][signalName], "not your signal");
        require(
            weights.length == signalsSymbol[signalName].length,
            "signal length mismatch"
        );
        signalsWeight[signalName] = weights;
        signalsMetaData[signalName].signalActive = true;
    }

    // @notice do nothing. this function is from ISignal.
    function updateSignal(string memory signalName) external override {
        revert("this signal do not require any update");
    }

    // @notice get symbol list of the signal
    // @param signalName unique identifier of signal
    // @return string[] list of symbol
    function getSignalSymbols(string memory signalName)
        external
        view
        override
        returns (string[] memory)
    {
        require(
            signalsMetaData[signalName].signalActive,
            "signal not available"
        );
        return signalsSymbol[signalName];
    }

    // @notice get symbol list of the signal
    // @param signalName unique identifier of signal
    // @return int256[] signal, % target allocation between each symbols.
    function getSignal(string memory signalName)
        external
        view
        override
        returns (int256[] memory)
    {
        require(
            signalsMetaData[signalName].signalActive,
            "signal not available"
        );

        return signalsWeight[signalName];
    }
}
