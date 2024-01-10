// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./JuiceboxProject.sol";

pragma solidity 0.8.6;

contract Tiles is JuiceboxProject, ERC721Enumerable {
    using SafeMath for uint256;

    event Mint(address to, address tileAddress);
    event SetBaseURI(string baseURI);

    bool public saleIsActive = false;

    // Limit the total number of reserve Tiles that can be minted by the owner
    uint256 public mintedReservesLimit = 50;
    uint256 public mintedReservesCount = 0;

    // Map Tile addresses to their token ID
    mapping(address => uint256) public idOfAddress;

    // Map token IDs to Tile addresses
    mapping(uint256 => address) public tileAddressOf;

    // Base uri used to retrieve Tile token metadata
    string public baseURI;

    constructor(
        uint256 _projectID,
        ITerminalDirectory _terminalDirectory,
        string memory _baseURI
    ) JuiceboxProject(_projectID, _terminalDirectory) ERC721("Tiles", "TILES") {
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

    // Calculate the current Tile market price based on current supply
    function calculatePrice() public view returns (uint256) {
        require(saleIsActive == true, "Sale hasn't started");

        uint256 currentSupply = totalSupply();

        if (currentSupply >= 102400) {
            return 10240000000000000000; // 102,401 - ∞ : 10.24 ETH
        } else if (currentSupply >= 51200) {
            return 5120000000000000000; // 51,201 - 102,400 : 5.12 ETH
        } else if (currentSupply >= 25600) {
            return 2560000000000000000; // 25,601 - 51,200 : 2.56 ETH
        } else if (currentSupply >= 12800) {
            return 1280000000000000000; // 12,801 - 25,600 : 1.28 ETH
        } else if (currentSupply >= 6400) {
            return 640000000000000000; // 6,401 - 12,800 : 0.64 ETH
        } else if (currentSupply >= 3200) {
            return 320000000000000000; // 3,201 - 6,400 : 0.32 ETH
        } else if (currentSupply >= 1600) {
            return 160000000000000000; // 1,601 - 3,200 : 0.16 ETH
        } else if (currentSupply >= 800) {
            return 80000000000000000; // 801 - 1600 : 0.08 ETH
        } else if (currentSupply >= 400) {
            return 40000000000000000; // 401 - 800 : 0.04 ETH
        } else if (currentSupply >= 200) {
            return 20000000000000000; // 201 - 400 : 0.02 ETH
        } else {
            return 10000000000000000; // 1 - 200 : 0.01 ETH
        }
    }

    // Mint Tile for address `_tileAddress` to `msg.sender`
    function mintTile(address _tileAddress) external payable returns (uint256) {
        require(
            msg.value >= calculatePrice(),
            "Ether value sent is below the price"
        );

        // Take fee into TileDAO Juicebox treasury
        _takeFee(
            msg.value,
            msg.sender,
            string(
                abi.encodePacked(
                    "Minted Tile with address ",
                    toAsciiString(_tileAddress)
                )
            ),
            false
        );

        return _mintTile(msg.sender, _tileAddress);
    }

    // If a wallet owner's matching Tile has been minted already, they may collect it from its current owner by paying the owner the current market price.
    function collectTile() external payable {
        uint256 tokenId = idOfAddress[msg.sender];
        require(tokenId != 0, "Tile for sender address has not been minted");

        address owner = ownerOf(tokenId);
        require(owner != msg.sender, "Sender already owns this Tile");
        require(
            msg.value >= calculatePrice(),
            "Ether value sent is below the price"
        );

        require(payable(owner).send(msg.value));

        _transfer(owner, msg.sender, tokenId);
    }

    function _mintTile(address to, address _tileAddress)
        private
        returns (uint256)
    {
        require(
            idOfAddress[_tileAddress] == 0,
            "Tile already minted for address"
        );

        // Start IDs at 1
        uint256 tokenId = totalSupply() + 1;

        _safeMint(to, tokenId);

        // Map Tile address to token ID
        idOfAddress[_tileAddress] = tokenId;
        // Map token ID to Tile address
        tileAddressOf[tokenId] = _tileAddress;

        emit Mint(to, _tileAddress);

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

    // Reserved for promotional giveaways, and rewards to those who helped inspire or enable Tiles.
    // Owner may mint Tile for `_tileAddress` to `to`
    function mintReserveTile(address to, address _tileAddress)
        external
        onlyOwner
        returns (uint256)
    {
        require(
            mintedReservesCount < mintedReservesLimit,
            "Reserves limit exceeded"
        );

        mintedReservesCount = mintedReservesCount + 1;

        return _mintTile(to, _tileAddress);
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
