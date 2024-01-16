// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./RoleControl.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//    d8888b.  .d88b.   .o88b. db   dD d88888b db       .d88b.  db   d8b   db    //
//    88  `8D .8P  Y8. d8P  Y8 88 ,8P' 88'     88      .8P  Y8. 88   I8I   88    //
//    88oobY' 88    88 8P      88,8P   88ooo   88      88    88 88   I8I   88    //
//    88`8b   88    88 8b      88`8b   88~~~   88      88    88 Y8   I8I   88    //
//    88 `88. `8b  d8' Y8b  d8 88 `88. 88      88booo. `8b  d8' `8b d8'8b d8'    //
//    88   YD  `Y88P'   `Y88P' YP   YD YP      Y88888P  `Y88P'   `8b8' `8d8'     //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////

/// @title RockFlowAvatar
/// @author wangfulong
/// @custom:security-contact wfllike@gmail.com
contract RockFlowOfficial is ERC721, IERC2981, ReentrancyGuard, RoleControl {
	using Counters for Counters.Counter;

	event MintedWithRole(address from, address to, uint256 indexed tokenId);
	event Deposit(address indexed account, uint256 amount);
	event Withdraw(address indexed account, uint256 amount);
	event Received(address, uint256);

	uint256 public constant MAX_SUPPLY = 8000;
	Counters.Counter private _supplyCounter;
	string private _customBaseURI;

	constructor(string memory _uri) ERC721("RockFlowOfficial", "RFO") {
		_customBaseURI = _uri;
	}

	/// @dev if you want your contract to receive Ether, you have to implement a receive Ether function
	receive() external payable {
		emit Received(msg.sender, msg.value);
	}

	function mint(address to, uint256 tokenId) public onlyMinterOrAdmin {
		require(totalSupply() < MAX_SUPPLY, "Exceed max supply");

		_safeMint(to, tokenId);

		_supplyCounter.increment();
		emit MintedWithRole(msg.sender, to, tokenId);
	}

	function totalSupply() public view returns (uint256) {
		return _supplyCounter.current();
	}

	function setBaseURI(string memory _uri) external onlyAdmin {
		_customBaseURI = _uri;
	}

	function baseURI() external view returns (string memory) {
		return _baseURI();
	}

	function _baseURI() internal view override returns (string memory) {
		return _customBaseURI;
	}

	function deposit() external payable {
		emit Deposit(msg.sender, msg.value);
	}

	/** PAYOUT **/
	function withdraw() external onlyAdmin nonReentrant {
		uint256 balance = address(this).balance;

		Address.sendValue(payable(msg.sender), balance);
		emit Withdraw(msg.sender, balance);
	}

	/** ROYALTIES **/
	function royaltyInfo(uint256 tokenId, uint256 salePrice)
		external
		view
		override
		returns (address receiver, uint256 royaltyAmount)
	{
		require(_exists(tokenId), "Nonexistent token");
		return (address(this), SafeMath.div(SafeMath.mul(salePrice, 10), 100));
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, IERC165, AccessControl)
		returns (bool)
	{
		return (interfaceId == type(IERC2981).interfaceId ||
			super.supportsInterface(interfaceId));
	}
}
