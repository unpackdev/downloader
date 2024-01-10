// SPDX-License-Identifier: MIT
// written by Goldmember#0001

//                   GGGg
//                   GGGGGG
//    ggggGGGGGGGGGGGGgGGg           gGGGGg
// ggGgggggg        GGGGGgggGGGGGG   GGGGGg
//gGg               gGGGGGg      ggggGGGGG
//gGgG         gg                  gGGGGGGGGGg
//  gGGgGg   ggG                     ggGGg   GggGGg
//     gGGGgggG                                  gggGG
//        gGgg   gGGg                               gGG
//        Gg     gGgg         gGGg                   ggG
//       gg                   gGGGG               Ggg
//      gGG                              gGg gggGGG
//      GGg  gGggGGggggg                  GGggg
//      GGggGGg       Ggg                 ggg
//      GGGG GG         gGg                GGg
//     gGGg            GG  gG                ggG
//      gGG   gGGgGgg      gG                gGG
//       gG   gDRAFFESg  gggg       gggg     GGg
//        GGg  GGGGGGGg   GGg   ggGGg         gGG
//          gGgg           gGggGgGg            ggGG
//             ggGGGGgggggGGGGg                 gGGGg
//                           gGg       GGgGg      ggGG
//                          ggGG      gGGGGgg       gGGg
//                           gGG       GgggG         gGGGgg
//                            Ggg gg                   ggGGGg
//                            gGGggGGGgggGg               gGGGGg
//                            GGGGGGGGGGGGGggg              ggGGGg
//                             gGGGGGGGGGGGGGG                 ggGGGGGGGGGGg
//                             GGGGGGGGGGGGg        g         ggg       ggGGGG
//                               GggggGGggg        ggg                      GgGGg
//                               GG                gGg                       ggGGg
//                              gGg               gg                          ggGG
//                             gGg              GgG    ggg                   GGg
//                             gGg      ggggGGGgggg  ggGGGGGgg                ggGG
//                            gGg     ggGGGGGGGGgg   ggGGGGGG                GGGg
//                            GgGGgG  gGGGGGGGgg       ggGg                 GGG
//                         gGGgggggGGGggGGGGGg                          gGgGGg
//                        gGgggggggggGGgGGGgg                       gGgGGgg
//                        GGGggggggggGGGGGGg          gg         GGgg
//                          ggGGGGgGGGGgg gGg          ggg        GgGg
//                            GGGGGGg     GGg           gg         gGGg
//                                       gGGg           ggg         GgGg
//                                       gGg            GGGg        GgGg
//                                       gGGg           ggGgGgGGGGGGGGGGGg
//                                       gGGGGGGGGGGGGGGGGGGGggggggggggGGG
//                                       GGGgggggggggggggggGGgggggggggggGGG
//                                       gGGggggggggggggggggGGgggggggggGGG
//                                        ggGGGGGG GTHEGARDEN GGGGGGGGgg

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract Draffes is ERC721A, Ownable {

    // collection details
    uint256 public constant ALLOWLISTPRICE = 0.06 ether;
    uint256 public constant PUBLICPRICE = 0.08 ether;
    uint256 public constant MAXSUPPLY = 5000;
    uint256 public constant MAXMINTSPERALLOWLIST = 2;
    uint256 public constant MAXMINTSPERPUBLIC = 5;
    uint256 public constant ALLOWLISTSUPPLY = 3712;

    // splits for funds
    uint256 public constant COMMUNITYSPLIT = 90;
    uint256 public constant DONATIONSPLIT = 10;

    // merkle tree
    bytes32 public merkleRoot = 0x201bf1802fbf7220ccae3cad829138b920e955cc89beede896c0813494576083;

    // variables and constants
    string public baseURI = 'draffes://sorryDetective/';
    bool public isAllowlistMintActive = false;
    bool public isPublicMintActive = false;
    mapping(address => uint256) public allowlistMintsPerAddress;
    mapping(address => uint256) public publicMintsPerAddress;
    uint256 public maxReserveMintRemaining = 20;
    address public communityWallet = 0xA81f5365851A2Fe91EC44aeC48DDc1b4EecCa179;
    address public donationWallet = 0x5aa11eED331Dfcdb03e7df639509d1A2a04a9Ea6;

    constructor() ERC721A("Draffes", "DRAFFE") {

    }

    function publicMint(uint256 _quantity) external payable {
        // active check
        require(isPublicMintActive
        , "DRAFFES: public mint is not active");
        // price check
        require(msg.value == _quantity * PUBLICPRICE
            , "DRAFFES: insufficient amount paid");
        // supply check
        require(_quantity + totalSupply() < MAXSUPPLY
            , "DRAFFES: not enough remaining to mint this many");
        // allowlist max minting check
        require(publicMintsPerAddress[msg.sender] + _quantity <= MAXMINTSPERPUBLIC
            , "DRAFFES: max mints per address exceeded");

        // mint
        publicMintsPerAddress[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function allowlistMint(uint256 _quantity, bytes32[] calldata _merkleProof) external payable {
        // active check
        require(isAllowlistMintActive
            , "DRAFFES: allowlist mint is not active");
        // price check
        require(msg.value == _quantity * ALLOWLISTPRICE
            , "DRAFFES: insufficient amount paid");
        // supply check
        require(_quantity + totalSupply() < MAXSUPPLY
            , "DRAFFES: not enough remaining to mint this many");
        // max reserve mint max supply
        require(_quantity + totalSupply() < ALLOWLISTSUPPLY
            , "DRAFFES: not enough spots in allowlist to mint this many");
        // allowlist max minting check
        require(allowlistMintsPerAddress[msg.sender] + _quantity <= MAXMINTSPERALLOWLIST
            , "DRAFFES: max mints per allowlist exceeded");

        // merkle verification
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, _leaf)
            , "DRAFFES: not in allowlist");

        // mint and update mapping
        allowlistMintsPerAddress[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reservedMint(uint256 _quantity) external onlyOwner {
        // supply check
        require(_quantity + totalSupply() < MAXSUPPLY
            , "DRAFFES: not enough remaining to mint this many");

        // reserve mint
        require(maxReserveMintRemaining >= _quantity
            , "DRAFFES: not enough reserve mints left");

        // mint to community wallet
        _safeMint(communityWallet, _quantity);
        maxReserveMintRemaining -= _quantity;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setCommunityWallet(address _newCommunityWallet) external onlyOwner {
        communityWallet = _newCommunityWallet;
    }

    function setDonationWallet(address _newDonationWallet) external onlyOwner {
        donationWallet = _newDonationWallet;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function toggleAllowlistMint() public onlyOwner {
        isAllowlistMintActive = !isAllowlistMintActive;
    }

    function togglePublicMint() public onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0
            , "DRAFFES: nothing to withdraw");

        uint256 _balance = address(this).balance;

        // community wallet
        (bool communitySuccess, ) = communityWallet.call{
            value: _balance * COMMUNITYSPLIT / 100}("");
        require(communitySuccess
            , "DRAFFES: community withdrawal failed");

        // donation wallet
        (bool donationSuccess, ) = donationWallet.call{
            value: _balance * DONATIONSPLIT / 100}("");
        require(donationSuccess
            , "DRAFFES: donation withdrawal failed");
    }


}
