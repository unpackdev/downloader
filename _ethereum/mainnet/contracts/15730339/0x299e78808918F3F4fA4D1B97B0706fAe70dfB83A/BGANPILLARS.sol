// SPDX-License-Identifier: CONSTANTLY WANTS TO MAKE THE WORLD BEAUTIFUL

// ██   ██ ██    ██ ██████  ███████ ██████      ██████   ██████   █████  ███    ██     ██████  ██ ██      ██       █████  ██████  ███████ 
// ██   ██  ██  ██  ██   ██ ██      ██   ██     ██   ██ ██       ██   ██ ████   ██     ██   ██ ██ ██      ██      ██   ██ ██   ██ ██      
// ███████   ████   ██████  █████   ██   ██     ██████  ██   ███ ███████ ██ ██  ██     ██████  ██ ██      ██      ███████ ██████  ███████ 
// ██   ██    ██    ██      ██      ██   ██     ██   ██ ██    ██ ██   ██ ██  ██ ██     ██      ██ ██      ██      ██   ██ ██   ██      ██ 
// ██   ██    ██    ██      ███████ ██████      ██████   ██████  ██   ██ ██   ████     ██      ██ ███████ ███████ ██   ██ ██   ██ ███████ 

// VOXEL PILLARS FOR HYPED AF BASTARD GAN PUNKS V2
// https://bastardganpunks.club/
// https://artglixxx.io/
// by @berkozdemir aka princess camel aka guerrilla pimp minion bastard
// https://berkozdemir.com

pragma solidity ^0.8.0;
import "./ERC721AQueryable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";

interface ISTHISBASTARDHYPEDAF {

    function isThisBastardHypedAF(uint256 _bastardId) external view returns (bool);

    function isThisBastardHypedAF_BATCH(uint256[] memory _bastardIds) external view returns (bool[] memory);

}

contract BGANPILLARSFACTORY is ERC721AQueryable, Ownable {

    ISTHISBASTARDHYPEDAF BGANHYPE = ISTHISBASTARDHYPEDAF(0xA44dE1E10Ad532c33f7aA6CbFC256A615c7164F9);
    IERC721 BGAN = IERC721(0x31385d3520bCED94f77AaE104b406994D8F2168C);

    bool mintOpen;

    string private _baseTokenURI;

    mapping (uint => bool) public isClaimed;
    mapping (uint => uint) public idToBGAN;

    event claimed(uint counter, uint id);
    constructor() ERC721A("BGAN PILLARS", "BGANPILLAR") {
        _baseTokenURI = "https://artglixxx.io/api/bganpillars/";
    }

    function flipMintState() public onlyOwner {
        mintOpen = !mintOpen;
    }

    function getWhichBGAN(uint _id) external view returns(uint256) {
        return idToBGAN[_id / 2];
    }
    function mint(address _to, uint256[] calldata _bgans) external {
        require(mintOpen, "MINTING ISN'T OPEN FREN");
        bool[] memory isHyped = BGANHYPE.isThisBastardHypedAF_BATCH(_bgans);
        uint start = totalSupply() / 2;
        for (uint i = 0; i < _bgans.length; i++) {
            require(isHyped[i], "NOT HYPED");
            uint bgan = _bgans[i];
            require(!isClaimed[bgan], "ALREADY CLAIMED");
            isClaimed[bgan] = true;
            require(BGAN.ownerOf(bgan) == msg.sender, "NOT OWNER");
            idToBGAN[start + i] = bgan;
            emit claimed(start + i, bgan);
        }
        _safeMint(_to, _bgans.length * 2);
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

}
