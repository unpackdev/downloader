// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Base64.sol";

import "./SoulsDescriptor.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Souls is ERC721 {

    address public owner = 0xaF69610ea9ddc95883f97a6a3171d52165b69B03; // for opensea integration. doesn't do anything else.

    address public collector; // address authorised to withdraw funds recipient
    address payable public recipient; // in this instance, it will be a mirror split on mainnet. 0xec0ef86a3872829F3EC40de1b1b9Df54a3D4a4b3

    uint256 public buyableSoulSupply;

    // minting time
    uint256 public startDate;
    uint256 public endDate;

    mapping(uint256 => bool) public soulsType; // true == full soul

    SoulsDescriptor public descriptor;

    ERC721 public anchorCertificates;

    // uint256 public newlyMinted;

    mapping(uint256 => bool) public claimedACIDs;

    event Claim(address indexed claimer, uint256 indexed tokenId);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, address collector_, address payable recipient_, uint256 startDate_, uint256 endDate_, address certificates_) ERC721(name_, symbol_) {
        collector = collector_; 
        recipient = recipient_;
        startDate = startDate_;
        endDate = endDate_;
        descriptor = new SoulsDescriptor();
        anchorCertificates = ERC721(certificates_);

        /* INITIAL CLAIM/MINT */
        // initial claim for un_frontier outside campaign window.
        // allows metadata + graph + storefronts to propagate before launch.
        // let this initial claim come from simondlr's personal collection of anchor certificates.
        // it is default certificate #1.
        // https://opensea.io/assets/0x600a4446094c341693c415e6743567b9bfc8a4a8/86944833354306826451453519009172227432197817959411860297499850535918774474487
        claimedACIDs[86944833354306826451453519009172227432197817959411860297499850535918774474487] = true;
        _createSoul(true,address(0xaF69610ea9ddc95883f97a6a3171d52165b69B03)); // claim the soul for untitled frontier, not simondlr.
        emit Claim(0xaF69610ea9ddc95883f97a6a3171d52165b69B03, 86944833354306826451453519009172227432197817959411860297499850535918774474487);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory soulType = "Sketched";
        if(soulsType[tokenId] == true) {
            soulType = "Fully Painted";
        }

        string memory name = descriptor.generateName(soulType, tokenId); 
        string memory description = "Paintings of forgotten souls by various simulated minds that try to remember those who they once knew in the default world.";

        string memory image = generateBase64Image(tokenId);
        string memory attributes = generateTraits(tokenId);
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,'",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        bytes memory img = bytes(generateImage(tokenId));
        return Base64.encode(img);
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateImage(tokenId, soulsType[tokenId]);
    }

    function generateTraits(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateTraits(tokenId, soulsType[tokenId]);
    }

    /*
    Owners of Anchor Certificates can claim a full soul.
    Max 160.
    */
    function claimSoul(uint ACID) public  {
        require(block.timestamp > startDate, "NOT_STARTED"); // ~ 2000 gas
        require(block.timestamp < endDate, "ENDED");
        require(claimedACIDs[ACID] == false, "AC_ID ALREADY CLAIMED");
        require(anchorCertificates.ownerOf(ACID) == msg.sender, "AC_ID NOT OWNED BY SENDER");

        claimedACIDs[ACID] = true;
        _createSoul(true, msg.sender);
        emit Claim(msg.sender, ACID);
    }

    function mintSoul() public payable {
        require(block.timestamp > startDate, "NOT_STARTED"); // ~ 2000 gas
        require(block.timestamp < endDate, "ENDED");
        require(msg.value >= 0.010 ether, 'MORE ETH NEEDED'); //~$30

        if(msg.value >= 0.068 ether) { //~$200
            buyableSoulSupply += 1;
            require(buyableSoulSupply <= 96, "MAX_SOLD_96");
            _createSoul(true, msg.sender);
        } else { // don't need to check ETH amount here since it is checked in the require above
            _createSoul(false, msg.sender);
        }
    }

    function _createSoul(bool fullSoul, address _owner) internal {
        uint256 tokenId = uint(keccak256(abi.encodePacked(block.timestamp, _owner)));
        soulsType[tokenId] = fullSoul;
        // newlyMinted = tokenId; // tests
        super._mint(_owner, tokenId);
    }

    function withdrawETH() public {
        require(msg.sender == collector, "NOT_COLLECTOR");
        recipient.transfer(address(this).balance);
    }
}