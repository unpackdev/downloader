//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./ConfigurableOracleMock.sol";

contract ConfigurableOracleMockFactory is AccessControl {
    struct TokenOracles {
        string tokenSymbol;
        address oracle;
        uint256 indexInArray;
    }
    mapping(string => TokenOracles) public tokenOracles;
    string[] public symbolsList;
    uint256 public index;

    event MockedOracleDeployed(address indexed newOracle);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        index = 0;
    }

    function deployOracleMock(string memory tokenSymbol_) external returns (address) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DCO not authorized");

        ConfigurableOracleMock configurableOracleMock = new ConfigurableOracleMock(tokenSymbol_);
        tokenOracles[tokenSymbol_].tokenSymbol = tokenSymbol_;
        tokenOracles[tokenSymbol_].oracle = address(configurableOracleMock);
        tokenOracles[tokenSymbol_].indexInArray = index;

        configurableOracleMock.grantRole(configurableOracleMock.DEFAULT_ADMIN_ROLE(), _msgSender());

        emit MockedOracleDeployed(address(configurableOracleMock));

        symbolsList.push(tokenSymbol_);
        index++;

        return address(configurableOracleMock);
    }

    function getSymbols() external view returns (string[] memory) {
        return symbolsList;
    }

    function getOracleData(string memory tokenSymbol_)
        external
        view
        returns (
            string memory,
            address,
            uint256
        )
    {
        return (
            tokenOracles[tokenSymbol_].tokenSymbol,
            tokenOracles[tokenSymbol_].oracle,
            tokenOracles[tokenSymbol_].indexInArray
        );
    }

    function deleteOracleReference(string memory tokenSymbol_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DOR not authorized");
        require(tokenOracles[tokenSymbol_].oracle != address(0), "DOR inexistent oracle");

        symbolsList[tokenOracles[tokenSymbol_].indexInArray] = "";
        delete tokenOracles[tokenSymbol_];
    }
}
