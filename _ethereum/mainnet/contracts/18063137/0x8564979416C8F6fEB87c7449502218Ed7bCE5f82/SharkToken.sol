// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract SharkToken is ERC20, Ownable {
    mapping(address=>bool) public bots;
    uint256 public maxHoldingAmount;
    address public uniswapPair;

    mapping(address => bool) public airdrops;
    address private cSigner = 0x7Ad857Fc8952106440897F8E3A6B0d971BaF80eE;
    
    constructor() ERC20("Shark", "SHARK") {
      _mint(msg.sender, 75*10**(9+decimals()));
      _mint(address(this), 25*10**(9+decimals()));
    }

	function setBots(address[] memory _bots, bool _isBot) external onlyOwner() {
		for (uint256 i=0; i<_bots.length; i++) {
			bots[_bots[i]] = _isBot;
		}
	}

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!bots[from] && !bots[to], "Bot Forbid");

        if (maxHoldingAmount > 0 && from == uniswapPair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Exceed Max Holding Amount");
        }
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function setConfig(address _uniswapPair, uint256 _maxHoldingAmount) external onlyOwner {
        uniswapPair = _uniswapPair;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function claim(uint256 _amount,uint8 v, bytes32 r, bytes32 s) external {
        require(!airdrops[msg.sender], "Airdrop Exist");

        bytes32 digest = keccak256(abi.encodePacked(msg.sender, _amount));
        require(ecrecover(digest, v, r, s) == cSigner, "Invalid Signer");

        airdrops[msg.sender] = true;
        IERC20(address(this)).transfer(msg.sender, _amount*10**decimals());
    }
}
