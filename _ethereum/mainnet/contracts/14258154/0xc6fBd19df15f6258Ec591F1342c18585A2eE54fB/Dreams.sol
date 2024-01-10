// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./JuiceboxProject.sol";
import "./Tiles.sol";

pragma solidity 0.8.6;

contract Dreams is JuiceboxProject, ERC721Enumerable {
    event Mint(address to, uint256 id, address tileAddress);
    event SetBaseURI(string baseURI);

    bool public saleIsActive = false;

    // Map Tile addresses of Dreams to their token ID
    mapping(address => uint256) public idOfAddress;

    // Map Dream token IDs to Tile addresses
    mapping(uint256 => address) public tileAddressOf;

    // Base uri used to retrieve Tile token metadata
    string public baseURI;

    // Tiles contract
    Tiles public immutable tiles;

    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant PRICE = 2e16; // 0.02 ETH

    constructor(
        uint256 _projectID,
        ITerminalDirectory _terminalDirectory,
        Tiles _tiles,
        string memory _baseURI
    )
        JuiceboxProject(_projectID, _terminalDirectory)
        ERC721("Dreams", "DREAMS")
    {
        tiles = _tiles;
        baseURI = _baseURI;
    }

    // Get URI used to retrieve metadata for Tile with ID `tokenID`
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        toAsciiString(tileAddressOf[tokenId])
                    ) // Convert address to string before encoding
                )
                : "";
    }

    // Get IDs for all tokens owned by `_owner`
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Mint Dream for `tileAddress` to `msg.sender`
    function mint(address tileAddress) external payable returns (uint256) {
        require(saleIsActive, "Sale has not started");
        require(totalSupply() < MAX_SUPPLY, "All dreams have been minted.");
        require(idOfAddress[tileAddress] == 0, "Tile has already been dreamt");
        require(
            tiles.ownerOf(tiles.idOfAddress(tileAddress)) == msg.sender,
            "Sender does not own this Tile."
        );
        require(msg.value >= PRICE, "Ether value sent is below the price");

        // Take fee into Juicebox treasury
        _takeFee(
            msg.value,
            msg.sender,
            string(
                abi.encodePacked("Dreamt of Tile ", toAsciiString(tileAddress))
            ),
            false
        );

        // Start IDs at 1
        uint256 tokenId = totalSupply() + 1;
        // Map Tile address to token ID
        idOfAddress[tileAddress] = tokenId;
        // Map token ID to Tile address
        tileAddressOf[tokenId] = tileAddress;

        _safeMint(msg.sender, tokenId);

        emit Mint(msg.sender, tokenId, tileAddress);

        return tokenId;
    }

    //
    // Owner functions
    //

    function startSale() external onlyOwner {
        require(saleIsActive == false, "Sale is already active");
        saleIsActive = true;
    }

    function pauseSale() external onlyOwner {
        require(saleIsActive == true, "Sale is already inactive");
        saleIsActive = false;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
