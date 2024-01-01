// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./KToken.sol";
import "./IKyokoPoolAddressesProvider.sol";
import "./ICreateKToken.sol";
import "./IKToken.sol";

contract CreateKToken is ICreateKToken {
    function createKToken(
        address _weth,
        address _provider,
        address _treasury,
        uint256 _reserveId,
        string memory symbol,
        string memory s1,
        string memory s2
    ) external override returns (address kTokenAddress) {
        address weth = _weth;
        IKyokoPoolAddressesProvider provider = IKyokoPoolAddressesProvider(_provider);
        address treasury = _treasury;
        uint256 reserveId = _reserveId;
        string memory s3 = "Kyoko interest bearing ";
        string memory s4 = "k";
        string memory kTokenName = string(abi.encodePacked(s3, symbol, s1, s2));
        string memory kTokenSymbol = string(abi.encodePacked(s4, symbol, s2));
        KToken kToken = new KToken(provider, reserveId, treasury, weth, 18, kTokenName, kTokenSymbol);
        kTokenAddress = address(kToken);
        emit CreateKToken(msg.sender, kTokenAddress);
    }
}