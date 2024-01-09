// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./IERC20Factory.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Clones.sol";

interface IERC20 {
    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external;
}

/**
 * @title ERC20Factory
 * @notice The `ERC20Factory` contract deploys ERC20 clones. After deployment, the
 * factory calls `initialize` to set up the ERC20 metadata and mint the initial total
 * supply to the owner's wallet.
 * @author MirrorXYZ
 */
contract ERC20Factory is
    IERC20Factory,
    IERC20FactoryEvents,
    IERC20Events,
    IOwnableEvents
{
    /// @notice Address that holds the clone implementation
    address public immutable implementation;

    constructor(address implementation_) {
        implementation = implementation_;
    }

    //======== Deploy function =========

    /// @notice Deploy an ERC20 clone.
    /// @param owner the owner of the ERC20 token
    /// @param name_ the ERC20 metadata name parameter
    /// @param symbol_ the ERC20 metadata symbol parameter
    /// @param totalSupply_ the ERC20 token initial supply, minted to `owner`
    /// @param decimals_ the ERC20 token decimals
    /// @param nonce an additional entropy input to the clones salt
    function create(
        address owner,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        uint256 nonce
    ) external override returns (address erc20Clone) {
        erc20Clone = Clones.cloneDeterministic(
            implementation,
            keccak256(abi.encode(owner, name_, symbol_, totalSupply_, nonce))
        );

        IERC20(erc20Clone).initialize(
            owner,
            name_,
            symbol_,
            totalSupply_,
            decimals_
        );

        emit ERC20Deployed(erc20Clone, name_, symbol_, owner);
    }

    function predictDeterministicAddress(address implementation_, bytes32 salt)
        external
        view
        override
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                implementation_,
                salt,
                address(this)
            );
    }
}
