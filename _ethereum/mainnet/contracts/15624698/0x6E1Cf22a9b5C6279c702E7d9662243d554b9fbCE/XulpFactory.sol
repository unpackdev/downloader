// SPDX-License-Identifier: CONSTANTLY WANTS TO MAKE THE WORLD BEAUTIFUL

// ██   ██ ██    ██ ██      ██████  ████████ ██    ██ ██████  ███████ ███████
//  ██ ██  ██    ██ ██      ██   ██    ██    ██    ██ ██   ██ ██      ██
//   ███   ██    ██ ██      ██████     ██    ██    ██ ██████  █████   ███████
//  ██ ██  ██    ██ ██      ██         ██    ██    ██ ██   ██ ██           ██
// ██   ██  ██████  ███████ ██         ██     ██████  ██   ██ ███████ ███████

// A NEW MEMBER OF ARTGLIXXX EGOSYSTEM, ALGORITHMICALLY GENERATED VOXEL SCULPTURES
// GLICPIXXXVER002 ASSETS ARE USED AS RAW MATERIAL WHILST MAKING THESE SEXY XULPTURES
// https://glicpixxx.love/
// https://artglixxx.io/
// by @berkozdemir

pragma solidity ^0.8.0;
import "./ERC721AQueryable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";

interface IGLIX {
    function burn(address from, uint256 amount) external returns (bool);
}

contract XulpFactory is ERC721AQueryable, Ownable, ERC2981 {
    bool saleState;
    address private GLIXTOKEN_ADDRESS = 0x4e09d18baa1dA0b396d1A48803956FAc01c28E88; // mainnet
    uint256 maxMintPerTx;
    uint256 totalXulps;
    uint256 glixPrice;
    string private _baseTokenURI;

    constructor() ERC721A("XULPTURES", "XULPTURES") {
        _safeMint(msg.sender, 1);
        _setDefaultRoyalty(0xe49381184A49CD2A48e4b09a979524e672Fdd10E, 500); // glicpixyz.eth
        editSale(1500 ether, 128, 5);
        _baseTokenURI = "https://artglixxx.io/api/xulptures/";
    }

    function flipSaleState() public onlyOwner {
        saleState = !saleState;
    }

    function setRoyalty(address _address, uint96 _royalty) external onlyOwner {
        _setDefaultRoyalty(_address, _royalty);
    }

    function mint(address _to, uint256 _amount) external {
        require(saleState, "SALE ISN'T OPEN FREN");
        require(_amount <= maxMintPerTx, "CAN ONLY MINT 5 AT ONCE");
        require(totalSupply() + _amount <= totalXulps, "MINTED OUT");
        require(IGLIX(GLIXTOKEN_ADDRESS).burn(msg.sender, glixPrice * _amount));
        _safeMint(_to, _amount);
    }

    function mintAdmin(address[] calldata _to, uint256 _amount)
        public
        onlyOwner
    {
        for (uint256 i; i < _to.length; i++) {
            _safeMint(_to[i], _amount);
        }
    }

    // THIS FUNCTION IS WRITTEN TO DROP NEW ITERATIONS IN THE SAME CONTRACT.
    function editSale(
        uint256 price,
        uint256 supply,
        uint256 _maxMintPerTx
    ) public onlyOwner {
        glixPrice = price;
        totalXulps = supply;
        maxMintPerTx = _maxMintPerTx;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Set the base token URI
     */
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
