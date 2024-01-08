// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./ERC721.sol";
import "./Ownable.sol";

contract Crates is ERC721, Ownable {
    uint256 private maxCratesSupply;
    uint256 public totalSupply;
    uint256 private pricePerUnit;
    uint256 public allTimeBalance;
    string private tokenURIBase;
    mapping(address => uint256) private shares;
    mapping(address => uint256) private withdrawals;
    bool private areSalesOpen;

    constructor(
        address _holder1,
        uint256 _amountHolder1,
        address _holder2,
        uint256 _amountHolder2
    ) ERC721("NFT2040 Crates", "NFT2040C") {
        shares[_holder1] = _amountHolder1;
        shares[_holder2] = _amountHolder2;
        pricePerUnit = 100000000000000000;
        maxCratesSupply = 1;
    }

    function increaseCratesSupply(uint256 _amount, uint256 _pricePerUnit)
        external
        onlyOwner
    {
        maxCratesSupply += _amount;
        pricePerUnit = _pricePerUnit;
    }

    function setAreSalesOpen(bool _areSaleOpen) external onlyOwner {
        areSalesOpen = _areSaleOpen;
    }

    function mint(address _to) external onlyOwner {
        super._safeMint(_to, totalSupply);
        totalSupply += 1;
    }

    function buy(uint256 _numberOfCrates) external payable {
        require(areSalesOpen, "Sales are not open");
        require(_numberOfCrates <= 5, "5 max units per tx");
        require(_numberOfCrates > 0, "Must be positive");
        require(
            (totalSupply + _numberOfCrates) < maxCratesSupply,
            "Exceeds max supply"
        );
        require(
            (_numberOfCrates * pricePerUnit) == msg.value,
            "Invalid ether value"
        );

        for (uint256 i = 0; i < _numberOfCrates; i++) {
            super._safeMint(_msgSender(), totalSupply);
            totalSupply += 1;
        }

        allTimeBalance += msg.value;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenURIBase;
    }

    function setTokenURIBase(string calldata _base) external onlyOwner {
        tokenURIBase = _base;
    }

    function getShareHolderWithdrawableAmount(address _holder)
        external
        view
        returns (uint256)
    {
        return
            ((allTimeBalance / 100) * shares[_holder]) - withdrawals[_holder];
    }

    function withdrawShares() external {
        require(shares[_msgSender()] > 0, "Not a shareholder");
        uint256 withdrawableAmount = this.getShareHolderWithdrawableAmount(
            _msgSender()
        );
        require(withdrawableAmount > 0, "Empty balance");
        withdrawals[_msgSender()] += withdrawableAmount;
        payable(_msgSender()).transfer(withdrawableAmount);
    }
}
