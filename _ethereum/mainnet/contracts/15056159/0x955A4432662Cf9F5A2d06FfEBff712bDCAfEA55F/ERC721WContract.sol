//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Holder.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

contract ERC721WContract is ERC721Enumerable, ERC721Holder, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address private wrappedContract;
    address private creator;

    mapping(uint256 => EnumerableSet.AddressSet) tokenId2AuthroizedAddresses;
    mapping(uint256 => mapping(address=> string)) tokenId2Address2Value;

    string private _contractURI;

    event TokenAuthorized (uint256 indexed tokenId, address indexed addr);

    event TokenRevoked (uint256 indexed tokenId, address indexed addr);

    event TokenValueUpdated (uint256 indexed tokenId, address indexed addr, string value);

    event TokenWrapped (uint256 indexed tokenId);

    event TokenUnwrapped (uint256 indexed tokenId);

    constructor(string memory name, string memory symbol,
                address _wrappedContract, address _creator,
                string memory contractURI) ERC721(name, symbol) {
        require(
            (ERC165)(_wrappedContract).supportsInterface(
                type(IERC721).interfaceId
            ),
            "IERC721"
        );
        require(
            (ERC165)(_wrappedContract).supportsInterface(
                type(IERC721Metadata).interfaceId
            ),
            "not support IERC721Metadata"
        );

        wrappedContract = _wrappedContract;
        creator = _creator;
        _contractURI = contractURI;

        _transferOwnership(_creator);
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(_msgSender() == ownerOf(tokenId), "should be the token owner");
        _;
    }

    modifier onlyAuthroized(uint256 tokenId) {
        require(tokenId2AuthroizedAddresses[tokenId].contains(_msgSender()), "address should be authorized");
        _;
    }

    // ======= start entry
    function setValue(uint256 tokenId, string calldata value) public onlyAuthroized(tokenId) {
        tokenId2Address2Value[tokenId][_msgSender()] = value;

        emit TokenValueUpdated(tokenId, _msgSender(), value);
    }

    function getValue(uint256 tokenId, address addr) public view returns (string memory) {
        return tokenId2Address2Value[tokenId][addr];
    }

    function authorize(uint256 tokenId, address authorizedAddress) public onlyTokenOwner(tokenId) {
        require(!tokenId2AuthroizedAddresses[tokenId].contains(authorizedAddress), "address already authorized");

        tokenId2AuthroizedAddresses[tokenId].add(authorizedAddress);

        emit TokenAuthorized(tokenId, authorizedAddress);
    }

    function revoke(uint256 tokenId, address addr) public onlyTokenOwner(tokenId) {
        tokenId2AuthroizedAddresses[tokenId].remove(addr);
        delete tokenId2Address2Value[tokenId][addr];

        emit TokenRevoked(tokenId, addr);
    }

    function revokeAll(uint256 tokenId) public onlyTokenOwner(tokenId) {
        for (uint256 i = tokenId2AuthroizedAddresses[tokenId].length() - 1;i > 0; i--) {
            address addr = tokenId2AuthroizedAddresses[tokenId].at(i);
            tokenId2AuthroizedAddresses[tokenId].remove(addr);
            delete tokenId2Address2Value[tokenId][addr];

            emit TokenRevoked(tokenId, addr);
        }

        if (tokenId2AuthroizedAddresses[tokenId].length() > 0) {
            address addr = tokenId2AuthroizedAddresses[tokenId].at(0);
            tokenId2AuthroizedAddresses[tokenId].remove(addr);
            delete tokenId2Address2Value[tokenId][addr];

            emit TokenRevoked(tokenId, addr);

        }
    }

    function isAddressAuthroized(uint256 tokenId, address addr) public view returns (bool) {
        return tokenId2AuthroizedAddresses[tokenId].contains(addr);
    }

    // ======= start wrap

    function wrap(uint256 tokenId) public {
        require((IERC721)(wrappedContract).ownerOf(tokenId) == _msgSender(), "should own tokenId");
        require((IERC721)(wrappedContract).getApproved(tokenId) == address(this), "should approve tokenId first");

        (IERC721)(wrappedContract).safeTransferFrom(_msgSender(), address(this), tokenId);

        if (_exists(tokenId) && ownerOf(tokenId) == address(this)) {
            _safeTransfer(address(this), _msgSender(), tokenId, "");
        } else {
            _safeMint(_msgSender(), tokenId);
        }

        emit TokenWrapped(tokenId);
    }

    function unwrap(uint256 tokenId) public onlyTokenOwner(tokenId) {
        (IERC721)(wrappedContract).safeTransferFrom(address(this), _msgSender(), tokenId);

        if (tokenId2AuthroizedAddresses[tokenId].length() != 0) {
            revokeAll(tokenId);
        }

        safeTransferFrom(_msgSender(), address(this), tokenId);
        emit TokenUnwrapped(tokenId);
    }

    // ======= start meta data views

    function getWrappedContract() public view returns (address) {
        return wrappedContract;
    }

    function getCreator() public view returns (address) {
        return creator;
    }

    // !!expensive, should call only when no gas is needed;
    function getAuthroizedAddresses(uint256 tokenId) external view returns (address[] memory) {
        return tokenId2AuthroizedAddresses[tokenId].values();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        return (IERC721Metadata)(wrappedContract).tokenURI(tokenId);
    }

    function contractURI() public view returns (string memory) {
        // throw error to make opensea ignore empty contractURI
        require(bytes(_contractURI).length != 0, "_contractURI is empty");

        return _contractURI;
    }

    function setContractURI(string calldata uri) public onlyOwner {
        _contractURI = uri;
    }
}
