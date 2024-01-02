// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";
import "./IBackerNFT.sol";

contract BackerNFT is ERC721Enumerable, IBackerNFT {
    uint256 private nftId = 0;
    string private baseUri;
    mapping(address => bool) private minters;
    bool private transferable;
    address private owner;

    modifier onlyMinter() {
        require(minters[_msgSender()], "Caller is not minter");
        _;
    }

    modifier onlyOwner() {
        require(_msgSender() == owner, "Caller is not owner");
        _;
    }

    constructor(string memory _nftName, string memory _nftSymbol, address _minter, address _owner, string memory _baseUri, bool _transferable) ERC721(_nftName, _nftSymbol) {
        baseUri = _baseUri;
        transferable = _transferable;
        minters[_minter] = true;
        owner = _owner;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        require(bytes(_baseUri).length > 0, "Base URI is required");
        baseUri = _baseUri;
        emit ChangedBaseURI(_baseUri);
    }

    function updateMinter(address _minter, bool _persmission) external override onlyOwner {
        require(_minter != address(0), "Minter must not be zero address");
        require(minters[_minter] != _persmission, "Minter already added");
        minters[_minter] = _persmission;
    }

    function setTransferable(bool _transferable) external onlyOwner {
        transferable = _transferable;
    }

    function mint(address _receiver) public override onlyMinter {
        nftId++;
        _safeMint(_receiver, nftId);
        emit TokenCreated(_receiver, nftId, block.timestamp);
    }

    function mintBatch(address _receiver, uint256 _amount) external override onlyMinter {
        require(_receiver != address(0), "Receiver can not be zero address");
        uint256[] memory ids = new uint256[](_amount);
        for(uint256 i = 0; i < ids.length; i++){
            mint(_receiver);
        }
    }

    function burn(uint256 _id) external override onlyMinter {
        require(
            _isApprovedOrOwner(_msgSender(), _id),
            "ERC721: caller is not approved or owner"
        );
        _burn(_id);
    }

    function burnBatch(uint256[] calldata _ids)
        external
        override
        onlyMinter
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _isApprovedOrOwner(_msgSender(), _ids[i]),
                "ERC721: caller is not approved or owner"
            );
            _burn(_ids[i]);
        }
    }

    function getAllNftOfUser(address _address)
        external
        view
        returns (
        uint256[] memory,
        string[] memory
        )
    {  
        require(_address != address(0), "Address can not be zero address");
        uint256 arrayLength = balanceOf(_address);
        uint256[] memory nftIds = new uint256[](arrayLength);
        string[] memory URIs = new string[](arrayLength);

        for (uint256 index = 0; index < arrayLength; index++) {
            uint256 _nftId = tokenOfOwnerByIndex(_address, index);
            if (_nftId == 0) {
                continue;
            }
            nftIds[index] = _nftId;
            string memory uri = tokenURI(_nftId);
            URIs[index] = uri;
        }
        return (nftIds, URIs);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseUri, Strings.toString(_tokenId)));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(transferable, "disabled");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not approved or owner"
        );
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(transferable, "disabled");
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(transferable, "disabled");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not approved or owner"
        );
        _safeTransfer(from, to, tokenId, _data);
    }
}