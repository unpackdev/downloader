
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IRegistryConsumer.sol";
import "./IRandomNumberProvider.sol";
import "./LockableRevealERC721EnumerableToken.sol";
import "./BlackHolePrevention.sol";
import "./Ownable.sol";

contract TokenFactoryV1 is Ownable, BlackHolePrevention {

    function deploy(
        TokenConstructorConfig memory tokenConfig,
        address _actualOwner
    ) external returns (address) {
        // Launch new token contract
        LockableRevealERC721EnumerableToken token = new LockableRevealERC721EnumerableToken();
        token.setup(tokenConfig);

        // transfer ownership of the new contract to owner
        token.transferOwnership(_actualOwner);
        return address(token);
    }
}