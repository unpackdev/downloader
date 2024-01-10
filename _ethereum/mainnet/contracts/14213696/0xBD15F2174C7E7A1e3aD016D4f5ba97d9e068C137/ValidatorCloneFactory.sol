// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Clones.sol";
import "./IBountyBoard.sol";
import "./AddressValidator.sol";
import "./IdValidator.sol";

contract ValidatorCloneFactory {
    event AddressValidatorCreated(address addr);
    event IdValidatorCreated(address addr);

    address public immutable ADDRESS_VALIDATOR_MASTER_COPY;
    address public immutable ID_VALIDATOR_MASTER_COPY;

    constructor() {
        ADDRESS_VALIDATOR_MASTER_COPY = address(new AddressValidator());
        ID_VALIDATOR_MASTER_COPY = address(new IdValidator());
    }

    function deployAddressValidatorClone(address[] memory addrs)
        external
        returns (address created)
    {
        created = Clones.cloneDeterministic(
            ADDRESS_VALIDATOR_MASTER_COPY,
            keccak256(abi.encode(msg.sender, addrs))
        );
        AddressValidator(created).initialize(msg.sender, addrs);
        emit AddressValidatorCreated(created);
    }

    function predictAddressValidatorAddr(address sender, address[] memory addrs)
        external
        view
        returns (address predicted)
    {
        predicted = Clones.predictDeterministicAddress(
            ADDRESS_VALIDATOR_MASTER_COPY,
            keccak256(abi.encode(sender, addrs))
        );
    }

    function deployIdValidatorClone(
        IBountyBoard.ERC721Grouping[] memory erc721Groupings
    ) external returns (address created) {
        created = Clones.cloneDeterministic(
            ID_VALIDATOR_MASTER_COPY,
            keccak256(abi.encode(msg.sender, erc721Groupings))
        );
        IdValidator(created).initialize(msg.sender, erc721Groupings);
        emit IdValidatorCreated(created);
    }

    function predictIdValidatorAddr(
        address sender,
        IBountyBoard.ERC721Grouping[] memory erc721Groupings
    ) external view returns (address predicted) {
        predicted = Clones.predictDeterministicAddress(
            ID_VALIDATOR_MASTER_COPY,
            keccak256(abi.encode(sender, erc721Groupings))
        );
    }
}
