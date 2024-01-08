// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IChangeableVariables {
    event AddressChanged(string indexed fieldName, address previousAddress, address newAddress);
    event ValueChanged(string indexed fieldName, uint previousValue, uint newValue);
    event BoolValueChanged(string indexed fieldName, bool previousValue, bool newValue);
}