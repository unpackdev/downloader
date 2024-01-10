// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract ColorThatNFT is ERC1155, Pausable, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;

    // tokenId -> owner
    mapping(uint256 => address) private _owner;

    uint16 public maxTokenPixel = 1000;
    uint16 public maxPositionPerTx = 256;
    uint256 public price = 0.01 ether;

    string public name;
    string public symbol;
    address public fundWallet;

    struct Position {
        uint16 x;
        uint16 y;
    }

    // colorPositions stores position and color data inside bytes32
    // 0x0000000000xxxxyyyyrrggbb
    event ColorUpdated(address indexed colorist, bytes32[] colorPositions);

    modifier inRange(bytes32[] memory colorPositions) {
        for (uint256 i = 0; i < colorPositions.length; i++) {
            (uint16 x, uint16 y, , , ) = decode(colorPositions[i]);
            require(x >= 0 && x < maxTokenPixel, "Pixel out of range");
            require(y >= 0 && y < maxTokenPixel, "Pixel out of range");
        }
        _;
    }

    modifier inRangePosition(uint16 x, uint16 y) {
        require(x >= 0 && x < maxTokenPixel);
        require(y >= 0 && y < maxTokenPixel);
        _;
    }

    constructor(address _fundWallet) ERC1155("") {
        require(_fundWallet != address(0), "Zero address error");
        name = "color that nft - unity";
        symbol = "unity";
        fundWallet = _fundWallet;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // encodes the position and color data inside bytes32
    // 0x0000000000xxxxyyyyrrggbb
    function encode(
        uint16 x,
        uint16 y,
        uint8 r,
        uint8 g,
        uint8 b
    ) external pure returns (bytes32 out) {
        assembly {
            let t := 0
            mstore(0x7, b)
            mstore(0x6, g)
            mstore(0x5, r)
            mstore(0x4, y)
            mstore(0x2, x)
            out := mload(0x7)
        }
    }

    // decodes the position and color data from a bytes32
    // 0x0000000000xxxxyyyyrrggbb
    function decode(bytes32 input)
        internal
        pure
        returns (
            uint16 x,
            uint16 y,
            uint8 r,
            uint8 g,
            uint8 b
        )
    {
        assembly {
            mstore(0x5, input)
            x := mload(0)
            mstore(0x3, input)
            y := mload(0)
            mstore(0x2, input)
            r := mload(0)
            mstore(0x1, input)
            g := mload(0)
            mstore(0x0, input)
            b := mload(0)
        }
    }

    function mint(bytes32[] calldata colorPositions)
        external
        payable
        inRange(colorPositions)
        whenNotPaused
    {
        require(
            msg.value >= price * colorPositions.length,
            "Insufficient funds to mint all pixels"
        );
        require(
            colorPositions.length <= maxPositionPerTx,
            "Too many positions per transaction"
        );
        uint256[] memory ids = new uint256[](colorPositions.length);
        uint256[] memory amounts = new uint256[](colorPositions.length);
        for (uint256 i = 0; i < colorPositions.length; i++) {
            (uint16 x, uint16 y, , , ) = decode(colorPositions[i]);
            uint256 tokenId = _getTokenId(x, y);
            require(_owner[tokenId] == address(0), "Token already minted");
            ids[i] = tokenId;
            amounts[i] = 1;
            _owner[tokenId] = msg.sender;
        }

        _mintBatch(msg.sender, ids, amounts, "");
        emit ColorUpdated(msg.sender, colorPositions);
    }

    function ownerOf(uint256 token) public view returns (address) {
        return _owner[token];
    }

    function ownerOf(Position calldata position)
        external
        view
        inRangePosition(position.x, position.y)
        returns (address)
    {
        return ownerOf(_getTokenId(position.x, position.y));
    }

    function setColor(bytes32[] calldata colorPositions)
        external
        inRange(colorPositions)
        whenNotPaused
    {
        require(
            colorPositions.length <= maxPositionPerTx,
            "Too many colorPositions per transaction"
        );

        for (uint256 i = 0; i < colorPositions.length; i++) {
            (uint16 x, uint16 y, , , ) = decode(colorPositions[i]);
            uint256 tokenId = _getTokenId(x, y);
            require(
                ownerOf(tokenId) == address(0) ||
                    ownerOf(tokenId) == msg.sender,
                "Only the owner can setColor on minted pixel"
            );
        }
        emit ColorUpdated(msg.sender, colorPositions);
    }

    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setFundWallet(address _newFundWallet) public onlyOwner {
        fundWallet = _newFundWallet;
    }

    function setMaxPositionsPerTx(uint16 _newMaxPositionPerTx)
        public
        onlyOwner
    {
        maxPositionPerTx = _newMaxPositionPerTx;
    }

    function setMaxTokenPixel(uint16 _newMaxTokenPixel) public onlyOwner {
        maxTokenPixel = _newMaxTokenPixel;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(fundWallet).send(address(this).balance));
    }

    function _getTokenId(uint16 x, uint16 y) internal view returns (uint256) {
        return x.mul(maxTokenPixel).add(y);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
