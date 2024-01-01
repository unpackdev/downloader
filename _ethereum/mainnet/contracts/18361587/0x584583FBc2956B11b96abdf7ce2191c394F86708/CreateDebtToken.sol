// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./VariableDebtToken.sol";
import "./StableDebtToken.sol";
import "./IKyokoPoolAddressesProvider.sol";
import "./ICreateDebtToken.sol";

contract CreateDebtToken is ICreateDebtToken {
    function createVariableDebtToken(
        address _weth,
        address _provider,
        uint256 _reserveId,
        string memory symbol,
        string memory s1,
        string memory s2
    ) external override returns (address variableAddress) {
        address weth = _weth;
        IKyokoPoolAddressesProvider provider = IKyokoPoolAddressesProvider(_provider);
        uint256 reserveId = _reserveId;
        string memory s3 = "Kyoko variable bearing ";
        string memory s4 = "kVariable";
        string memory hVariableName = string(abi.encodePacked(s3, symbol, s1, s2));
        string memory hVariableSymbol = string(abi.encodePacked(s4, symbol, s2));
        VariableDebtToken variableDebtToken = new VariableDebtToken(provider, reserveId, weth, 18, hVariableName, hVariableSymbol);
        variableAddress = address(variableDebtToken);

        emit CreateVariableToken(msg.sender, variableAddress);
    }

    function createStableDebtToken(
        address _weth,
        address _provider,
        uint256 _reserveId,
        string memory symbol,
        string memory s1,
        string memory s2
    ) external override returns (address stableAddress) {
        address weth = _weth;
        IKyokoPoolAddressesProvider provider = IKyokoPoolAddressesProvider(_provider);
        uint256 reserveId = _reserveId;
        string memory s3 = "Kyoko stable bearing ";
        string memory s4 = "kStable";
        string memory hStableName = string(abi.encodePacked(s3, symbol, s1, s2));
        string memory hStableSymbol = string(abi.encodePacked(s4, symbol, s2));
        StableDebtToken stableDebtToken = new StableDebtToken(provider, reserveId, weth, 18, hStableName, hStableSymbol);
        stableAddress = address(stableDebtToken);
        
        emit CreateStableToken(msg.sender, stableAddress);
    }
}