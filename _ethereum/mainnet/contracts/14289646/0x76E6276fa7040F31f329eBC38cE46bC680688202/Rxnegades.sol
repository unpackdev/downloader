// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";

/**
 * @title Rxnegades
 */
contract Rxnegades is ERC721 {
    address private _owner;

    bool public SOLD_OUT = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping (uint256 => string) _tokenURI;

    string public baseURI;
    
    uint256 private nextTokenId = 0;
    uint256 private constant MAX_TOKEN_ID = 2**256 - 1;
    uint256 public constant TOKEN_PRICE = 0.0313 ether;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address safe,
        address developer,
        address artist
    ) ERC721(name_, symbol_) {
        _owner = safe;
        baseURI = baseURI_;

        _mintNextTo(safe);
        _mintNextTo(developer);
        _mintNextTo(artist);
    }

    /**
     * Gift Rxnegade Membership
     * @dev function that allows accounts to pay for a membership token for another account
     * @return tokenId
     */
    function gift(address to) public payable returns (uint256) {
        require(msg.value >= TOKEN_PRICE, "RXNGD: not enough ether sent");
        uint256 tokenId = _mintNextTo(to);
        payable(_owner).transfer(address(this).balance);
        return tokenId;
    }

    /**
     * Join Rxnegades
     * @dev function that allows accounts to pay for a membership token
     * @return tokenId
     */
    function join() public payable returns (uint256) {
        require(msg.value >= TOKEN_PRICE, "RXNGD: not enough ether sent");
        uint256 tokenId = _mintNextTo(msg.sender);
        payable(_owner).transfer(address(this).balance);
        return tokenId;
    }

    /**
     * Set Token URI
     * @dev function that allows approved or owner of the token to set the metadata URI
     * @param tokenId id of the token
     * @param tokenURI_ string URI of the metadata
     */
    function setTokenURI(uint256 tokenId, string memory tokenURI_) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "RXNGD: not approved or owner");
        _tokenURI[tokenId] = tokenURI_;
    }

    // PUBLIC VIEWS

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * Token URI
     * @dev function that gets the metadata URI for the token
     * @param tokenId the id of the token
     * @return the token URI set by the owner or the default
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (keccak256(bytes(_tokenURI[tokenId])) == keccak256(bytes(""))) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        }
        return _tokenURI[tokenId];
    }

    // ONLY OWNER

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "RXNGD: caller is not the owner");
        _;
    }

    /**
     * Honor
     * @dev grant an honorary membership token
     * @param to address to mint to
     */
    function honor(address to) public onlyOwner returns (uint256) {
        return _mintNextTo(to);
    }

    /**
     * Set Base URI
     * @dev function that allows the owner to update the base URI used for default token metadata
     * @param baseURI_ the default metadata URI
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "RXNGD: new owner can not be the zero address");
        _transferOwnership(newOwner);
    }

    // INTERNAL

    /**
     * @dev mints the next available token to the given address
     */
    function _mintNextTo(address to) internal returns (uint256) {
        require(!SOLD_OUT, "RXNGD: membership sold out");

        uint256 tokenId = nextTokenId;
        if (tokenId != MAX_TOKEN_ID) { 
            nextTokenId++; 
        } else {
            SOLD_OUT = true;
        }
        
        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
