// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProof.sol";
import "./ERC1155SupplyUpgradeable.sol";

contract SevenArtBase1155Slim is ERC1155SupplyUpgradeable, OwnableUpgradeable {
    uint256 public curatedDropAmount;
    address public sevenArt;
    uint256 public constant FEE = 770000000000000;
    uint256[] public createdArray;

    struct TokenProps {
        bool saleIsActive;
        bool allowlistActive;
        string uri;
        uint256 price;
        uint256 startDate;
        uint256 endDate;
        uint256 maxPerWallet;
        uint256 maxSupply;
        bytes32 merkleRoot;
    }

    mapping(uint256 => TokenProps) public tokenProperties;
    mapping(address user => mapping(uint256 token => uint256 minted))
        public tokensMintedByUser;
    mapping(uint256 => bool) public tokenAlreadyExists;

    function initialize(address _sevenArt) public initializer {
        sevenArt = _sevenArt;
        __ERC1155Supply_init();
        __Ownable_init();
    }

    modifier tokenExists(uint256 _id) {
        require(tokenAlreadyExists[_id], "Initialize token first");
        _;
    }

    function getCreatedArray() public view returns (uint256[] memory) {
        return createdArray;
    }

    function setSaleIsActive(
        bool _saleIsActive,
        uint256 _id
    ) public onlyOwner tokenExists(_id) {
        tokenProperties[_id].saleIsActive = _saleIsActive;
    }

    function setAllowlistActive(
        bool _allowlistActive,
        uint256 _id
    ) public onlyOwner tokenExists(_id) {
        tokenProperties[_id].allowlistActive = _allowlistActive;
    }

    function setURI(
        string memory _uri,
        uint256 _id
    ) public onlyOwner tokenExists(_id) {
        tokenProperties[_id].uri = _uri;
    }

    function setPrice(
        uint256 _price,
        uint256 _id
    ) public onlyOwner tokenExists(_id) {
        tokenProperties[_id].price = _price;
    }

    function setStartDate(
        uint256 _startDate,
        uint256 _id
    ) public onlyOwner tokenExists(_id) {
        tokenProperties[_id].startDate = _startDate;
    }

    function setEndDate(
        uint256 _endDate,
        uint256 _id
    ) public onlyOwner tokenExists(_id) {
        tokenProperties[_id].endDate = _endDate;
    }

    function setMaxPerWallet(
        uint256 _maxPerWallet,
        uint256 _id
    ) public onlyOwner tokenExists(_id) {
        tokenProperties[_id].maxPerWallet = _maxPerWallet;
    }

    function setMaxSupply(
        uint256 _maxSupply,
        uint256 _id
    ) public onlyOwner tokenExists(_id) {
        tokenProperties[_id].maxSupply = _maxSupply;
    }

    function setMerkleRoot(
        bytes32 _merkleRoot,
        uint256 _id
    ) public onlyOwner tokenExists(_id) {
        tokenProperties[_id].merkleRoot = _merkleRoot;
    }

    function setCuratedDropAmount(uint256 _percent) public {
        require(msg.sender == sevenArt, "only sevenart can set this");
        require(_percent <= 50, "only 1-50 allowed");
        {
            curatedDropAmount = _percent;
        }
    }

    function mint(
        uint256 _id,
        uint256 _amount,
        uint256 _allowed,
        bytes32[] calldata _proof
    ) public payable {
        require(tokenProperties[_id].saleIsActive, "Sale is not active");
        require(checkSaleSchedule(_id), "Not at this time");
        require(
            tokenProperties[_id].maxSupply == 0 ||
                totalSupply(_id) + _amount <= tokenProperties[_id].maxSupply,
            "Sold out"
        );
        require(
            tokenProperties[_id].maxPerWallet == 0 ||
                tokensMintedByUser[msg.sender][_id] + _amount <=
                tokenProperties[_id].maxPerWallet,
            "Reached wallet limit"
        );
        if (tokenProperties[_id].allowlistActive) {
            require(
                tokensMintedByUser[msg.sender][_id] + _amount <= _allowed,
                "Can't mint more"
            );
            require(
                isWhitelisted(msg.sender, _allowed, _id, _proof),
                "Not whitelisted"
            );
        }

        require(
            (_amount * tokenProperties[_id].price) + FEE * _amount <= msg.value,
            "Not enough ETH"
        );
        tokensMintedByUser[msg.sender][_id] += _amount;
        _mint(msg.sender, _id, _amount, "");
        (bool os, ) = payable(sevenArt).call{value: FEE * _amount}("");
        require(os);
    }

    function setAllTokenProps(
        TokenProps memory _props,
        uint256 _id
    ) public onlyOwner {
        tokenProperties[_id] = _props;
        if (!tokenAlreadyExists[_id]) {
            createdArray.push(_id);
        }
        tokenAlreadyExists[_id] = true;
    }

    function withdraw() public {
        require(
            msg.sender == sevenArt || msg.sender == owner(),
            "caller is not the owner / sevenart"
        );
        uint256 curatedDropSplit = (address(this).balance * curatedDropAmount) /
            100;
        (bool os, ) = payable(sevenArt).call{value: curatedDropSplit}("");
        require(os);

        (os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function checkSaleSchedule(uint256 _id) internal view returns (bool) {
        if (
            (tokenProperties[_id].startDate == 0 ||
                tokenProperties[_id].startDate <= block.timestamp) &&
            (tokenProperties[_id].endDate == 0 ||
                tokenProperties[_id].endDate >= block.timestamp)
        ) {
            return true;
        }
        return false;
    }

    function isWhitelisted(
        address _address,
        uint256 _allowed,
        uint256 _id,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encode(_address, _allowed));
        return
            MerkleProof.verify(
                _merkleProof,
                tokenProperties[_id].merkleRoot,
                leaf
            );
    }

    function airdropManyTokens(
        address[] calldata wallets,
        uint256[] calldata tokenIds,
        uint256[] calldata amount
    ) public onlyOwner {
        require(
            wallets.length == tokenIds.length &&
                wallets.length == amount.length &&
                tokenIds.length == amount.length,
            "Inputs must be the same length"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenAlreadyExists[tokenIds[i]], "Initialize token first");
            _mint(wallets[i], tokenIds[i], amount[i], "");
        }
    }

    function uri(
        uint256 tokenId
    )
        public
        view
        virtual
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return tokenProperties[tokenId].uri;
    }
}
