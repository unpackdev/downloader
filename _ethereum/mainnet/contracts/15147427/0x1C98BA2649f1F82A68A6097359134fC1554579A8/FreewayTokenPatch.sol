// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

/// @custom:security-contact security@aubit.io
contract FreewayTokenPatch is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    mapping(address => bool) private _blacklist;

    function initialize() external initializer {
        __ERC20_init("FreewayToken", "FWT");
        __Pausable_init();
        __Ownable_init();

        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        // Allow liquidity retrieval
        bool poolToRouter = from == 0x271544Af1F703ac3dEb3F12790dE83b3B987AA2B && to == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        bool routerToLiquidityProvider = from == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D && to == 0xa35F15C084bEf799E94A30803666129e0Eb8dCE5;

        // Allow users to send tokens to the designated wallet to prove ownership
        bool toVault = to == 0x3df5ab00556A022860ad917692B360f63842d700;

        require (poolToRouter || routerToLiquidityProvider || toVault, "Token transfers are restricted to the verification address");
        require (to != address(this), "Token transfers to the contract address are forbidden");
        require (!isBlackListed(from), "Token transfer refused. from is on blacklist");
        super._beforeTokenTransfer(from, to, amount);
    }
    
    event BlacklistUpdated(address indexed user, bool value);

    function blacklistUpdate(address user, bool value) public virtual onlyOwner {
        _blacklist[user] = value;
        emit BlacklistUpdated(user, value);
    }
    
    function isBlackListed(address user) public view returns (bool) {
        return _blacklist[user];
    }

    /**
    * @dev For a large number of destinations, separate in different calls to batchTransfer.
    * @param destinations List of addresses to set the values
    * @param values List of values to set
    */
    function batchTransfer(address[] calldata destinations, uint256[] calldata values) external {
        require(destinations.length == values.length, "destinations.length != values.length");
        
        uint256 length = destinations.length;
        uint i;
        
        for (i = 0; i < length; i++) {
            _transfer(msg.sender, destinations[i], values[i]);
        }
    }

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}
