// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author: BLOCKS

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

import "./IBlocksToken.sol";

/**
 * BlocksToken - Governance token for the BLOCKS DAO

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxkxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMNXKKKKKKKKKKXXNMWNXKKKKXNMMMMMMMMWNOl'..;. 'lkXWMMMMMMWNXXKXKKXKKKXWMWNXKKKKXNMWXKKKKXNMWXKKKKXXXKKXNWMMMMMMMM
MMMMMMMWx.......'.....,dKl......dWMMMMWXkl'    .;.    'ckXWMMKl'....''.....;kKc.....'xWk,....:Ox;.....''....'oXMMMMMMM
MMMMMMMWo      ':.     'x;      lNMMMKl.       .;.       .cdOo      ':.     'x,      oO,    .xO'     .:'     .dWMMMMMM
MMMMMMMWo      ,c.     'x;      lNMMWd         .:.         .ll      ,c.     'd,      ::    .xWO.     .c,      dWMMMMMM
MMMMMMMWo      ,c.     ;k;      lNMMWo         .:.         .cl      ,c.     'd;      .    .dWM0,     .:c,,,,:oKMMMMMMM
MMMMMMMWo      .'     ;OK;      cXWWWo       ..,;,..       .cl      ,xocccccxO,          .oNMMWOc,'''',......cKMMMMMMM
MMMMMMMWo      .;.    .cO;      .,,;xl    ..''.   .''..    .cc      ,dc,,,,,lk,           lNMMKc,'''':o'     .dWMMMMMM
MMMMMMMWo      ,c.     'x:          cl..'''.         ..''...lc      ,c.     'd;      .    .oNMO.     .c,      dWMMMMMM
MMMMMMMWo      ,c.     'x:          cOl,.               .'cdOl      ,c.     'd;      cc    .oNO.     .c,      dWMMMMMM
MMMMMMMWo      ';.     ,k:          lNXxc.             .:xXWWd.     ';.     ,x;      o0;    .dO'     .:.     .xWMMMMMM
MMMMMMMWx,''''',,'''',cOXo''''''''',xWMMWXkl'       'ckXWMMMMXd;,''',,'''',cOKo''''',kWO:''''cOOc,'''',,''',:dXMMMMMMM
MMMMMMMMWNNNNNNNNNNNNWWMMWNNNNNNNNNNWMMMMMMMNOo,.,lONMMMMMMMMMMWWNNNNNNNNNWWMMWNNNNNNWMMWNNNNNWMWWNNNNNNNNNWWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

contract BlocksToken is ERC20, ERC20Burnable, Ownable, IBlocksToken {
	uint256 private immutable _SUPPLY_CAP;
    
    /**
     * @notice Constructor 
     * @param _premintReceiver address that receives the premint
     * @param _premintAmount amount to premint
     * @param _cap supply cap (to prevent abusive mint)
     */
    constructor(
        address _premintReceiver,
        uint256 _premintAmount,
        uint256 _cap
    ) ERC20("BLOCKS", "BLOCKS") {
        require(_cap > _premintAmount, "BLOCKS: Premint amount is greater than cap");
        // Transfer the sum of the premint to address
        _mint(_premintReceiver, _premintAmount);
        _SUPPLY_CAP = _cap;
    }    

    /**
     * @notice Mint BLOCKS tokens
     * @param account address to receive tokens
     * @param amount amount to mint
     * @return status true if mint is successful, false if not
     */
    function mint(address account, uint256 amount) external override onlyOwner returns (bool status) {
        if (totalSupply() + amount <= _SUPPLY_CAP) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    /**
     * @notice View supply cap
     */
    function SUPPLY_CAP() external view override returns (uint256) {
        return _SUPPLY_CAP;
    }
}
