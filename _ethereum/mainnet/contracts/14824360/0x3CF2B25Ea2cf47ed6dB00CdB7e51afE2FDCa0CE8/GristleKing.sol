//                        *
//             ***       ***
//             *****    *** *
//             ** ************
//      *****   * * ******** **
//       ************** ***** *
//        ***** ***** *********
//         ** *** *****
//           ** ***                  ******
//            ***    ***********  *********
//                 ************************
//               **** ******* * ***** *****
//              **** **     ****** *****
//          ***** ** *      ** ****
//        *** **** ********* *** *
//      ******** ********** *** **
//     ***** ********************
//    ** * **     **************
//    **** *       **********
//    * *****
//    **********
//     * ***********
//     * ********** ***************
//   *** ****************************
//  *********************************
// ****** ***************************
// ****** *                *********
// ********              ***********
//  * ********    *****************
//  ****************************
//   ***********************
//
// SPDX-License-Identifier: Unlicense
// @author devberry.eth
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./DAOable.sol";
import "./MerkleProof.sol";

    error TeamMintingDisabled();
    error WhitelistMintingDisabled();
    error PublicMintingDisabled();
    error InvalidEthereumValue();
    error OriginNotSender();
    error QuantityExceedsMaxSupply();
    error InvalidMerkleProof();
    error MintingInProgress();
    error MaximumMintedPerWallet();

contract GristleKing is ERC721A, DAOable {

    using Strings for uint256;

    struct TierConfig {
        bytes32 merkleRoot;
        uint256 price;
    }

    address constant public _gk = 0xD75CbE7FC76b674d8DB4483B9C2D0b1fd729fdD9;
    address constant public _shuffleDAOCore = 0x74aF33bABE251b50e70Fc1d85B7ebf9A0036581A;

    bool teamClaimed = false;

    string public baseURI;

    mapping(uint64 => TierConfig) tierConfigs;

    uint256 public mintingTier; // 0 = Disabled // 1 = Team // 2 = Team + WL // 3 = Everyone //

    uint256 constant maxSupply = 749;

    constructor() ERC721A("G-Units", "UNIT"){}

    function teamMint() external onlyPartner {
        if (teamClaimed == true) revert TeamMintingDisabled();
        teamClaimed = true;
        _mint(_gk, 15);
        _mint(dao(), 5);
    }

    function whitelistMint(uint64 quantity, bytes32[] calldata merkleProof) external payable {
        if (mintingTier < 2) revert WhitelistMintingDisabled();
        TierConfig memory config = tierConfigs[2];
        if (!MerkleProof.verify(merkleProof, config.merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert InvalidMerkleProof();
        internalMint(config,quantity);
    }

    function publicMint(uint64 quantity) external payable {
        if (mintingTier < 3) revert PublicMintingDisabled();
        internalMint(tierConfigs[3],quantity);
    }

    function internalMint(TierConfig memory _config, uint64 quantity) internal {
        if (tx.origin != msg.sender) revert OriginNotSender();
        if (_totalMinted() + quantity > maxSupply) revert QuantityExceedsMaxSupply();
        if (_numberMinted(msg.sender) >= 2) revert MaximumMintedPerWallet();
        if (msg.value < _config.price * quantity) revert InvalidEthereumValue();
        _mint(msg.sender, quantity);
    }

    function setTierConfig(uint64 _tier, bytes32 _merkleRoot, uint256 _price) external onlyPartner {
        tierConfigs[_tier] = TierConfig(_merkleRoot,_price);
    }

    function setMintingTier(uint64 _tier) external onlyPartner {
        mintingTier = _tier;
    }

    function setBaseURI(string memory __baseURI) external onlyPartner {
        baseURI = __baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function numberMinted(address owner) external view returns (uint256){
        return _numberMinted(owner);
    }

    function withdraw() external onlyPartner {

        uint256 ten = address(this).balance/10;

        (bool successTeam,) = address(dao()).call{
        value : ten*2
        }("");
        if (!successTeam) revert("Failed");

        (bool successCore,) = _shuffleDAOCore.call{
        value : ten
        }("");
        if (!successCore) revert("Failed");

        (bool successOwner,) = _gk.call{
        value : address(this).balance
        }("");
        if (!successOwner) revert("Failed");
    }

    function withdrawFallback() external onlyOwner {
        (bool successTeam,) = address(dao()).call{
        value : address(this).balance
        }("");
        if (!successTeam) revert("Failed");
    }

}
