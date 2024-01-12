// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./IAether.sol";

/**
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation.
 */
contract AetherWrapper is  ERC721URIStorage, Ownable {
    address public aetherAddress = payable(0x31d4C5be1082A88F2ABAFeA549B6C189C2cf057F);
    string private _baseTokenURI;
    uint256 private _tokenSupply;

    constructor() ERC721("Aether Wrapped", "AETHW") {
        _baseTokenURI = "https://api.aethercity.org/";
    }

    /**
     * @dev transfers Aether to the wrapper and assigns a wrapped token to msg.sender
     */
    function wrap(uint _aetherID) external {      
        require( IAether(aetherAddress).ownerOf(_aetherID)==msg.sender,"Only the owner can wrap a property.");
        IAether(aetherAddress).transferFrom(msg.sender,address(this),_aetherID);
        _tokenSupply +=1;
        _mint(msg.sender, _aetherID);
    }

    /**
     * @dev Burns the wrapper token and transfers the underlying Panda to the owner
     **/
    function unwrap(uint256 _aetherID) external {
        require(_isApprovedOrOwner(msg.sender, _aetherID));
        _burn(_aetherID);
        _tokenSupply -=1;
        IAether(aetherAddress).transfer(msg.sender,_aetherID);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Set a new base token URI
     */
    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) external view virtual returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _tokenSupply;
    }
}