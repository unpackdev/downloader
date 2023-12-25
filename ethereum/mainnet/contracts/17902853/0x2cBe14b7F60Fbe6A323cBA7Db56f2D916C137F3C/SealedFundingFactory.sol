pragma solidity ^0.8.7;

import "./SealedFunding.sol";

contract SealedFundingFactory {
    address public immutable exchange;

    constructor(address _exchange) {
        exchange = _exchange;
    }

    event SealedFundingRevealed(bytes32 salt, address owner);

    function deploySealedFunding(bytes32 salt, address owner) public {
        new SealedFunding{salt: salt}(owner, exchange);
        emit SealedFundingRevealed(salt, owner);
    }

    function computeSealedFundingAddress(bytes32 salt, address owner)
        external
        view
        returns (address predictedAddress, bool isDeployed)
    {
        predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(abi.encodePacked(type(SealedFunding).creationCode, abi.encode(owner, exchange)))
                        )
                    )
                )
            )
        );
        isDeployed = predictedAddress.code.length != 0;
    }
}
