// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./IERC20.sol";

contract CSXSwap is Ownable {

    address public csx;
    address public treasuryWallet;

    event MintToken(address user, uint256 csxAmount);

    constructor(address _csx, address _treasuryWallet) {
        require(_csx != address(0), "CSX$: token zero address");
        require(
            _treasuryWallet != address(0),
            "CSX$: treasuryWallet wallet zero address"
        );
        csx = _csx;
        treasuryWallet = _treasuryWallet;
    }


    function swap(uint256 _csxAmount) external {
        require(_msgSender() != address(0), "CSX$: zero address");
        require(_csxAmount > 0, "CSX$: amount error");
        require(
            treasuryWallet != address(0x0),
            "CSX$: cannot transfer to zero address"
        );
        uint256 allowance = IERC20(csx).allowance(_msgSender(), address(this));
        require(
            allowance >= _csxAmount,
            "CSX$: Transfer amount exceeds allowance."
        );
        IERC20(csx).transferFrom(_msgSender(), treasuryWallet, _csxAmount);
        emit MintToken(_msgSender(), _csxAmount);
    }

    function updateTreasuryWallet(address _newWallet) external onlyOwner {
        treasuryWallet = _newWallet;
    }

     function updateCSXAddress(address _newAddress) external onlyOwner {
        csx = _newAddress;
    }
    
}
