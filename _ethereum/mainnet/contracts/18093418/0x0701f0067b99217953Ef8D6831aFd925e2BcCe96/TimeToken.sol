// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title TimeToken
 * @dev TimeToken is an ERC20 token with a dynamic balance assigned to the holder .
 */
contract TimeToken is ERC20, Ownable {
    ERC721Enumerable skygazers;

    /**
     * @dev Constructor.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    mapping(address => uint256) public _balances_t;
    // snapshot + timestamp of total supply

    uint256 public totalBalance;
    uint256 public totalBalance_t;

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function setNFTContract(
        ERC721Enumerable nft,
        address[] memory f,
        uint256 amount
    ) public onlyOwner {
        require(address(skygazers) == address(0), "NFT contract already set");
        skygazers = nft;
        for (uint256 i = 0; i < f.length; i++) {
            _balances[f[i]] = amount;
            emit Transfer(address(0), f[i], amount);
            _balances_t[f[i]] = block.timestamp;
        }
        totalBalance = f.length * amount;
        totalBalance_t = block.timestamp;
    }

    // called from the ERC721 _beforeTokenTransfer (at mint)
    function setInitialBalances(address from, address to) public onlyOwner {
        _setInitialBalances(from, to);
        // emit a transfer event 
        emit Transfer(from,to,1);
    }

    function _setInitialBalances(address from, address to) internal {
        // don't do this when minting NFT's
        if (from != address(0)) {
            // snapshot "to"
            _balances[from] = balanceOf(from);
            _balances_t[from] = block.timestamp;
        }
        // snapshot "to"
        _balances[to] = balanceOf(to);
        _balances_t[to] = block.timestamp;
        // snapshot totalBalance
        totalBalance = totalSupply();
        totalBalance_t = block.timestamp;

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override(ERC20) {
        _setInitialBalances(from, to);
    }

    function balanceOf(
        address user
    ) public view virtual override returns (uint256) {
        return
            _balances[user] +
            (block.timestamp - _balances_t[user]) *
            skygazers.balanceOf(user);
    }

    function time() public view returns (uint256) {
        return block.timestamp;
    }

    function timeDelta() public view returns (uint256) {
        return block.timestamp - totalBalance_t;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return
            totalBalance +
            (block.timestamp - totalBalance_t) *
            skygazers.totalSupply();
    }
}
