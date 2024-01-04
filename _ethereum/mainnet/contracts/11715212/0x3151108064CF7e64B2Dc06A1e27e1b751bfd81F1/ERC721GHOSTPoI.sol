// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./AccessControl.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Address.sol";
import "./ERC721.sol";
import "./ERC721Pausable.sol";


/**
 * @title ERC721GHOSTPoI Metadata & Mintable functionality
 * @dev {ERC721} token, including:
 *
 * - a minter role that allows for token minting (creation)
 * - a pauser role that allows to stop all token transfers
 */
contract ERC721GHOSTPoI is Context, AccessControl, ERC721Pausable {

	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

	Counters.Counter private _tokenIdTracker;


	/**
	 * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
	 * account that deploys the contract.
	 */
	constructor () ERC721("Know Your Customer", "KYC") {
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		
		_setupRole(MINTER_ROLE, _msgSender());
		_setupRole(PAUSER_ROLE, _msgSender());	
	}


    /**
     * @dev Function to mint tokens.
     *
     * Requirements:
     *
     * - can not mint ti smart contract
     * - only one token can be minted
     *
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @param tokenURI The token URI of the minted token.
     */
    function mint(address to, uint256 tokenId, string memory tokenURI) public virtual {
	require(!Address.isContract(to), "can not be smart contract");
	require(balanceOf(to) == 0, "only 1 kyc for address");

        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }


	/**
	 * @dev Pauses all token transfers.
	 *
	 * See {ERC721Pausable} and {Pausable-_pause}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `PAUSER_ROLE`.
	 */
	function pause() public virtual {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		_pause();
	}

	
	/**
	 * @dev Unpauses all token transfers.
	 *
	 * See {ERC721Pausable} and {Pausable-_unpause}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `PAUSER_ROLE`.
	 */
	function unpause() public virtual {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		_unpause();
	}


}
