// SPDX-License-Identifier: Unlicensed.
pragma solidity 0.8.2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./SafeERC20.sol";

contract DigiToadsClaim is Ownable, Pausable {
    using SafeERC20 for IERC20;
    address public DigiToads;
	
    uint256 public totalContribution;
	
    mapping(address => uint256) public contributors;
    mapping(address => uint256) public claimedBalance;
	
    event AmountClaimed(address account, uint256 amount);
	event NewDigiToadsToken(address newDigiToads);
	
    constructor(address _DigiToads) {
        require(_DigiToads != address(0), "Error: Cannot be the null address");
        DigiToads = _DigiToads;
    }
	
    function addContributors(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Error: Array lengths do not match");
		
        for(uint256 i = 0; i < accounts.length; i++) {
           contributors[accounts[i]] += amounts[i];
           totalContribution += amounts[i];
        }
    }
	
    function removeContributors(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = contributors[accounts[i]];
            require(amount > 0, "Error: Contributor not registered");
			
            contributors[accounts[i]] = 0;
            totalContribution -= amount;
        }
    }
	
    function claim() external whenNotPaused{
        address caller = _msgSender();
		
        uint256 amountToClaim = pending(caller);
		
        require(amountToClaim > 0, "Error: No balance to claim");
		require(IERC20(DigiToads).balanceOf(address(this)) >= amountToClaim, "Error: Not enough DigiToads balance");
		
        claimedBalance[caller] += amountToClaim;
        IERC20(DigiToads).safeTransfer(caller, amountToClaim);
		
        emit AmountClaimed(caller, amountToClaim);
    }

    function pending(address account) public view returns (uint256) {
        uint256 amount = contributors[account] - claimedBalance[account];
        return amount;
    }
	
	function updsateDigiToadsToken(address newAddress) external onlyOwner{
       require(newAddress != address(0), "Zero address");
	   DigiToads = newAddress;
	   emit NewDigiToadsToken(newAddress);
    }
	
    function pause() public onlyOwner {
        _pause();
    }
	
    function unpause() public onlyOwner {
        _unpause();
    }
}