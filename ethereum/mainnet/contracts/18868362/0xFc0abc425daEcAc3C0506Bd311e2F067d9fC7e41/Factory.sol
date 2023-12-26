// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./OwnableUpgradeable.sol";
import "./XRC20.sol";
import "./XRC721.sol";

contract Factory is OwnableUpgradeable {
    uint256 public deployFee;

    uint256 public nextTokenId;

    address private _feeWallet;
    mapping(uint256 => uint8) private _contractType;
    mapping(uint256 => address) private _contractAddress;
    mapping(address => uint256) private _tokenId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __Ownable_init(initialOwner);
        nextTokenId = 1;
    }

    event TokenDeployed(
        uint256 indexed tokenId,
        uint8 indexed contractType,  // contractType: 1/XRC20, 2/XRC721
        address indexed contractAddress,
        address initialOwner
    );

    struct TokenInfo {
        bool exists;
        uint256 tokenId;
        uint8 contractType;
        address contractAddress;
        uint32 version;
        address owner;
        bool editable;
    }

    function getTokenInfoById(
        uint256 tokenId
    ) public view returns (TokenInfo memory) {
        return TokenInfo(
            tokenId == 0 || _contractAddress[tokenId] != address(0),
            tokenId,
            _contractType[tokenId],
            _contractAddress[tokenId],
            _contractType[tokenId] == 1 ? XRC20(_contractAddress[tokenId]).VERSION() : XRC721(_contractAddress[tokenId]).VERSION(),
            _contractType[tokenId] == 1 ? XRC20(_contractAddress[tokenId]).owner() : XRC721(_contractAddress[tokenId]).owner(),
            _contractType[tokenId] == 1 ? XRC20(_contractAddress[tokenId]).EDITABLE() : XRC721(_contractAddress[tokenId]).EDITABLE()
        );
    }

    function getTokenInfoByAddress(
        address contractAddress
    ) public view returns (TokenInfo memory) {
        uint256 tokenId = _tokenId[contractAddress];
        return getTokenInfoById(tokenId);
    }

    function getAllTokenAddressByOwnerAddress(
        address ownerAddress
    ) public view returns (address[] memory) {
        if (ownerAddress == address(0)) {
            return new address[](0);
        }

        address[] memory allTokens = new address[](nextTokenId - 1);
        uint256 index = 0;

        for (uint256 i = 1; i < nextTokenId; i++) {
            if (
                _contractAddress[i] != address(0) &&
                (
                    _contractType[i] == 1 ?
                        XRC20(_contractAddress[i]).owner() :
                        XRC721(_contractAddress[i]).owner()
                ) == ownerAddress
            ) {
                allTokens[index] = _contractAddress[i];
                index++;
            }
        }

        address[] memory result = new address[](index);

        for (uint256 i = 0; i < index; i++) {
            result[i] = allTokens[i];
        }

        return result;
    }

    function getAllTokenInfoByOwnerAddress(
        address ownerAddress
    ) public view returns (TokenInfo[] memory) {
        address[] memory tokenAddresses = getAllTokenAddressByOwnerAddress(ownerAddress);

        TokenInfo[] memory result = new TokenInfo[](tokenAddresses.length);

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            result[i] = getTokenInfoByAddress(tokenAddresses[i]);
        }

        return result;
    }

    function deploy20(
        address tokenOwner,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 maxSupply,
        uint8 decimals,
        uint256 tokenPerMint,
        uint256 miningDifficulty,
        bool editable
    ) external payable takeFee {
        require(maxSupply % tokenPerMint == 0, "mintAmountPerTransaction must be a divisor of maxSupply");
        require(miningDifficulty > 0, "Difficulty can not be zero");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        XRC20 token = new XRC20(
            tokenId,
            tokenOwner,
            tokenName,
            tokenSymbol,
            maxSupply,
            decimals,
            tokenPerMint,
            miningDifficulty,
            editable
        );

        _contractType[tokenId] = 1;
        _contractAddress[tokenId] = address(token);
        _tokenId[address(token)] = tokenId;

        emit TokenDeployed(tokenId, 1, address(token), tokenOwner);
    }

    function deploy721(
        address tokenOwner,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 maxSupply,
        string memory baseURI,
        uint256 miningDifficulty,
        bool editable
    ) external payable takeFee {
        require(miningDifficulty > 0, "Difficulty can not be zero");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        XRC721 token = new XRC721(
            tokenId,
            tokenOwner,
            tokenName,
            tokenSymbol,
            maxSupply,
            baseURI,
            miningDifficulty,
            editable
        );

        _contractType[tokenId] = 2;
        _contractAddress[tokenId] = address(token);
        _tokenId[address(token)] = tokenId;

        emit TokenDeployed(tokenId, 2, address(token), tokenOwner);
    }

    function setDeployFee(uint256 fee, address wallet) external onlyOwner {
        deployFee = fee;
        _feeWallet = wallet;
    }

    modifier takeFee() {
        require(msg.value >= deployFee, "Insufficient deploy fee");
        payable(_feeWallet).transfer(msg.value);
        _;
    }
}
