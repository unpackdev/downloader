pragma solidity 0.7.5;

import "./Ownable.sol";
import "./ERC20.sol";

/**
 * @dev YzerChain token of ERC20 standard.
 *
 * name           : YzerChain
 * symbol         : YZR
 * decimal        : 18
 * initial supply : 10,000,000 YZR
 */
contract YzerChain is Ownable, ERC20 {
    mapping (address => bool) public minters;

    /**
     * @dev Initialize token with name, symbol, and mint supply.
     */
    constructor() public Ownable() ERC20('YzerChain', 'YZR') {
        _mint(msg.sender, 10000000 * 1e18);
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
     * @dev Burn `amount` token.
     *
     * Only minter can burn.
     */
    function burn(uint amount) external {
        require(minters[msg.sender], "not minter");
        _burn(address(this), amount);
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
