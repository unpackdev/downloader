// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract GoodMorningChongqing is Ownable, Pausable, ReentrancyGuard, ERC721 {
    using ECDSA for bytes32;

    event SafeMint(
        address indexed account,
        uint256 tokenId,
        uint256 price,
        uint256 mintTime
    );

    // bytes4(keccak256("transfer(address,uint256)"))
    bytes4 constant ERC20_TRANSFER_SELECTOR = 0xa9059cbb;

    // bytes4(keccak256("transferFrom(address,address,uint256)"))
    bytes4 constant ERC20_TRANSFERFROM_SELECTOR = 0x23b872dd;

    uint256 public constant BASE_10000 = 10_000;

    string public baseURI;

    address public payToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // Record the total number of paid NFTs
    uint256 private totalSafeMintNumber;

    // Record the total transaction volume of payment tokens
    uint256 private totalVolume;

    uint256 public totalSupply_MAX = 100;

    address private systemSigner;

    address[] private projectPartys;

    uint256[] private incomeDistributions;

    uint256[] private mintedTokenIds;

    // White Lists
    mapping(address => bool) private whiteLists;

    constructor(
        address[] memory _projectPartys,
        uint256[] memory _incomeDistributions,
        address _signer,
        string memory _baseURI_
    ) ERC721("GoodMorningChongqing", "GMCQ") {
        projectPartys = _projectPartys;

        incomeDistributions = _incomeDistributions;

        systemSigner = _signer;

        baseURI = _baseURI_;

        whiteLists[_msgSender()] = true;
    }

    function setPause() external onlyOwner {
        if (!paused()) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setIncomeDistribution(
        address[] calldata _projectPartys,
        uint256[] calldata _incomeDistributions
    ) external onlyOwner {
        projectPartys = _projectPartys;

        incomeDistributions = _incomeDistributions;
    }

    function setPayToken(address _payToken) external onlyOwner {
        payToken = _payToken;
    }

    function setBaseURI(string memory _baseURI_) external onlyOwner {
        baseURI = _baseURI_;
    }

    function setWhiteList(address _account) external onlyOwner {
        whiteLists[_account] = !whiteLists[_account];
    }

    function setMAX_totalSupply(uint256 _totalSupply_MAX) external onlyOwner {
        totalSupply_MAX = _totalSupply_MAX;
    }

    function getWhiteList(address _account) external view returns (bool) {
        return whiteLists[_account];
    }

    function getMintedTokenIds() external view returns (uint256[] memory) {
        return mintedTokenIds;
    }

    function getTotalSafeMintData()
        external
        view
        returns (uint256 number, uint256 volume)
    {
        return (totalSafeMintNumber, totalVolume);
    }

    function safeMint(
        uint256[] calldata _tokenIds,
        uint256[] memory _prices,
        address _receiver,
        uint256 _deadline,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant returns (bool) {
        address _account = _msgSender();

        uint256 _amount = _tokenIds.length;

        require(_amount > 0 && _amount == _prices.length, "Invalid paras");

        require(block.timestamp < _deadline, "Signature has expired");

        bytes memory _data = abi.encode(
            address(this),
            _account,
            _tokenIds,
            _prices,
            _receiver,
            _deadline
        );

        bytes32 _hash = keccak256(_data);

        _verifySignature(_hash, _signature);

        // mint NFT To _receiver
        uint256 _totalPayPrice = _mintNFT(_receiver, _tokenIds, _prices);

        unchecked {
            totalVolume += _totalPayPrice;

            totalSafeMintNumber += _amount;
        }

        // _account pay Token
        _payERC20Token(_account, _totalPayPrice);

        return true;
    }

    function swap(
        address _receiver,
        uint256[] calldata _tokenIds
    ) external onlyOwnerOrWhiteList whenNotPaused nonReentrant returns (bool) {
        uint256[] memory _prices = new uint[](_tokenIds.length);

        _mintNFT(_receiver, _tokenIds, _prices);

        return true;
    }

    function withdraw(
        address _target,
        address _account,
        uint256 _value
    ) external onlyOwner {
        _safeTransferERC20(_target, _account, _value);
    }

    function totalSupply() external view returns (uint256) {
        return mintedTokenIds.length;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _safeTransferERC20(
        address target,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = target.call(
            abi.encodeWithSelector(ERC20_TRANSFER_SELECTOR, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Low-level call failed"
        );
    }

    function _safeTransferFromERC20(
        address target,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = target.call(
            abi.encodeWithSelector(ERC20_TRANSFERFROM_SELECTOR, from, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Low-level call failed"
        );
    }

    modifier onlyOwnerOrWhiteList() {
        address _caller = _msgSender();

        require(owner() == _caller || whiteLists[_caller], "No permission");
        _;
    }

    function _verifySignature(
        bytes32 _hash,
        bytes calldata _signature
    ) internal view {
        _hash = _hash.toEthSignedMessageHash();

        address signer = _hash.recover(_signature);

        require(systemSigner == signer, "Invalid signature");
    }

    function _mintNFT(
        address _receiver,
        uint256[] calldata _tokenIds,
        uint256[] memory _prices
    ) internal returns (uint256) {
        uint256 _totalPayPrice;

        uint256 _amount = _tokenIds.length;

        for (uint256 i = 0; i < _amount; ++i) {
            uint256 _tokenId = _tokenIds[i];

            require(
                _tokenId > 0 && _tokenId <= totalSupply_MAX,
                "Invalid tokenId"
            );

            mintedTokenIds.push(_tokenId);

            _totalPayPrice += _prices[i];

            _safeMint(_receiver, _tokenId);

            emit SafeMint(_receiver, _tokenId, _prices[i], block.timestamp);
        }

        return _totalPayPrice;
    }

    function _payERC20Token(address _account, uint256 _totalPayPrice) internal {
        for (uint256 i = 0; i < projectPartys.length; ++i) {
            uint256 _amount0 = (_totalPayPrice * incomeDistributions[i]) /
                BASE_10000;

            _safeTransferFromERC20(
                payToken,
                _account,
                projectPartys[i],
                _amount0
            );
        }
    }
}
