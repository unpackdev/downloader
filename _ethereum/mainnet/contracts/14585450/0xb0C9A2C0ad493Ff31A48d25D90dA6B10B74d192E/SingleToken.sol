// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";

contract SingleToken is ERC721, Ownable {
    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _baseUri;

	constructor(string memory name_, string memory symbol_, string memory baseUri_) ERC721(name_, symbol_) {
		_baseUri = baseUri_;
	}

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function setBaseURI(string memory newuri) public onlyOwner {
		_baseUri = newuri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address tokenOwner, address operator) public view virtual override returns (bool) {
        return ERC721.isApprovedForAll(tokenOwner, operator) || (operator == owner());
    }

	function mintToBatch(
		address[] memory recipients,
		uint256[][] memory ids,
		bytes memory data
	) public virtual onlyOwner {
        require(recipients.length == ids.length, "ST: recipients and ids length mismatch");
		for (uint256 i = 0; i < recipients.length; ++i) {
			for (uint256 k = 0; k < ids[i].length; ++k) {
				_safeMint(recipients[i], ids[i][k], data);
			}
		}
	}

	function mintToBatch(address[] memory recipients, uint256) public virtual onlyOwner {
		for (uint256 i = 0; i < recipients.length; ++i)
			_safeMint(recipients[i], i, '');
	}

	function burn(uint256 id) public virtual {
		require(_isApprovedOrOwner(_msgSender(), id), "ST: caller is not owner nor approved");
        _burn(id);
	}

	function burnFromBatch(uint256[] memory ids) public virtual onlyOwner {
		for (uint256 i = 0; i < ids.length; ++i)
			_burn(ids[i]);
	}
}
