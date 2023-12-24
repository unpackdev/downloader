// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC721AUpgradeable.sol";
import "./OperatorFiltererUpgradeable.sol";
import "./Ownable2StepUpgradeable.sol";

contract CreepCrewGenesis is
ERC721AUpgradeable,
Initializable,
OperatorFiltererUpgradeable,
Ownable2StepUpgradeable {
	
	mapping (address => bool) public isController;
	string public baseURI;
	
	modifier onlyController() {
		require(isController[msg.sender], "Not a controller");
		_;
	}
	
	function initialize(address _operatorFilterer) public initializerERC721A initializer {
		__ERC721A_init("Creep Crew Genesis", "CCG");
		__Ownable2Step_init();
		__OperatorFilterer_init(_operatorFilterer, true);
	}
	
	function addController (address _controller) external onlyOwner {
		isController[_controller] = true;
	}
	
	function removeController (address _controller) external onlyOwner {
		isController[_controller] = false;
	}
	
	function mint(address _to, uint256 _amount) external onlyController {
		_mint(_to, _amount);
	}
	
	function burn(uint256 _amount) external onlyController {
		_burn(_amount);
	}
	
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}
	
	function setBaseURI(string memory baseURI_) public onlyOwner {
		require(bytes(baseURI_).length > 0, "Invalid Base URI Provided");
		baseURI = baseURI_;
	}
	
	// Opensea overiding functions
	function setApprovalForAll(
		address operator,
		bool approved
	) public override onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}
	
	function approve(
		address operator,
		uint256 tokenId
	) public payable override onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}
	
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}
}
