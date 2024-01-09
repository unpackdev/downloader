pragma solidity 0.6.12;

import "./ERC20.sol";

// Standard ERC20 token with mint and burn
contract MOSToken is ERC20 {
    address public governance;
    bool public transferEnable;
    mapping (address => bool) public isMinter;

    constructor () public ERC20("MetaOasis DAO", "MOS") {
        governance = msg.sender;
        transferEnable = false;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setMinter(address _minter, bool _status) external {
        require(msg.sender == governance, "!governance");
        isMinter[_minter] = _status;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by minter
    function mint(address _to, uint256 _amount) external {
        require(isMinter[msg.sender] == true, "!minter");
        _mint(_to, _amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract has enabled transfer
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (!transferEnable) {
            require(from == address(0), "ERC20: only allow mint");
        }
    }
}
