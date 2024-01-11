// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HumeAngelbabyCommunityEP1.sol";
import "./Factory.sol";

contract HumeAngelbabyCommunityEP1Factory is Factory, Ownable {
    mapping(address => bool) private contracts;

    /// @inheritdoc Factory
    function _createChild(bytes calldata data_)
        internal
        virtual
        override
        returns (address child_)
    {
        ConstructorConfig memory config_ = abi.decode(
            data_,
            (ConstructorConfig)
        );
        child_ = address(new HumeAngelbabyCommunityEP1(config_));
    }

    /// @inheritdoc Factory
    function createChild(bytes calldata data_)
        external
        virtual
        override
        nonReentrant
        returns (address) 
    {
        require(
            msg.sender == owner() || msg.sender == address(this),
            "Ownable: caller is not the owner"
        );
        // below could be replaced with //super.createChild(data_); ???
        
        // Create child contract using hook.
        address child_ = _createChild(data_);
        // Ensure the child at this address has not previously been deployed.
        require(!contracts[child_], "DUPLICATE_CHILD");
        // Register child contract address to `contracts` mapping.
        contracts[child_] = true;
        // Emit `NewChild` event with child contract address.
        emit IFactory.NewChild(msg.sender, child_);
        return child_;
    }

    /// @inheritdoc Factory
    function isChild(address maybeChild_)
        external
        view
        virtual
        override
        returns (bool)
    {
        return contracts[maybeChild_];
    }

    /// Typed wrapper around IFactory.createChild.
    function createChildTyped(ConstructorConfig calldata config_)
        external
        onlyOwner
        returns (HumeAngelbabyCommunityEP1 child_)
    {
        child_ = HumeAngelbabyCommunityEP1(
            this.createChild(abi.encode(config_))
        );
    }
}
