pragma solidity 0.7.5;

import "./Ownable.sol";
import "./ERC20.sol";

/**
 * @dev ABCVoucher token of ERC20 standard.
 * @author Over1 Team
 *
 * name           : ABCVoucher
 * symbol         : ABC
 * decimal        : 8
 * initial supply : 0 ABC
 */
contract ABCVoucher is Ownable, ERC20 {
    mapping (address => bool) public minters;

    /**
     * @dev Initialize token with name, symbol and decimals.
     */
    constructor() public Ownable() ERC20('ABCVoucher', 'ABC') {
        _setupDecimals(8);
    }

    /**
     * @dev Mint `amount` token to `account`.
     *
     * Only minter can mint.
     */
    function mint(address account, uint amount) external {
        require(minters[msg.sender], "not minter");
        _mint(account, amount);
    }

    /**
     * @dev Add `minter` to the minters list.
     *
     * Only owner can add minter.
     */
    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    /**
     * @dev Remove `minter` from the minters list.
     *
     * Only owner can remove minter
     */
    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }
}
