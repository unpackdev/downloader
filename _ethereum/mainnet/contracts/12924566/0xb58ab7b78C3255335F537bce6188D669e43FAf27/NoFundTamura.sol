// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.6;

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./HasContractURI.sol";

contract NoFundTamura is ERC1155Burnable, Ownable, AccessControlEnumerable, HasContractURI {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _uri;
    mapping(uint256 => string) private tokenMetadataCidList;

    constructor(
        string memory __uri,
        string memory contractURI,
        address artist
    )
    ERC1155(__uri)
    HasContractURI(contractURI)
    {
        _uri = __uri;
        _setupRole(DEFAULT_ADMIN_ROLE, artist);
        _setupRole(MINTER_ROLE, artist);
        transferOwnership(artist);
    }

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role to mint");
        _;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string calldata tokenMetadataCid
    ) external onlyMinter {
        require(!exists(id), "Token is already minted");
        setMetadataCid(id, tokenMetadataCid);

        _mint(to, id, amount, "");
    }

    function additionalMint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyMinter {
        require(exists(id), "Token is not minted yet");
        _mint(to, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] calldata _tokenMetadataCidList
    ) external onlyMinter {
        require(ids.length == _tokenMetadataCidList.length, "must be same length");

        for (uint256 i = 0; i < _tokenMetadataCidList.length; i++) {
            require(!exists(ids[i]), "Token is already minted");
            setMetadataCid(ids[i], _tokenMetadataCidList[i]);
        }

        _mintBatch(to, ids, amounts, "");
    }

    function additionalMintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyMinter {
        for (uint256 i = 0; i < ids.length; i++) {
            require(exists(ids[i]), "Token is not minted yet");
        }

        _mintBatch(to, ids, amounts, "");
    }

    function exists(uint256 id) public view returns (bool) {
        return
        keccak256(abi.encodePacked(tokenMetadataCidList[id]))
        != keccak256(abi.encodePacked(""));
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(exists(id), "URI query for nonexistent token");

        return bytes(_uri).length > 0
        ? string(abi.encodePacked(_uri, tokenMetadataCidList[id]))
        : '';
    }

    function setMetadataCid(uint256 id, string memory tokenMetadataCid) internal {
        require(
            keccak256(abi.encodePacked(tokenMetadataCid)) != keccak256(abi.encodePacked("")),
            "Metadata cid must be non-empty"
        );

        tokenMetadataCidList[id] = tokenMetadataCid;
    }

    function setContractURI(string memory contractURI) external onlyOwner {
        _setContractURI(contractURI);
    }

    function setURI(string memory newURI) external onlyOwner {
        _uri = newURI;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC1155, HasContractURI)
    returns (bool)
    {
        return
        AccessControlEnumerable.supportsInterface(interfaceId) ||
        ERC1155.supportsInterface(interfaceId) ||
        HasContractURI.supportsInterface(interfaceId);
    }
}
