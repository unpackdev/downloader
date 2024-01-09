// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

import "./ProxyRegistry.sol";

contract GolfJunkiesMintPass1155 is ERC1155Supply, ReentrancyGuard, Ownable {

    uint256 constant public MAX_SUPPLY = 500;
    uint256 constant public TOKEN_ID = 1;

    address public _proxyAddress;
    address public _treasuryAddress;
    address public _authenticatedBurner;
    uint256 public _price;
    uint256 public _maxPerTx;
    bool public _saleClosed;

    // Contract name
    string public name = "Golf Junkies Mint Pass";
    // Contract symbol
    string public symbol = "GJMP";
    

    constructor(
        address proxyAddress_,
        address treasuryAddress_,
        uint256 price_,
        uint256 maxPerTx_,
        string memory uri_) ERC1155(uri_) {
        _proxyAddress = proxyAddress_;
        _treasuryAddress = treasuryAddress_;
        _price = price_;
        _maxPerTx = maxPerTx_;
    }

    function mint(uint256 amount) external payable nonReentrant {
        require(!_saleClosed, "Mint pass closed");
		require((totalSupply(TOKEN_ID) + amount) <= MAX_SUPPLY, "Minting will exceed maximum supply");
		require(amount > 0, "Mint more than zero");
		require(amount <= _maxPerTx, "Mint amount too high");
		require(msg.value >= (_price * amount), "Sent eth incorrect"); 
        _mint(msg.sender, TOKEN_ID, amount, "");
        payable(_treasuryAddress).transfer(msg.value);
    }

    function isSoldOut() external view returns(bool) {
		return!(totalSupply(TOKEN_ID) < MAX_SUPPLY);
	}

    function setTreasury(address newTreasuryAddress_) external onlyOwner {
		_treasuryAddress = newTreasuryAddress_;
	}

	function setBurner(address newBurnerAddress_) external onlyOwner {
		_authenticatedBurner = newBurnerAddress_;
	}

	function burnFrom(address from, uint256 amount) external nonReentrant {
		require(_authenticatedBurner != address(0), "Burner not configured");
		require(msg.sender == _authenticatedBurner, "Not authorised");
        require(amount > 0, "Amount must be over 0");
        require(balanceOf(from, TOKEN_ID) >= amount, "Not enough tokens");
        _burn(from, TOKEN_ID, amount);
	}

	function closeSale() external onlyOwner {
		_saleClosed = true;
	}

    /**
     * @dev Override the base isApprovedForAll(address owner, address operator) to allow us to
     *      specifically allow the opense operator to transfer tokens
     * 
     * @param owner_ owner address
     * @param operator_ operator address
     * @return bool if the operator is approved for all
     */
    function isApprovedForAll(
        address owner_,
        address operator_
    ) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyAddress);
        if (address(proxyRegistry.proxies(owner_)) == operator_) {
            return true;
        }
        return ERC1155.isApprovedForAll(owner_, operator_);
    }

    /**
     * @dev to receive remaining eth from the link exchange
     */
    receive() external payable {}

}