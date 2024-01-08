/**
 * LiquidCraft NFT Contract
 *
 * author: Solulab Inc. - Parth Kaloliya
 *
 * SPDX-License-Identifier: UNLICENSED
 */

pragma solidity 0.8.0;

import "./Counters.sol";
import "./ERC1155.sol";
import "./AccessControl.sol";

contract LCNFT is ERC1155, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private Id;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct nftGenerateInfo {
        address creator;
        uint256 royalty;
        address nftContractAddress;
        uint256 nftTokenId;
        string tokenURI;
        uint256 timeOfGenerate;
    }

    mapping(uint256 => nftGenerateInfo) nftLogs;
    mapping(uint256 => address) creator;
    mapping(uint256 => address) owner;
    mapping(uint256 => mapping(address => uint256)) royalty;

    event Mint(
        uint256 tokenId,
        uint256 qty,
        string uri,
        address tokenOwner,
        nftGenerateInfo newNFT
    );

    constructor(string memory _uri) ERC1155(_uri) {
        _setURI(_uri);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function addAdminRole(address _admin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_admin != address(0), "Admin Address cannot be zero address.");
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function addMinterRole(address _minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _minter != address(0),
            "Minter Address cannot be zero address."
        );
        _setupRole(MINTER_ROLE, _minter);
    }

    function mint(
        uint256 amount,
        uint256 Royalty,
        string memory newuri
    ) external onlyRole(MINTER_ROLE) returns (nftGenerateInfo memory) {
        uint256 _Id = Id.current();
        _setURI(newuri);
        nftGenerateInfo memory newNft = nftGenerateInfo({
            creator: msg.sender,
            royalty: Royalty,
            nftContractAddress: address(this),
            nftTokenId: _Id,
            tokenURI: newuri,
            timeOfGenerate: block.timestamp
        });
        nftLogs[_Id] = newNft;
        creator[_Id] = msg.sender;
        owner[_Id] = msg.sender;
        royalty[_Id][msg.sender] = Royalty;

        emit Mint(_Id, amount, newuri, owner[_Id], newNft);
        Id.increment();

        _mint(msg.sender, _Id, amount, "");
        return newNft;
    }

    function getRoyalty(uint256 id, address _creator)
        external
        view
        returns (uint256)
    {
        return royalty[id][_creator];
    }

    function getOwner(uint256 id) external view returns (address) {
        return owner[id];
    }

    function getCreator(uint256 id) external view returns (address) {
        return creator[id];
    }

    function getNFTDetails(uint256 id)
        external
        view
        returns (nftGenerateInfo memory)
    {
        return nftLogs[id];
    }
}
