// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./LibAppStorage.sol";
import "./GToken.sol";
import "./IERC20Extras.sol";

contract GTokenFactoryFacet is Modifiers {
    event GTokenDeployed(address GToken, address SPToken);

    /// @dev calling this function externally in the protocol registry contract for the deployment of sythetic Gov Token
    /// @param _spToken the token being approved as an VIP token
    /// @dev for default approval of synthetic tokens for burning on the time of payback and liqudiation of collaterals
    function deployGToken(address _spToken) external returns (address _gToken) {
        require(
            msg.sender == address(this),
            "Only Protocol Registry Can Deploy"
        );
        IERC20Extras spToken = IERC20Extras(_spToken);
        string memory gTokenName = string(
            abi.encodePacked("gov", spToken.name())
        );
        string memory gTokenSymbol = string(
            abi.encodePacked("gov", spToken.symbol())
        );
        _gToken = address(
            new GToken(gTokenName, gTokenSymbol, _spToken, address(this))
        );
        GToken(_gToken).transferOwnership(address(this));

        emit GTokenDeployed(_gToken, _spToken);
        return _gToken;
    }
}
