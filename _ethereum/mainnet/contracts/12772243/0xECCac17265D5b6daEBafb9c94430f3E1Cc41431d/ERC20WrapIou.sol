pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract ERC20WrapIou is ERC20, Ownable, ERC20Pausable, ERC20Burnable {

    constructor(
        address[] memory tokenHolders,
        uint256[] memory amounts
    ) ERC20("WRAP-IOU", "WRAP-IOU") {
        require(
            tokenHolders.length == amounts.length,
            "Token holders and amounts lengths must match"
        );

        pause();
        mintMultiple(tokenHolders, amounts);
    }

    modifier isTransferAllowed(address sender) {
        if (paused()) {
            require(
                sender == owner() || msg.sender == owner(),
                "Pausable: not authorized to execute transfer while paused"
            );
        }
        _;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        super._mint(to, amount);
    }

    function mintMultiple(address[] memory tokenHolders, uint256[] memory amounts) public onlyOwner {
        for (uint256 i = 0; i < tokenHolders.length; i++) {
            mint(tokenHolders[i], amounts[i]);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override isTransferAllowed(msg.sender) returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override isTransferAllowed(sender) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Pausable) {}
}
