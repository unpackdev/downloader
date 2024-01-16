//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";

/**
 * @title Contract for SmartWork Membership
 * Copyright 2022 SmartWork
 *
 * Contract deployed by CPI Technologies GmbH
 */
contract SmartWorkNFT is ERC721, Ownable {
    using Strings for uint;
    using Address for address;
    using Address for address payable;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    uint256 private _totalSupply;
    bool public _uriEditable = true;
    mapping(address => bool) private _mintAllowance;
    string private _pre;
    string private _post;

    event EthersWithdrawn(address indexed operator, address indexed to, uint amount);

    /**
     * @dev the metadata url should be replaced
     * @param totalSupply totalSupply
     */
    constructor(uint256 totalSupply) ERC721("SmartWork", "SWBC") {
        _totalSupply = totalSupply;
    }

    /**
     * Total supply of the tokens
     */
    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    /*
     * Allow a new minter address
     */
    function allowMint(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0) && !addresses[i].isContract(), "SmartWork: wrong address");
            _mintAllowance[addresses[i]] = true;
        }
    }

    /*
     * This function will mint multiple NFT tokens to multiple addresses given in an array
     */
    function bulkMint(address[] calldata addresses, uint number) external {
        if (!_mintAllowance[msg.sender]) {
            revert("SmartWork: You are not allowed to mint these special SmartWork tokens!");
        }

        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0) && !addresses[i].isContract(), "SmartWork: wrong address");
            require((_tokenIds.current() + number) <= _totalSupply, "SmartWork: the limit of the tokens is going to be exceeded");

            for (uint j = 0; j < number; j++) {
                _tokenIds.increment();
                uint newTokenId = _tokenIds.current();
                _mint(addresses[i], newTokenId);
            }
        }
    }

    /**
     * Check if a given address can mint NFTs
     */
    function checkMintingAllowance(address addr) external view returns (bool) {
        return _mintAllowance[addr];
    }

    /**
     * Get the address of a given token
     */
    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_pre, tokenId.toString(), _post));
    }

    /*
     * Performs a minting action to a given address. Can only be done by an authorized minter
     */
    function mint(address to, uint number) external {
        require(to != address(0) && !to.isContract(), "SmartWork: wrong address");
        require((_tokenIds.current() + number) <= _totalSupply, "SmartWork: the limit of the tokens is going to be exceeded");

        if (!_mintAllowance[msg.sender]) {
            revert("SmartWork: You are not allowed to mint these special SmartWork tokens!");
        }

        for (uint i = 0; i < number; i++) {
            _tokenIds.increment();
            uint newTokenId = _tokenIds.current();
            _mint(to, newTokenId);
        }
    }

    function withdrawEthers(uint amount, address payable to) public virtual onlyOwner {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }

    function setURI(string memory pre, string memory post) external onlyOwner {
        require(_uriEditable, "URI no more editable");
        _pre = pre;
        _post = post;
    }

    function disableSetURI() external onlyOwner {
        _uriEditable = false;
    }
}
