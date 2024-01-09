// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./Cryptomedia.sol";
import "./Clones.sol";

/**
 * @title Cryptomedia Factory
 * @author neuroswish
 *
 * Factory for deploying cryptomedia
 *
 * Good morning
 * Look at the valedictorian
 * Scared of the future while I hop in the DeLorean
 *
 */

contract CryptomediaFactory {
    // ======== Storage ========
    address public logic;
    address public bondingCurve;

    // ======== Events ========
    event CryptomediaDeployed(
        address contractAddress,
        address indexed creator,
        string metadataURI,
        string name,
        string symbol,
        uint256 reservedTokens,
        address bondingCurve
    );

    // ======== Constructor ========
    constructor(address _bondingCurve) {
        bondingCurve = _bondingCurve;
        Cryptomedia _cryptomediaLogic = new Cryptomedia();
        _cryptomediaLogic.initialize(
            address(this),
            "Verse",
            "VERSE",
            "",
            bondingCurve,
            0
        );
        logic = address(_cryptomediaLogic);
    }

    // ======== Deploy contract ========
    function createCryptomedia(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        string calldata _metadataURI,
        uint256 _reservedTokens
    ) external returns (address cryptomedia) {
        require(
            bytes(_metadataURI).length != 0,
            "Cryptomedia: metadata URI must be non-empty"
        );
        cryptomedia = Clones.clone(logic);
        Cryptomedia(cryptomedia).initialize(
            msg.sender,
            _tokenName,
            _tokenSymbol,
            _metadataURI,
            bondingCurve,
            _reservedTokens
        );
        emit CryptomediaDeployed(
            cryptomedia,
            msg.sender,
            _metadataURI,
            _tokenName,
            _tokenSymbol,
            _reservedTokens,
            bondingCurve
        );
    }
}
