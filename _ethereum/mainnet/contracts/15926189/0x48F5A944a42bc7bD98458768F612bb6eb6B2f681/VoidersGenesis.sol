// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

/**
 * @title VoidersGenesis
 * is ERC721A-compatible contract.
 */
contract VoidersGenesis is ERC721A, Ownable {
    using ECDSA for bytes32;

    address public immutable whitelistChecker;
    uint256 public constant maxTotalSupply = 888;
    uint256 public constant presalePrice = 0.25 ether;
    uint128 public immutable presaleStartTime;
    uint128 public immutable presaleEndTime;
    string private _baseContractURI;
    string private _contractURI;

    mapping(address => bool) public mintedFromWhitelist;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _newBaseURI,
        string memory _newContractURI,
        uint128 _presaleStartTime,
        address _treasury,
        address _whitelistChecker
    ) ERC721A(_name, _symbol) {
        _baseContractURI = _newBaseURI;
        _contractURI = _newContractURI;
        require(
            _whitelistChecker != address(0),
            "Whitelist checker cannot be 0"
        );
        whitelistChecker = _whitelistChecker;
        require(_treasury != address(0), "Invalid treasury address");
        _mintERC2309(_treasury, 25);
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleStartTime + 24 hours;
    }

    /**
     * @dev Mints a token to an approved address with discount.
     * @param signature of whitelisted address from whitelist checker
     */
    function presaleMint(bytes memory signature) external payable {
        require(
            keccak256(abi.encodePacked(msg.sender))
                .toEthSignedMessageHash()
                .recover(signature) == whitelistChecker,
            "You are not whitelisted"
        );
        require(
            block.timestamp >= presaleStartTime &&
                block.timestamp < presaleEndTime,
            "Presale is not active"
        );
        require(
            !mintedFromWhitelist[msg.sender],
            "You are already minted from whitelist"
        );
        require(msg.value == presalePrice, "Wrong amount of ETH");
        mintedFromWhitelist[msg.sender] = true;
        _mintTo(msg.sender, 1);
    }

    /**
     * @dev Mints the rest of the tokens to owner for selling.
     */
    function ownerMintForSell() external onlyOwner {
        require(
            block.timestamp > presaleEndTime,
            "Can sell only after presale"
        );
        uint256 numToMint = maxTotalSupply - totalSupply();
        _mintTo(msg.sender, numToMint);
    }

    /**
     * @dev Withdraws presell rewards.
     */
    function ownerWithdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Changes baseTokenURI.
     * @param _newBaseTokenURI new URI for all tokens
     */
    function changeBaseTokenURI(string memory _newBaseTokenURI)
        public
        onlyOwner
    {
        _baseContractURI = _newBaseTokenURI;
    }

    /**
     * @dev Changes baseContractURI.
     * @param _newContractURI new URI for all tokens
     */
    function changeContractURI(string memory _newContractURI) public onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @dev Returns contractURI.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns baseTokenURI.
     */
    function baseTokenURI() public view returns (string memory) {
        return _baseContractURI;
    }

    /**
     * @dev Returns baseTokenURI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseContractURI;
    }

    /**
     * @dev Returns URI for exact token.
     * @param _tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(_tokenId), ".json")
                )
                : "";
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to new URI for all tokens
     */
    function _mintTo(address _to, uint256 _quantity) internal {
        require(totalSupply() < maxTotalSupply, "Exceeds max supply of tokens");

        _mint(_to, _quantity);
    }
}
