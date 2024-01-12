// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20PresetMinterPauser.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract Souls is ERC20PresetMinterPauser, Ownable {
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

    constructor(string memory name, string memory symbol) ERC20PresetMinterPauser(name, symbol) {
        _setupRole(BURNER_ROLE, _msgSender());
        super.mint(msg.sender, 1500000*(10**18));
    }

    function addOrDeleteMinterRole(address _to, bool _add) public virtual onlyOwner {
        if (_add) {
            _setupRole(MINTER_ROLE, _to);
        } else {
            _revokeRole(MINTER_ROLE, _to);
        }
    }

    function addOrDeletePauserRole(address _to, bool _add) public virtual onlyOwner {
        if (_add) {
            _setupRole(PAUSER_ROLE, _to);
        } else {
            _revokeRole(PAUSER_ROLE, _to);
        }
    }

    function addOrDeleteBurnerRole(address _to, bool _add) public virtual onlyOwner {
        if (_add) {
            _setupRole(BURNER_ROLE, _to);
        } else {
            _revokeRole(BURNER_ROLE, _to);
        }
    }

    function pause() public virtual override {
        super.pause();
    }

    function unpause() public virtual override {
        super.unpause();
    }

    function mint(address to, uint256 amount) public virtual override {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Souls: must have minter role to burn tokens');
        super.mint(to, amount);
    }

    function burn(uint256 amount) public virtual override {
        require(hasRole(BURNER_ROLE, _msgSender()), 'Souls: must have burner role to burn tokens');
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override {
        require(hasRole(BURNER_ROLE, _msgSender()), 'Souls: must have burner role to burn tokens');
        super.burnFrom(account, amount);
    }

    function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }
    
    /**
     * @dev withdraw all eth from contract and transfer to owner.
     */
    function withdraw() external onlyOwner {
        (bool aa, ) = payable(owner()).call{value: address(this).balance}('');
        require(aa);
    }

    /// @dev To withdraw all erc20 token from the contract
    /// @param token - address of the erc20 token
    function withdrawERC20(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, 'Amount Insufficient');
        IERC20(token).transfer(msg.sender, amount);
    }

    /// @dev To withdraw all erc20 token from the contract
    /// @param token - address of the erc20 token
    function withdrawERC20UsingSafeTransfer(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, 'Amount Insufficient');
        SafeERC20.safeTransfer(IERC20(token), msg.sender, amount);
    }
}
