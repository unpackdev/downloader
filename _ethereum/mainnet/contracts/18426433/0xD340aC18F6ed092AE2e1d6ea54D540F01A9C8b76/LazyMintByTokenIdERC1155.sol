// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/*----------------------------------------------------------\
|                             _                 _           |
|        /\                  | |     /\        | |          |
|       /  \__   ____ _ _ __ | |_   /  \   _ __| |_ ___     |
|      / /\ \ \ / / _` | '_ \| __| / /\ \ | '__| __/ _ \    |
|     / ____ \ V / (_| | | | | |_ / ____ \| |  | ||  __/    |
|    /_/    \_\_/ \__,_|_| |_|\__/_/    \_\_|   \__\___|    |
|                                                           |
|    https://avantarte.com/careers                          |
|    https://avantarte.com/support/contact                  |
|                                                           |
\----------------------------------------------------------*/

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ISpecifiedMinter.sol";
import "./SimpleRoyalties.sol";

/**
 * @title A Lazy minting contract that can mint arbitrary token ids
 * @author Liron Navon
 * @notice this contract specified an address "minter" which is the only address that can call "mint"
 */
contract LazyMintByTokenIdERC1155 is
    ERC1155,
    SimpleRoyalties,
    Ownable,
    ISpecifiedMinter
{
    /// @dev only the minter address can call "mint"
    address public minter;

    string public name;

    constructor(
        string memory _name,
        address _minter,
        string memory _uri,
        address royaltiesReciever,
        uint256 royaltiesFraction
    ) ERC1155(_uri) SimpleRoyalties(royaltiesReciever, royaltiesFraction) {
        minter = _minter;
        name = _name;
    }

    modifier onlyMinter() {
        require(minter == msg.sender, "Unauthorized minter");
        _;
    }

    /**
     * @dev Mints a token to a given user
     */
    function _mintToken(address to, uint256 tokenId) private returns (uint256) {
        _mint(to, tokenId, 1, "");
        return tokenId;
    }

    /**
     * @dev Calls mint, only for requests of the minter address
     */
    function mint(
        address to,
        uint256 tokenId
    ) public onlyMinter returns (uint256) {
        return _mintToken(to, tokenId);
    }

    /**
     * @dev Calls mint, only for the contract owner
     */
    function ownerMint(
        address to,
        uint256 tokenId
    ) public onlyOwner returns (uint256) {
        return _mintToken(to, tokenId);
    }

    /**
     * @dev Set a new uri
     */
    function setUri(string calldata _uri) public onlyOwner {
        _setURI(_uri);
    }

    /**
     * @dev Set a new minter
     */
    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    /**
     * @dev Set new royalties for the contract
     */
    function setRoyalties(address reciever, uint256 fraction) public onlyOwner {
        _setRoyalty(reciever, fraction);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(SimpleRoyalties, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
