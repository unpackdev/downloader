// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./ConfirmedOwner.sol";
import "./ERC20Mintable.sol";
import "./ERC20Wrapper.sol";

/**
 * @title Wrapped NOOT (https://noot.fun)
 *
 * @notice Wrapped version of NOOT token, with guarded wrapping/unwrapping methods
 * and guarded minter interface for CCIP TokenPool.
 * 
 * @dev This token is meant to not be publicly accessible to prevent abusing to to
 * evade transfer fees. WNOOT does only exist inside the bridge temporarly or inside 
 * CCIP Token Pool.
 * This contract has restricted methods to add minters, the only allowed minter should be
 * the CCIP Token Pool. Methods to change minter role soley exist to recover from critical bugs
 * which requires migration to a new Portal contract. Due to the nature of these methods, 
 * it is strongly recommended to transfer the ownership to a multisig wallet and/or a timelock 
 * controller after the initial setup is completed.
 */
contract WNOOT is ERC20Mintable, ERC20Burnable, ERC20Wrapper, ConfirmedOwner  {
    constructor(
        address _owner,
        address _underlyingToken,
        bool _underlyingBurnMint
    )
        ERC20("WNOOT", "WNOOT")
        ConfirmedOwner(_owner)
        ERC20Wrapper(_underlyingToken, _underlyingBurnMint)
    {}

    function setWrapper(address _wrapper, bool _isWrapper) external onlyOwner {
        _setWrapper(_wrapper, _isWrapper);
    }

    function setMinter(address _minter, bool _isMinter) external onlyOwner {
        _setMinter(_minter, _isMinter);
    }

    function withdrawReflections(address _to) external onlyOwner {
        _withdrawReflections(_to);
    }
}
