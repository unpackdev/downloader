// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ERC20Permit.sol";
import "./IRewardDistributorManager.sol";
import "./IBSLendingPair.sol";
import "./IBSWrapperToken.sol";
import "./IERC20Details.sol";
import "./Initializable.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title WrapperToken
/// @author @samparsky
/// @dev
///
////////////////////////////////////////////////////////////////////////////////////////////


abstract contract WrapperTokenBase is ERC20Permit, Initializable {

    /// @dev reward distributor Manager
    IRewardDistributorManager public rewardManager;

    /// @dev underlying wrapper token
    address public underlying;

    /// @dev the LendingPair is the "owner" for WrapperTokens
    address internal _owner;


     /**
     * @dev Throws if called by any account other than the lendingpair.
     */
    modifier onlyLendingPair() {
        require(address(_owner) == msg.sender, "ONLY_LENDING_PAIR");
        _;
    }

    function _rewardHook(address _from, address _to) internal {
        rewardManager.accumulateRewards(_from, _to);
    }
}

contract WrapperToken is  IBSWrapperToken, WrapperTokenBase {
    /// @dev wrapper token version
    uint256 constant public VERSION = 0x1;

    /// @notice
    function initialize(
        address __owner,
        address _underlying,
        string memory _tokenName,
        string memory _tokenSymbol,
        IRewardDistributorManager _manager
    ) external virtual override initializer {
        require(__owner != address(0), "invalid owner");
        require(_underlying != address(0), "invalid underlying");

        _owner = __owner;
        uint8 underlyingDecimal = IERC20Details(_underlying).decimals();
        initializeERC20(_tokenName, _tokenSymbol, underlyingDecimal);
        initializeERC20Permit(_tokenName);
        underlying = _underlying;
        rewardManager = _manager;
    }

    /**
    @notice mint is an only owner function that allows the owner to mint new tokens to an input account
    @param _to is the address that will receive the new tokens
    @param _amount is the amount of token they will receive
    **/
    function mint(address _to, uint256 _amount) external virtual override onlyLendingPair {
        _rewardHook(address(0), _to);
        _mint(_to, _amount);
    }

    /**
     * @notice burn is an only owner function that allows the owner to burn  tokens from an input account
     * @dev IMPORTANT: it reverts if user doesn't have enough balance
     * @param _from is the address where the tokens will be burnt
     * @param _amount is the amount of token to be burnt
     **/
    function burn(address _from, uint256 _amount) external virtual override onlyLendingPair {
        _rewardHook(_from, address(0));
        _burn(_from, _amount);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        _rewardHook(sender, recipient);
        super._transfer(sender, recipient, amount);
    }
}
