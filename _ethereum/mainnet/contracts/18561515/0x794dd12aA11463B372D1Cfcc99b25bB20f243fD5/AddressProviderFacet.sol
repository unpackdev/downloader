// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./LibAppStorage.sol";

contract AddressProviderFacet is Modifiers {
    event UpdateGovToken(address indexed _govToken);
    event UpdateGovGovToken(address indexed _govGovToken);

    /// @dev function to set gov token address
    /// @param _govToken contract address of the gov token
    function setGovToken(address _govToken) external onlyOwner {
        AppStorage storage s = LibAppStorage.appStorage();

        require(_govToken != address(0), "zero address");
        s.govToken = _govToken;
        emit UpdateGovToken(_govToken);
    }

    /// @dev function to set govGovToken address
    /// @param _govGovToken gov synthetic token address
    function setgovGovToken(address _govGovToken) external onlyOwner {
        AppStorage storage s = LibAppStorage.appStorage();

        require(_govGovToken != address(0), "zero address");
        s.govGovToken = _govGovToken;
        emit UpdateGovGovToken(_govGovToken);
    }
}
