// SPDX-License-Identifier: Mit
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


/// @title ViseToken - A token contract with buy functionality using USDT.
contract ViseToken is Ownable, ERC20 {

    using SafeERC20 for IERC20;

    uint256 public constant INITIAL_TOTAL_SUPPLY = 1_000_000_000 * 10**18;
    uint256 public unlockTS;


    mapping(address => bool) public whitelist;
    mapping(address => bool) public stakingContracts;

    event Unlocked(uint256 timestamp);
    event EtherWithdrawn(address to, uint256 amount);
    event ERC20Withdrawn(IERC20 token, address to, uint256 amount);

    /// @dev Initializes the contract with the given parameters.
    constructor(
        address _owner
    ) ERC20("VISE", "VISE") {
        _mint(_owner, INITIAL_TOTAL_SUPPLY);
        _transferOwnership(_owner);
        whitelist[_owner] = true;
        unlockTS = 1735689600; // 01.01.2025
    }

    ///@dev Sets the whitelist status for a user.
    ///@param _user The address of the user.
    ///@param _state The whitelist status to be set.
    ///@dev Only the contract owner can call this function.
    function setWhitelist(address _user, bool _state) external onlyOwner {
        whitelist[_user] = _state;
    }

    ///@dev Sets the staking contract status.
    ///@param _contract The address of the staking contract.
    ///@param _state The staking contract status to be set.
    ///@dev Only the contract owner can call this function.
    function setStakingContract(address _contract, bool _state) external onlyOwner {
        stakingContracts[_contract] = _state;
    }

    /// @dev Unlocks the contract, allowing token transfers.
    function unLock() external onlyOwner {
        require(unlockTS >= block.timestamp, "Already unlocked");
        unlockTS = block.timestamp;
        emit Unlocked(block.timestamp);
    }

    /// @dev Allows the owner to withdraw ETH from the contract.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient founds");
        address payable to = payable(msg.sender);
        to.transfer(_amount);
        emit EtherWithdrawn(to, _amount);
    }

    /// @dev Allows the owner to withdraw a specified amount of ERC20 tokens from the contract.
    /// @param _tokenAddress The address of the ERC20 token to withdraw.
    /// @param _amount The amount of ERC20 tokens to withdraw.
    function withdrawERC20(
        IERC20 _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        _tokenAddress.safeTransfer(msg.sender, _amount);
        emit ERC20Withdrawn(_tokenAddress, msg.sender, _amount);
    }

    /// @dev Overrides the internal _transfer function to check for token unlock status.
    function _transfer(address _from, address _to, uint256 _amount) internal override{
        if(unlockTS < block.timestamp){
            super._transfer(_from,_to,_amount);
        }
        require(whitelist[_from] || stakingContracts[_from] || stakingContracts[_to], "Tokens are frozen");
        super._transfer(_from,_to,_amount);
    }

}
