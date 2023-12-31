// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                     //
//                                                                                                                     //
//      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""     //
//      """"""""""""""""""""""""""""""""/////***(/**/(//)/(/)//**////(""""""""""""""""""""""""""""""""""""""""""""     //
//      """"""""""""""""""""""""""////***,,,.#%%%%%%##((////@@@***,**///(/((((""""""""""""""""""""""""""""""""""""     //
//      """"""""""""""""""""(//////%&%%%%&&%%%%%%%####%%#######%#####@$@#@##////((""""""""""""""""""""""""""""""""     //
//      """"""""""""""""""///(/&%&%%%%&&%%%%%%%####%%#######%##############((///(//(//""""""""""""""""""""""""""""     //
//      """"""""""""""""(((((%%&%&%%%##%&&&&%%%%%%%%%#&&&%%###################%###((////(/#"""""""""""""""""""""""     //
//      """""""""""""/(##%%##%%&%&%%%%##%%%%#%%#&&&%%######%################&%%###&%%######////"""""""""""""""""""     //
//      """"""""""(((#%%%%%&%%%#%%###%##%&&&&%%###%##%#####%###############%%########%#(((((((/(/(""""""""""""""""     //
//      """"""""((#%%%%%&&%%####%%&&&#(%%%%##%&&&&%%%%%%%%&&&&&&%%%###%##%%%%%%%%#%%%##%&&&&%%%(((//("""""""""""""     //
//      """"""(((%%%%&&%%%%%&&&&%%###%##%&&&&%%###%##%#####%###%%%%%%%&&&&&&&&%%%%%%%%%###%%#####(((((//""""""""""     //
//      """""((%&&&&&&%%%%&&%%%%##%%%%#%%#&&&%%##%%%%%&&&&&&&#%%%%%%%%%%%%%#%%%%%%%&&&%&%%&&&%%######((//,""""""""     //
//      """/(%%%%%%&%%%%%&%&&%%%%%%%%%%%%%####%%%%%#########%%%%%%%%%%&&&&%%%%%%%%&&&&&&&&&&&&&%%%#%%%%%#(/"""""""     //
//      ""/(#%%%&&&%%%&&&&&%%&&%%%%%%%########%%#%%%%%%%%%%%%%%%%%%&&&&&&%%%%&&&%%%%%&&&&&&&%%%%%%%#%%%%%(/"""""""     //
//      ""(#%&&&&&&&&&&&&&&&%%%%%%%%%%##%%%%%%%%#######%%%%%%%&&&&&&&&&&%%%%%&&&&&&&&&&&&&&%%&%###%%#####((/""""""     //
//      ""(#%%%%%%&&%%&&&%%#%&&%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%%%%%%%%%%%%&&&&&%%%%%%%####%%&&%%%%%%##%%%%%##(""""""     //
//      "/(#%&&%%&&%%%%%%%%%&&&&&&&%&%%##(/////////////////((((((#####%%%%%%##((////@@@@*(#%%%%%%%%##%%%%%#(""""""     //
//      ""/#%&%%%%%&&&&&&&&&%%###((////%"""""""""""""""""""""""""""%%%//*%""""""""""""""""""#%%%%&%%%%%%%#(/""""""     //
//      "\\#%%%%%%%&&&&&%#(//"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""(%&%&&&%%(//""""""     //
//      "//%@""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" */#%&&%#//"""""""     //
//      "\\#%@""RRRRRRRRRRRRRRRRR"""UUUUUUUU"""""UUUUUUUU""""""""GGGGGGGGGGGGGDDDDDDDDDDDDD""""""*/#%&&%#//"""""""     //
//      """"#$""R::::::::::::::::R""U::::::U"""""U::::::U"""""GGG::::::::::::GD::::::::::::DDD"""@*/#%#(/&""""""""     //
//      """"""""R::::::RRRRRR:::::R"U::::::U"""""U::::::U"""GG:::::::::::::::GD:::::::::::::::DD"""@*/((*"""""""""     //
//      """"""""RR:::::R"""""R:::::RUU:::::U"""""U:::::UU""G:::::GGGGGGGG::::GDDD:::::DDDDD:::::D"""@*/&**""""""""     //
//      """"""""""R::::R"""""R:::::R"U:::::U"""""U:::::U""G:::::G"""""""GGGGGG""D:::::D""""D:::::D"""""/""""""""""     //
//      """"""""""R::::R"""""R:::::R"U:::::D"""""D:::::U"G:::::G""""""""""""""""D:::::D"""""D:::::D"""""""""""""""     //
//      """"""""""R::::RRRRRR:::::R""U:::::D"""""D:::::U"G:::::G""""""""""""""""D:::::D"""""D:::::D"""""""""""""""     //
//      """"""""""R:::::::::::::RR"""U:::::D"""""D:::::U"G:::::G""""GGGGGGGGGG""D:::::D"""""D:::::D"""""""""""""""     //
//      """"""""""R::::RRRRRR:::::R""U:::::D"""""D:::::U"G:::::G""""G::::::::G""D:::::D"""""D:::::D"""""""""""""""     //
//      """"""""""R::::R"""""R:::::R"U:::::D"""""D:::::U"G:::::G""""GGGGG::::G""D:::::D"""""D:::::D"""""""""""""""     //
//      """"""""""R::::R"""""R:::::R"U:::::D"""""D:::::U"G:::::G""""""""G::::G""D:::::D"""""D:::::D"""""""""""""""     //
//      """"""""""R::::R"""""R:::::R"U::::::U"""U::::::U""G:::::G"""""""G::::G""D:::::D""""D:::::D""""""""""""""""     //
//      """"""""RR:::::R"""""R:::::R"U:::::::UUU:::::::U"""G:::::GGGGGGGG::::GDDD:::::DDDDD:::::D"""""""""""""""""     //
//      """"""""R::::::R"""""R:::::R""UU:::::::::::::UU"""""GG:::::::::::::::GD:::::::::::::::DD""""""""""""""""""     //
//      """"""""R::::::R"""""R:::::R""""UU:::::::::UU"""""""""GGG::::::GGG:::GD::::::::::::DDD""""""""""""""""""""     //
//      """"""""RRRRRRRR"""""RRRRRRR""""""UUUUUUUUU""""""""""""""GGGGGG"""GGGGDDDDDDDDDDDDD"""""""""""""""""""""""     //
//      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""     //
//      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""     //
//      """"""""""""""""""""""""                  "_"_"_"_____"_____"                     """"""""""""""""""""""""     //
//                                                |"|"|"|_"""_|"""__|                                                  //
//                                                |"|"|"|"|"|"|"""__|                                                  //
//                                                |_____|"|_|"|__|"""                                                  //
//                                                                                                                     //
//                                                """""""""""""""""""                                                  //
//                                  """""""""""""""""_""""""""""""""""""""""""""""                                     //
//                                  """"""""""""""""|"|__""_""_"""""""""""""""""""                                     //
//                                  """"""""""""""""|"'_"\|"||"|""""""""""""""""""                                     //
//                                  """"""""""""""""|_.__/"\_,"|""""""""""""""""""                                     //
//                                  ""___""""""""""""""""_"|__/"""_"""""""""_"""""                                     //
//                                  "|"""\""___"""_"__""(_)"_"_""(_)"_"__""(_)"___                                     //
//                                  "|"|)"|/"-_)"|"'""\"|"||"'"\"|"||"'""\"|"|(_-<                                     //
//                                  "|___/"\___|"|_|_|_||_||_||_||_||_|_|_||_|/__/                                     //
//                                  """"""""""""""""""""""""""""""""""""""""""""""                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./Strings.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

contract RUGD_V2 is
    ERC721AUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    uint256 public maxSupply;
    uint256 public premintSupply;
    uint256 public maxMint;
    uint256 public price;
    bool public isSaleOn;
    bool public revealStatus;
    address public teamWallet;

    string private realBaseURI;
    string private virtualURI;

    mapping(address => uint256) public qtyMintedPerUser;

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    // - `initializer` for OpenZeppelin's `OwnableUpgradeable`.
    function initialize(
        address _teamWallet
    ) public initializerERC721A initializer {
        maxMint = 3;
        maxSupply = 4444;
        premintSupply = 444;
        realBaseURI = "https://bafybeibb2psr2is7jzeolp6mmz3xsiojmlkxzi3ez6wuhi2xwfkt5zdire.ipfs.nftstorage.link/";
        virtualURI = "https://bafybeibb2psr2is7jzeolp6mmz3xsiojmlkxzi3ez6wuhi2xwfkt5zdire.ipfs.nftstorage.link/";
        revealStatus = false;
        isSaleOn = true;
        teamWallet = _teamWallet;
        price = 0;
        __ERC721A_init("RUGD.WTF - Vol 1", "RUGD");
        __Ownable_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
        _mint(teamWallet, premintSupply);
        qtyMintedPerUser[teamWallet] += premintSupply;
    }

    function sale(uint256 quantity) external payable nonReentrant {
        require(totalSupply() + quantity <= maxSupply, "Exceed Max Supply");
        require(isSaleOn, "Sale is NOT on");
        require(
            qtyMintedPerUser[msg.sender] + quantity <= maxMint,
            "Max wallet exceeded"
        );
        uint mintPrice = 0;
        if (qtyMintedPerUser[msg.sender] == 0) {
            mintPrice = price * (quantity - 1);
        } else {
            mintPrice = price * quantity;
        }
        require(msg.value >= mintPrice, "Insufficient price");
        qtyMintedPerUser[msg.sender] += quantity;
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    function adminMint(address wallet, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _mint(wallet, quantity);
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setUri(
        string memory _newUri,
        string memory _virtualUri
    ) external onlyOwner {
        realBaseURI = _newUri;
        virtualURI = _virtualUri;
    }

    function setRevealStatus(bool _status) public onlyOwner {
        revealStatus = _status;
    }

    function startSale() external onlyOwner {
        require(!isSaleOn, "Can't start");
        isSaleOn = true;
    }

    function stopSale() external onlyOwner {
        require(isSaleOn, "Sale is not on");
        isSaleOn = false;
    }

    function withdraw(address payable _wallet) external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "No funds");
        _wallet.transfer(bal);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return
            string(
                abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json")
            );
    }

    function _baseURI() internal view override returns (string memory) {
        if (revealStatus) {
            return realBaseURI;
        } else {
            return virtualURI;
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
