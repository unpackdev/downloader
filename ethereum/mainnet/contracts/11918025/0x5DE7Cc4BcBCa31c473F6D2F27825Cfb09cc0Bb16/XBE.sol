pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./Address.sol";


/**
 * @title eurxb.finance governments token
 * @dev xbe token
 */
contract XBE is ERC20 {
    using Address for address;
    using SafeMath for uint256;

    address private governance;
    mapping (address => bool) private minters;

    constructor(
        uint256 initialSupply
    ) public ERC20("XBE", "XBE") {
        governance = _msgSender();
        _mint(msg.sender, initialSupply);
    }

    function getGovernance() external view returns (address) {
        return governance;
    }

    function getMinters(address minter) external view returns (bool) {
        return minters[minter];
    }

    function mint(address account, uint256 amount) external {
        require(minters[msg.sender], "!minter");
        _mint(account, amount);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function addMinter(address _minter) external {
        require(msg.sender == governance, "!governance");
        minters[_minter] = true;
    }

    function removeMinter(address _minter) external {
        require(msg.sender == governance, "!governance");
        minters[_minter] = false;
    }
}
