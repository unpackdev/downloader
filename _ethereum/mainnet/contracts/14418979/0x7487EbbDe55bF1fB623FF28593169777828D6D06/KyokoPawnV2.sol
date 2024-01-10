// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract KyokoPawnV2 is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 public pawnPrice;
    uint256 public constant MAX_PAWN = 1000;
    uint256 public constant maxPawnPurchase = 10;
    bool public saleIsActive;
    string private _baseURIextended;
    address public multiSign;
    address public applyToken;
    struct INFO {
        address adr;
        uint8 amount;
    }

    mapping(address => uint256) public preSales;

    function initialize(address _multiSign) public initializer {
        __Ownable_init();
        __ERC721_init("Kyoko Pawn", "PAWN");
        multiSign = _multiSign;
    }

    function setPreSales(INFO[] memory _whiteList) public onlyOwner {
        for (uint8 index = 0; index < _whiteList.length; index++) {
            INFO memory _info = _whiteList[index];
            setPreSale(_info.adr, _info.amount);
        }
    }

    function setPreSale(address _adr, uint256 _amount) public onlyOwner {
        preSales[_adr] = _amount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setApplyToken(address _applyToken) external onlyOwner {
        applyToken = _applyToken;
    }

    function setPawnPrice(uint256 _price) external onlyOwner {
        pawnPrice = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function mintPawnForSales(uint256 _number) public payable {
        require(saleIsActive, "Sale must be active to mint Pawn");
        require(
            _number <= maxPawnPurchase,
            "Can only mint 10 tokens at a time"
        );
        require(
            totalSupply().add(_number) <= MAX_PAWN,
            "Purchase would exceed max supply of Pawns"
        );
        uint256 totalCost = pawnPrice.mul(_number);
        IERC20Upgradeable(applyToken).safeTransferFrom(
            msg.sender,
            multiSign,
            totalCost
        );
        for (uint256 i = 0; i < _number; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_PAWN) {
                _mint(msg.sender, mintIndex);
            }
        }
    }

    modifier checkScles() {
        require(preSales[msg.sender] > 0, "You are not on the white list");
        _;
    }

    function mintPawn() public checkScles {
        uint256 _number = preSales[msg.sender];
        for (uint256 i = 0; i < _number; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_PAWN) {
                _mint(msg.sender, mintIndex);
            }
        }
        preSales[msg.sender] = 0;
    }
}
