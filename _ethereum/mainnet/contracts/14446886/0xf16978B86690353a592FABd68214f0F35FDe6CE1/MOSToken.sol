//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Ownable.sol";

contract MOSToken is ERC20, Ownable {
    bool public transferEnable;
    uint256 public maxSupply;
    mapping (address => bool) public isMinter;

    constructor () public ERC20("MetaOasis DAO", "MOS") {
        transferEnable = false;
        maxSupply = 1_000_000_000 ether;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply < maxSupply, "!excess");
        require(_maxSupply >= totalSupply(), "!less than totalSupply");
        maxSupply = _maxSupply;
    }

    function setMinter(address _minter, bool _status) external onlyOwner {
        isMinter[_minter] = _status;
    }

    function setTransferEnable() external onlyOwner {
        transferEnable = !transferEnable;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by minter
    function mint(address _to, uint256 _amount) external {
        require(isMinter[msg.sender] == true, "!minter");
        require((totalSupply() + _amount) <= maxSupply, "!excess");
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