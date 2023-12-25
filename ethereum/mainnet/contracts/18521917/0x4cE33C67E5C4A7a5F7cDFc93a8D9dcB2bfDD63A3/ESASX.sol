// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./ERC20Burnable.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ESASXErrors.sol";

/**
 * @title Asymetrix Protocol V2 esASX
 * @author Asymetrix Protocol Inc Team
 * @notice A contract implements esASX token that will be used to incentivize those users who stake their stETH in the
 *         StakePrizePoolV2 contract. The token is non-transferable by default and can be transferred only from and only
 *         to whitelisted users.
 */
contract ESASX is ERC20Burnable, Ownable {
    using Address for address;

    mapping(address => uint256) private _isWhitelisted;

    uint256 private constant NOT_WHITELISTED = 0;
    uint256 private constant WHITELISTED = 1;

    /**
     * @notice Deploy esASX token contract.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _amount The amount of tokens to mint in time of deploy.
     */
    constructor(string memory _name, string memory _symbol, uint256 _amount) ERC20(_name, _symbol) {
        _isWhitelisted[msg.sender] = WHITELISTED;

        _mint(msg.sender, _amount);
    }

    /**
     * @notice A method sets whitelisted status for specific address. Callable only by the owner.
     * @param _address An address to whitelist/unwhitelist.
     * @param _whitelisted State for the whitelist.
     */
    function setWhitelisted(address _address, bool _whitelisted) external onlyOwner {
        _isWhitelisted[_address] = _whitelisted ? WHITELISTED : NOT_WHITELISTED;
    }

    /**
     * @notice A method checks if the address is whitelisted.
     * @param _address An address provided for the check.
     */
    function isWhitelisted(address _address) public view returns (bool) {
        return _isWhitelisted[_address] == WHITELISTED;
    }

    /**
     * @notice A method doing additional checks before transfer.
     * @param from An address from where transfer is coming.
     * @param to An address where transfer is coming to.
     * @param amount An amount of tokens to transfer.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (!isWhitelisted(from) && !isWhitelisted(to)) revert ESASXErrors.NonTransferable();

        super._afterTokenTransfer(from, to, amount);
    }
}
