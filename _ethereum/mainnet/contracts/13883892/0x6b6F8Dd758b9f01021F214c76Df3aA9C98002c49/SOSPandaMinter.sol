// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract SOSPandaMinter is PaymentSplitter, Ownable, Pausable  {
    
    uint256 public mintPrice = 50000000000000000000000000;
    address erc20Address;
    address immutable expAddress;
    
    constructor(
    	address _erc20Address,
    	address _expAddress,
        address[] memory payees,
        uint256[] memory shares_
    ) PaymentSplitter(payees, shares_) {
    	erc20Address = _erc20Address;
    	expAddress = _expAddress;
    }    

    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }                         

    function setERC20(address _erc20Address) external onlyOwner {
        erc20Address = _erc20Address;
    }  

    function purchase(uint256 amount) external whenNotPaused {
        require(IERC20(erc20Address).transferFrom(msg.sender, address(this), mintPrice * amount), "Payment failed");
        require(amount <= 10, "max tx amount exceeded");

        Expandables(expAddress).ownerMint(msg.sender, amount);
    }

    function release(IERC20 token, address account) public override {
        require(msg.sender == account || msg.sender == owner(), "Release: no permission");

        super.release(token, account);
    }    

    function transferPandaOwnership(address _newOwner) external onlyOwner {
    	Expandables(expAddress).transferOwnership(_newOwner);
    } 

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }    

    function reveal() external onlyOwner returns (bytes32 requestId) {
        return Expandables(expAddress).reveal();
	}

	function ownerMint(address to, uint256 amount) external onlyOwner {
        Expandables(expAddress).ownerMint(to, amount);
	}
}

interface Expandables {
    function ownerMint(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
    function reveal() external returns (bytes32 requestId);
}