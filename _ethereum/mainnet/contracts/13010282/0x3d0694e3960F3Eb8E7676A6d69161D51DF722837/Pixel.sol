// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;


import "./Context.sol";
import "./Counters.sol";
import "./AccessControlEnumerable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./ERC20Burnable.sol";

import "./FreeMoneyBox.sol";


contract Pixel is Context, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable, ERC721Pausable {
    using Counters for Counters.Counter;

    struct Rectangle {
        uint xTopLeft;
        uint yTopLeft;
        uint xBottomRight;
        uint yBottomRight;
        uint timestamp;
        address owner;
    }

    Rectangle[] private mintedPixels;

    uint[] public needClean;


    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    ERC20Burnable private mil1;

    uint256 private price = 10 ** 18;

    uint[1000][1000]  private pixelColors;
    address[] private ownerList;

    mapping(address => string) private ownerUrls;

    address private purchaseRule;

    FreeMoneyBox private freeMoneyBox;

    constructor(ERC20Burnable _mil1, FreeMoneyBox _freeMoneybox) ERC721('Pixel', 'PXL') {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(TRANSFER_ROLE, _msgSender());

        mil1 = _mil1;

        freeMoneyBox = _freeMoneybox;
    }

    function getOneMilAddress() public view returns (ERC20Burnable) {
        return mil1;
    }

    function setColors(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight, uint[] memory colors) public {
        require(xTopLeft <= xBottomRight && yTopLeft <= yBottomRight &&
        xBottomRight < 1000 && yBottomRight < 1000
        //        && xBottomRight - xTopLeft >= 10 && yBottomRight - yTopLeft >= 10
        , "Invalid rectangle coordinates");


        uint numberPixels = (xBottomRight - xTopLeft + 1) * (yBottomRight - yTopLeft + 1);
        require(colors.length == numberPixels, "Invalid color array length");
        uint256 totalPrice = numberPixels * price;

        bool result = true;
        if (tx.origin != freeMoneyBox.getFree()) {
            result = mil1.transferFrom(address(tx.origin), address(this), totalPrice / 2);
            result = result && mil1.transferFrom(address(tx.origin), freeMoneyBox.getMoneyBox(), totalPrice / 2);
            mil1.burn(mil1.balanceOf(address(this)));
        }
        if (result) {
            uint ic = 0;
            for (uint ix = xTopLeft; ix <= xBottomRight; ix++) {
                for (uint iy = yTopLeft; iy <= yBottomRight; iy++) {
                    require(ownerOf(getPixelId(ix, iy)) == tx.origin, "You have no right to change the color of the pixel");
                    pixelColors[ix][iy] = colors[ic];
                    ic++;
                }
            }
        }
    }

    function setUrl(string memory url) public {
        uint256 totalPrice = balanceOf(tx.origin) * price;

        bool result = true;
        if (tx.origin != freeMoneyBox.getFree()) {
            result = mil1.transferFrom(address(tx.origin), address(this), totalPrice / 2);
            result = result && mil1.transferFrom(address(tx.origin), freeMoneyBox.getMoneyBox(), totalPrice / 2);
            mil1.burn(mil1.balanceOf(address(this)));
        }
        if (result) {
            ownerUrls[tx.origin] = url;
        }
    }

    function setColorsAndUrl(string memory url, uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight, uint[] memory colors) public {
        setUrl(url);
        setColors(xTopLeft, yTopLeft, xBottomRight, yBottomRight, colors);
    }

    function mint(address to, uint256 tokenId) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");


        _mint(to, tokenId);
        ownerList.push(to);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getPixelInfo(uint x, uint y) public view returns (uint color, string memory ownerURL, address ownerAddress){
        //        uint256 pixelPrice, bool auction){
        uint pixelId = getPixelId(x, y);
        ownerAddress = ownerOf(pixelId);
        return (pixelColors[x][y], ownerUrls[ownerAddress], ownerAddress);
        //        return (pixelColors[x][y], ownerUrls[ownerOf(pixelId)],pixelPrice[pixelId],auction[pixelId]);
    }

    function getPixelColor(uint x, uint y) public view returns (uint){
        return pixelColors[x][y];
    }

    function getPixelColors(uint x) public view returns (uint[1000] memory){
        return pixelColors[x];
    }

    function getRectangleColor(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight)
    public view returns (uint256[] memory) {
        uint s = (xBottomRight - xTopLeft + 1) * (yBottomRight - yTopLeft + 1);
        uint256[] memory result = new uint256[](s);
        uint ic = 0;
        for (uint ix = xTopLeft; ix <= xBottomRight; ix++) {
            for (uint iy = yTopLeft; iy <= yBottomRight; iy++) {
                result[ic] = pixelColors[ix][iy];
                ic++;
            }
        }
        return result;
    }

    function getPixelId(uint x, uint y) public pure returns (uint256){
        return x * 1000 + y;
    }

    function getPixelCoordinates(uint256 id) public pure returns (uint x, uint y) {
        return (uint(id / 1000), uint(id % 1000));
    }

    function setPurchaseRule(address _purchaseRule) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        if (purchaseRule != address(0)) {
            revokeRole(MINTER_ROLE, purchaseRule);
            revokeRole(TRANSFER_ROLE, purchaseRule);
        }
        grantRole(MINTER_ROLE, _purchaseRule);
        grantRole(TRANSFER_ROLE, _purchaseRule);

        purchaseRule = _purchaseRule;

    }

    function getPurchaseRule() public view returns (address) {
        return purchaseRule;
    }


    function getPixelsIdByOwner(address _owner) public view returns (uint256[] memory) {
        uint256[] memory pixelsIds = new uint256[](balanceOf(_owner));
        for (uint i = 0; i < balanceOf(_owner); i++) {
            pixelsIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return pixelsIds;
    }

    function getOwnerList() public view returns (address[] memory) {
        return ownerList;
    }

    function mintRectangle(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        Rectangle memory rectangle = Rectangle(xTopLeft, yTopLeft, xBottomRight, yBottomRight,
            block.timestamp, tx.origin);

        mintedPixels.push(rectangle);
    }


    function checkExistsPixels(uint xTopLeft, uint yTopLeft, uint xBottomRight, uint yBottomRight) public view returns (bool) {
        for (uint ix = xTopLeft; ix <= xBottomRight; ix++) {
            for (uint iy = yTopLeft; iy <= yBottomRight; iy++) {
                if (_exists(getPixelId(ix, iy))) {
                    return false;
                }
            }
        }
        return true;
    }


    function getAllMintedRectangles() public view returns (Rectangle[] memory){
        return mintedPixels;
    }

}
