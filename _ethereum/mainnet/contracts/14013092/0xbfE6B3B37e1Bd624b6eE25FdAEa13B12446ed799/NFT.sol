// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721URIStorage.sol";
import "./base64.sol";
import "./Render.sol";

interface Protocol {
    function tokenURI(uint256) external view returns (string memory);
}

contract RightClickNFT is ERC721URIStorage {
    address payable private vandal_king;
    address private constant blackhole = 0x0000000000000000000000000000000000000000;
    uint256 private _vandalId;

    event Vandalized(address user, address target, uint256 targetId, uint256 vToken);
    event CleanedUp(address user, uint256 target, uint256 vToken);

    struct vTag {
        address nft;
        string tokenId;
        string tag;
        uint256 status; // 0 - original mint() 1 - burned mint() 2 - switcheeero for original mint() after burn()
        uint256 trait;
    }

    mapping(bytes => bool) public isTagged;
    mapping(uint256 => vTag) public vandal;

    uint256 public initMintPrice;
    Render public svgstorage;

    constructor(address payable creator) ERC721("VandalNeu", "CR") {
        vandal_king = creator;
        initMintPrice = 0.01377 ether;
        svgstorage = new Render();
    }

    function mint(
        address nft,
        uint256 tokenId,
        string memory tag
    ) public payable returns (uint256) {
        bytes memory hashed = abi.encode(nft, tokenId);
        require(!isTagged[hashed], "already defaced");
        require(nft != address(this), "loop deface forbidden");
        require(bytes(tag).length < 30, "tag max len = 30");
        initMintPrice = getCurrentPriceToMint();
        require(msg.value >= initMintPrice, "not enough eth sent");

        isTagged[hashed] = true;
        uint256 vandalId = _vandalId++;

        Protocol vandal_target = Protocol(nft);
        string memory original_uri = vandal_target.tokenURI(tokenId); // copy original uri
        string memory _tokenId = svgstorage.toString(tokenId);

        // trim tokenId length, ie. some tokens can be very long, destroys svg
        if (bytes(_tokenId).length > 30) {
            _tokenId = svgstorage.substring(_tokenId, 0, 30);
        }

        uint256 _vtokenId = uint256(keccak256(hashed)); // totally predictable value.
        vandal[vandalId].nft = nft;
        vandal[vandalId].tokenId = _tokenId;
        vandal[vandalId].tag = tag;
        vandal[vandalId].status = 0;
        vandal[vandalId].trait = randomNum(_vtokenId);

        _safeMint(msg.sender, vandalId);
        _setTokenURI(vandalId, original_uri); // same tokenId as svg

        if (msg.value - initMintPrice > 0) {
            payable(msg.sender).transfer(msg.value - initMintPrice); // excess/padding/buffer
        }

        emit Vandalized(msg.sender, nft, tokenId, vandalId);

        return vandalId;
    }

    function burn(uint256 tokenId, string memory tag) public payable returns (uint256) {
        require(_exists(tokenId), "nothing to clean");
        require(msg.value >= getCurrentPriceToBurn(), "not enough eth");
        require(bytes(tag).length < 30, "tag max len = 30");
        require(vandal[tokenId].status == 0, "already burned");
        initMintPrice = initMintPrice - ((initMintPrice / 1000) * 1); // Tagging gets more popular!

        uint256 _btokenId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))); // generate new tokenId for burn caller
        uint256 vandalId = _vandalId++;

        _safeMint(msg.sender, vandalId);

        // burn (this nft) metadata setting
        vandal[vandalId].nft = vandal[tokenId].nft;
        vandal[vandalId].tokenId = vandal[tokenId].tokenId;
        vandal[vandalId].tag = tag;
        vandal[vandalId].status = 1;
        vandal[vandalId].trait = randomNum(_btokenId);

        // original mint (burned nft) metadata zeroed
        vandal[tokenId].nft = blackhole;
        vandal[tokenId].tokenId = "0";
        vandal[tokenId].tag = tag;
        vandal[tokenId].status = 2;

        payable(ownerOf(tokenId)).transfer(msg.value);

        emit CleanedUp(msg.sender, tokenId, vandalId);

        return vandalId;
    }

    function randomNum(uint256 seed) public pure returns (uint256) {
        return seed % 4;
    }

    function checkIfTagged(address nft, uint256 tokenId) public view returns (bool) {
        bytes memory result = abi.encode(nft, tokenId);
        return isTagged[result];
    }

    function getStatus(uint256 tokenId) public view returns (vTag memory) {
        return vandal[tokenId];
    }

    function getCurrentPriceToMint() public view returns (uint256) {
        return initMintPrice + ((initMintPrice / 1000) * 3); // should grow by 0.3% of current total value after each mint
    }

    function getCurrentPriceToBurn() public view returns (uint256) {
        uint256 baseBurn = getCurrentPriceToMint() * 10;
        return baseBurn + initMintPrice;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory uri) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // copied-nft
        if (vandal[tokenId].status == 0) {
            return super.tokenURI(tokenId);
        }

        // burner-nft burn() caller NFT
        if (vandal[tokenId].status == 1) {
            string memory svg = svgstorage.bodyB(
                ownerOf(tokenId),
                tokenId,
                vandal[tokenId].tag,
                vandal[tokenId].trait,
                vandal[tokenId].nft,
                vandal[tokenId].tokenId
            );
            return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
        }

        // copied-nft transformed by burn call, zeroed data
        if (vandal[tokenId].status == 2) {
            return ftokenURI(tokenId);
        }
    }

    // after burning, output of this function will be the same as tokenURI()
    function ftokenURI(uint256 tokenId) public view returns (string memory) {
        string memory svg = svgstorage.bodyF(
            vandal[tokenId].nft,
            vandal[tokenId].tokenId,
            tokenId,
            ownerOf(tokenId),
            vandal[tokenId].tag,
            vandal[tokenId].trait
        );
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }

    function withdrawETH() public {
        require(msg.sender == vandal_king, "Not allowed");
        vandal_king.transfer(address(this).balance);
    }
}
