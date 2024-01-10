// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./IERC1155MetadataURI.sol";
import "./AccessControl.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CandyTreats is AccessControl, ERC1155Supply {
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    mapping(uint256=>string) public tokenIdToUri;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256 public constant MAX_PER_EDITION = 50;


    constructor () ERC1155("ipfs://") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0xC7E97B7013Bd8574C7c76a25191D75E096dFf164);
        _setupRole(MINTER_ROLE, 0xC7E97B7013Bd8574C7c76a25191D75E096dFf164);
    }

    receive() external payable {}

    function setTokenIdURI(string memory newuri, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenIdToUri[tokenId] = newuri;
    }

    function setProxyRegistry(address preg) external onlyRole(DEFAULT_ADMIN_ROLE) {
        proxyRegistryAddress = preg;
    }

    function uri(uint _tokenId) public view override returns(string memory) {
        return tokenIdToUri[_tokenId];
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintTo(address _to, uint256 tokenId, uint256 amount) external onlyRole(MINTER_ROLE) {
        require (totalSupply(tokenId) + amount <= MAX_PER_EDITION, "reached max edition");
        _mint(_to, tokenId, amount, "");
    }

    function bulkMintTo(address[] memory _to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        uint256 amount = _to.length;
        require (totalSupply(tokenId) + amount <= MAX_PER_EDITION, "reached max edition");
        for (uint i = 0; i < amount; i++) {
            _mint(_to[i], tokenId, 1, "");
        }
    }

    function burn(address account, uint256 id, uint256 amount) external {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, amount);
    }

    function burnAsBurner(address account, uint256 id, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(account, id, amount);
    }

    // allow gasless listings on opensea
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}