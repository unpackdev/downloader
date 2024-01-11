// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ERC1155.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IMintableERC1155.sol";
import "./NativeMetaTransaction.sol";
import "./ContextMixin.sol";
import "./AccessControl.sol";
import "./IERC165.sol";
import "./AccessControlMixin.sol";
import "./Strings.sol";

contract DummyMintableERC1155 is
	ERC1155,
	AccessControlMixin,
	NativeMetaTransaction,
	ContextMixin,
	IMintableERC1155,
	Ownable
{
	using Strings for uint256;

	bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
	// Contract name
	string public name;
	// Contract symbol
	string public symbol;
    string private _uri;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory uri_
	) ERC1155(uri_) {
		name = _name;
		symbol = _symbol;
		_uri = uri_;
		_setupContractId("DummyMintableERC1155");
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(PREDICATE_ROLE, _msgSender());
		_initializeEIP712(_name);
	}

	function uri(uint256 _id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_uri, _id.toString()));
    }

	function setURI(string calldata newuri) external onlyOwner {
		_uri = newuri;
	}

	function collect(address _token) external onlyOwner {
		if (_token == address(0)) {
			payable(msg.sender).transfer(address(this).balance);
		} else {
			uint256 amount = IERC20(_token).balanceOf(address(this));
			IERC20(_token).transfer(msg.sender, amount);
		}
	}

	function collectNFTs(address _token, uint256 _tokenId) external onlyOwner {
		uint256 amount = IERC1155(_token).balanceOf(address(this), _tokenId);
		IERC1155(_token).safeTransferFrom(
			address(this),
			msg.sender,
			_tokenId,
			amount,
			""
		);
	}

	function mint(
		address account,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external override only(PREDICATE_ROLE) {
		_mint(account, id, amount, data);
	}

	function mintBatch(
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external override only(PREDICATE_ROLE) {
		_mintBatch(to, ids, amounts, data);
	}

	function burn(
		address account,
		uint256 id,
		uint256 value
	) public virtual {
		require(
			account == _msgSender() || isApprovedForAll(account, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);
		_burn(account, id, value);
	}

	function burnBatch(
		address account,
		uint256[] memory ids,
		uint256[] memory values
	) public virtual {
		require(
			account == _msgSender() || isApprovedForAll(account, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);
		_burnBatch(account, ids, values);
	}

	function _msgSender()
		internal
		view
		virtual
		override
		returns (address)
	{
		return ContextMixin.msgSender();
	}

	function supportsInterface(
		bytes4 interfaceId
		) public view virtual override(AccessControl, IERC165, ERC1155) returns (bool) {
		return interfaceId == type(IMintableERC1155).interfaceId || super.supportsInterface(interfaceId);
	}
}
