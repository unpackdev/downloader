// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./Strings.sol";

contract MultiToken is ERC1155, Ownable {
	constructor(string memory uri_) ERC1155(uri_) {}

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     */
    function uri(uint256 id) public view virtual override returns (string memory) {
		return string(abi.encodePacked(ERC1155.uri(id), Strings.toString(id)));
    }

    /**
     * @dev Sets a new base URI for all tokens.
     *
     * See {IERC1155MetadataURI-uri}.
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address tokenOwner, address operator) public view virtual override returns (bool) {
        return ERC1155.isApprovedForAll(tokenOwner, operator) || (operator == owner());
    }

	function mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual onlyOwner {
        _mint(to, id, amount, data);
	}

	function mintBatch(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual onlyOwner {
        _mintBatch(to, ids, amounts, data);
	}

	function mintToBatch(
		address[] memory recipients,
		uint256[][] memory ids,
		bytes memory data
	) public virtual onlyOwner {
        require(recipients.length == ids.length, "MT: recipients and ids length mismatch");
		for (uint256 i = 0; i < recipients.length; ++i)
			_mintBatch(recipients[i], ids[i], _createAndFillArray(ids[i].length, 1), data);
	}

	function mintToBatch(
		address[] memory recipients,
		uint256 id
	) public virtual onlyOwner {
		for (uint256 i = 0; i < recipients.length; ++i)
			_mint(recipients[i], id, 1, '');
	}

	modifier ownerOrApproved(address tokenOwner) {
		require(tokenOwner == _msgSender() || isApprovedForAll(tokenOwner, _msgSender()), "MT: caller is not owner nor approved");
		_;
	}

	function burn(
		address from,
		uint256 id,
		uint256 amount
	) public virtual ownerOrApproved(from) {
        _burn(from, id, amount);
	}

	function burnBatch(
		address from,
		uint256[] memory ids,
		uint256[] memory amounts
	) public virtual ownerOrApproved(from) {
        _burnBatch(from, ids, amounts);
	}

	function burnFromBatch(
		address[] memory owners,
		uint256[][] memory ids
	) public virtual onlyOwner {
        require(owners.length == ids.length, "MT: owners and ids length mismatch");
		for (uint256 i = 0; i < owners.length; ++i)
			_burnBatch(owners[i], ids[i], _createAndFillArray(ids[i].length, 1));
	}

    function _createAndFillArray(uint256 count, uint256 value) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](count);
		for (uint256 i = 0; i < count; ++i)
        	array[i] = value;

        return array;
    }
}
