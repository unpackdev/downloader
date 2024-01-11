// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC2981.sol";
import "./IERC721AQueryable.sol";
import "./console.sol";
import "./Strings.sol";

contract IdiotMedicine is ERC1155, ERC2981, Ownable {
    using Address for address payable;
    using Strings for uint256;
    uint256 private immutable goldenMaxSupply;
    uint256 private immutable goldenPrice;
    uint256 private immutable goldenWalletLimit;
    uint256 private goldenMinted;
    uint256 private teamMinted;
    mapping(address => uint256) private goldenWalletMinted;

    bool private mintStarted = false;
    string private baseURI;
    mapping(address => bool) private idiotGreenClaimed;

    address private burnerAddress;
    IERC721AQueryable private immutable idiotContract;

    constructor(
        string memory _uri,
        uint256 _goldenMaxSupply,
        uint256 _goldenWalletLimit,
        uint256 _goldenPrice,
        address _idiotContractAdress
    ) ERC1155(_uri) {
        goldenMaxSupply = _goldenMaxSupply;
        goldenWalletLimit = _goldenWalletLimit;
        goldenPrice = _goldenPrice;
        idiotContract = IERC721AQueryable(_idiotContractAdress);
        baseURI = _uri;
        setFeeNumerator(800);
    }

    function claimGreen() external {
        require(mintStarted, "Claim not started");
        require(idiotGreenClaimed[msg.sender] != true, "already claimed");
        uint256 amount = idiotContract.balanceOf(msg.sender);
        require(amount > 0, "have no idiots or claimed alreay");
        idiotGreenClaimed[msg.sender] = true;
        _mint(msg.sender, 1, amount, "");
    }

    function buyGolden(uint32 amount) external payable {
        uint256 requiredFund = amount * goldenPrice;
        require(mintStarted, "Mint not started");
        require(amount + goldenMinted <= goldenMaxSupply, "Exceed max supply");
        require(msg.value >= requiredFund, "Insufficient fund");
        require(
            amount + goldenWalletMinted[msg.sender] <= goldenWalletLimit,
            "Exceed wallet limit"
        );
        goldenMinted += amount;
        goldenWalletMinted[msg.sender] += amount;
        _mint(msg.sender, 0, amount, "");
        if (msg.value > requiredFund) {
            payable(msg.sender).sendValue(msg.value - requiredFund);
        }
    }

    function setStarted(bool value) external onlyOwner {
        mintStarted = value;
    }

    function burnGolden(address from, uint256 amount) external {
        require(msg.sender == burnerAddress, "No auth");
        _burn(from, 0, amount);
    }

    function burnGreen(address from, uint256 amount) external {
        require(msg.sender == burnerAddress, "No auth");
        _burn(from, 1, amount);
    }

    function teamMintGolden(address to, uint32 amount) external onlyOwner {
        teamMinted += amount;
        _mint(to, 0, amount, "");
    }

    function teamMintGreen(address to, uint32 amount) external onlyOwner {
        _mint(to, 1, amount, "");
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setBurner(address _burner) external onlyOwner {
        burnerAddress = _burner;
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeId == 0 || typeId == 1, "typeId error");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getGoldenPrice() public view returns (uint256) {
        return goldenPrice;
    }

    function getGoldenMinted() public view returns (uint256) {
        return goldenMinted;
    }

    function getTeamMinted() public view returns (uint256) {
        return teamMinted;
    }

    function getGoldenWalletLimit() public view returns (uint256) {
        return goldenWalletLimit;
    }

    function getGoldenMaxSupply() public view returns (uint256) {
        return goldenMaxSupply;
    }

    function isStarted() public view returns (bool) {
        return mintStarted;
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}
