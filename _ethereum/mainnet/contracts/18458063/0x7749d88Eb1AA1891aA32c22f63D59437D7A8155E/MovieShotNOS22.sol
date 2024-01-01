// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC721AOpensea.sol";
import "./AggregatorV3Interface.sol";
import "./MerkleProof.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//   ███    ███  ██████  ██    ██ ██ ███████ ███████ ██   ██  ██████  ████████ ███████   //
//   ████  ████ ██    ██ ██    ██ ██ ██      ██      ██   ██ ██    ██    ██    ██        //
//   ██ ████ ██ ██    ██ ██    ██ ██ █████   ███████ ███████ ██    ██    ██    ███████   //
//   ██  ██  ██ ██    ██  ██  ██  ██ ██           ██ ██   ██ ██    ██    ██         ██   //
//   ██      ██  ██████    ████   ██ ███████ ███████ ██   ██  ██████     ██    ███████   //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////

error NotAllowed();
error MintNotStarted();
error MintEnded();
error ExceededAllowance();
error NotOnAllowlist();
error ExceedsMaximumSupply();
error WithdrawFailed();
error WrongETHValueSent();

contract MovieShotNOS22 is ERC721AOpensea {
    uint256 public immutable MAX_SUPPLY;
    bytes32 public discount1MerkleRoot;
    bytes32 public discount2MerkleRoot;
    address public adminMinter;
    address public beneficiaryAddress;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public maxMintAmount;
    uint256 public publicSalePrice;
    uint256 public discountPrice1;
    uint256 public discountPrice2;

    AggregatorV3Interface internal priceFeed;

    string private _baseTokenURI;

    constructor(
        uint256 _maxSupply,
        uint256 _startTime,
        uint256 _endTime,
        address _adminMinter,
        address _beneficiaryAddress,
        address _owner,
        address _aggregatorAddress,
        string memory _baseUri
    ) ERC721A("MovieShots - Nosferatu", "MSHOT-NOS22") ERC721AOpensea(_owner) {
        publicSalePrice = 99 * 1e18;
        discountPrice1 = 90 * 1e18;
        discountPrice2 = 75 * 1e18;
        maxMintAmount = 12;
        startTime = _startTime;
        endTime = _endTime;
        _baseTokenURI = _baseUri;

        MAX_SUPPLY = _maxSupply;

        priceFeed = AggregatorV3Interface(_aggregatorAddress);

        _setDefaultRoyalty(_beneficiaryAddress, 420);
        adminMinter = _adminMinter;
        beneficiaryAddress = _beneficiaryAddress;
    }

    modifier mintRunning() {
        if (block.timestamp < startTime) {
            revert MintNotStarted();
        }

        if (block.timestamp > endTime) {
            revert MintEnded();
        }
        _;
    }

    modifier onlyAdminMinter() {
        if (adminMinter != _msgSender()) revert NotAllowed();
        _;
    }

    modifier supplyAvailable(uint256 numberOfTokens) {
        if (_totalMinted() + numberOfTokens > MAX_SUPPLY) {
            revert ExceedsMaximumSupply();
        }
        _;
    }

    function mint(
        uint8 quantity,
        address to
    ) external payable mintRunning supplyAvailable(quantity) {
        if (msgValueInUSD(msg.value) < publicSalePrice * quantity) {
            revert WrongETHValueSent();
        }

        uint256 alreadyMinted = _numberMinted(_msgSender()) -
            _getAux(_msgSender()) +
            quantity;

        if (quantity > maxMintAmount || alreadyMinted > maxMintAmount) {
            revert ExceededAllowance();
        }

        if (to == address(0x0)) {
            to = _msgSender();
        }

        _mint(to, quantity);
    }

    function discountMint(
        uint8 quantity,
        bool superDiscount,
        bytes32[] calldata merkleProof,
        address to
    ) external payable mintRunning supplyAvailable(quantity) {
        bytes32 leaf = keccak256(abi.encodePacked((_msgSender())));
        bool onAllowlist;
        uint256 price;

        if (!superDiscount) {
            price = discountPrice1;
            onAllowlist = MerkleProof.verifyCalldata(
                merkleProof,
                discount1MerkleRoot,
                leaf
            );
        } else {
            price = discountPrice2;
            onAllowlist = MerkleProof.verifyCalldata(
                merkleProof,
                discount2MerkleRoot,
                leaf
            );
        }

        if (!onAllowlist) {
            revert NotOnAllowlist();
        }

        if (msgValueInUSD(msg.value) < price * quantity) {
            revert WrongETHValueSent();
        }

        uint64 alreadyWhitelistMinted = _getAux(_msgSender()) + quantity;
        if (
            quantity > maxMintAmount || alreadyWhitelistMinted > maxMintAmount
        ) {
            revert ExceededAllowance();
        }
        _setAux(_msgSender(), alreadyWhitelistMinted);

        if (to == address(0x0)) {
            to = _msgSender();
        }

        _mint(to, quantity);
    }

    function adminMint(
        address recipient,
        uint8 quantity
    ) external onlyAdminMinter supplyAvailable(quantity) {
        _mint(recipient, quantity);
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setPriceFeed(address _aggregatorAddress) external onlyOwner {
        priceFeed = AggregatorV3Interface(_aggregatorAddress);
    }

    function setPrices(
        uint256 _publicSalePrice,
        uint256 _discountPrice1,
        uint256 _discountPrice2
    ) external onlyOwner {
        publicSalePrice = _publicSalePrice;
        discountPrice1 = _discountPrice1;
        discountPrice2 = _discountPrice2;
    }

    function setMerkleRoots(
        bytes32 _discount1MerkleRoot,
        bytes32 _discount2MerkleRoot
    ) external onlyOwner {
        discount1MerkleRoot = _discount1MerkleRoot;
        discount2MerkleRoot = _discount2MerkleRoot;
    }

    function setAdminMinter(address _adminMinter) external onlyOwner {
        adminMinter = _adminMinter;
    }

    function setBeneficiaryAddress(
        address _beneficiaryAddress
    ) external onlyOwner {
        beneficiaryAddress = _beneficiaryAddress;
    }

    function getLatestPrice() internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price >= 0 ? uint256(price * 1e10) : 0;
    }

    function msgValueInUSD(uint256 amount) public view returns (uint256) {
        uint256 currentETHPrice = getLatestPrice();
        uint256 ethAmountInUSD = (currentETHPrice * amount) / 1e18;
        return ethAmountInUSD;
    }

    function getAvailablePublicMints(
        address from
    ) public view returns (uint256) {
        return maxMintAmount - (_numberMinted(from) - _getAux(from));
    }

    function getAvailableDiscountMints(
        address from
    ) public view returns (uint256) {
        return maxMintAmount - _getAux(from);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(beneficiaryAddress).call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }
}
