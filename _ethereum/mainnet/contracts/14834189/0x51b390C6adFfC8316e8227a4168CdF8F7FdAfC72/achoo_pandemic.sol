// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./ERC721Burnable.sol";
import "./SafeERC20.sol";
import "./Strings.sol";


contract AchooPandemic is ERC1155Supply, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    // Achoo tokens are NFTs with id's 0 to 9999
    uint256 public constant ACHOO_TOKEN_MAX_SUPPLY = 10000;
    uint256 public constant ACHOO_TOKEN_SUPERSPREADER_MAX_SUPPLY = 200;
    uint256 public constant ACHOO_TOKEN_UNIT_PRICE = 0.07 ether;

    // payment related
    uint256 public ACHOO_TOKEN_UNIT_PRICE_WITH_APE = 18 ether;
    uint256 public ACHOO_TOKEN_UNIT_PRICE_WITH_CIG = 203240 ether;

    uint8 private MINT_WITH_TOKEN_ETH_ID = 0;
    uint8 private MINT_WITH_TOKEN_APE_ID = 1;
    uint8 private MINT_WITH_TOKEN_CIG_ID = 2;

    // Sneezes are FTs with id 11111
    uint256 public constant ACHOO_SNEEZE_TOKEN_ID = 11111;

    string private _baseURIExtended;
    bool public _metadataLocked = false;

    // superspreaders have a separate pool of id's
    uint256 private nextAchooSuperspreaderTokenId = 0; // 0-199 are superspreaders
    uint256 private nextAchooTokenId = ACHOO_TOKEN_SUPERSPREADER_MAX_SUPPLY;

    // superspreader related
    bool public superspreaderMintActive = false;
    mapping(address => uint8) private _superspreaderAllowList;

    // sneeze drop related
    uint256 public sneezeDropAvailable = 0;
    uint256 public sneezeDropTokenCount = 0;

    // infected wallets related
    mapping(address => uint16) private _infectedWallets;
    uint16 public _numInfectedWalletsDistinct;

    // ERC20's we interact with (mainnet)
    address public constant ERC20APEContract = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
    address public constant ERC20CIGContract = 0xCB56b52316041A62B6b5D0583DcE4A8AE7a3C629;

    // ERC721's we interact with (mainnet)
    address public constant ERC721AVTKContract = 0x9575F8A18E367d90736A074dB5cACa2760811b93;

    constructor() ERC1155("") {
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(_metadataLocked == false, "Metadata is locked! no updates possible");
        _baseURIExtended = _newBaseURI;
    }

    function uri(uint256 tokenId) public view virtual override(ERC1155) returns (string memory) {
        return bytes(_baseURIExtended).length > 0 ? string(abi.encodePacked(_baseURIExtended, tokenId.toString())) : "";
    }

    function lockMetadata() external onlyOwner {
        _metadataLocked = true;
    }

    function updateTokenUnitPrices(uint256 APEUnitPrice, uint256 CIGUnitPrice) external onlyOwner {
        ACHOO_TOKEN_UNIT_PRICE_WITH_APE = APEUnitPrice;
        ACHOO_TOKEN_UNIT_PRICE_WITH_CIG = CIGUnitPrice;
    }

    function getTokenUnitPrice(uint8 tokenID) public view returns (uint256) {
        if (tokenID == MINT_WITH_TOKEN_ETH_ID) {
            return ACHOO_TOKEN_UNIT_PRICE;
        } else if (tokenID == MINT_WITH_TOKEN_APE_ID) {
            return ACHOO_TOKEN_UNIT_PRICE_WITH_APE;
        } else if (tokenID == MINT_WITH_TOKEN_CIG_ID) {
            return ACHOO_TOKEN_UNIT_PRICE_WITH_CIG;
        }

        return 0;
    }

    function getAchooTotalSupply() public view returns (uint256) {
        return nextAchooSuperspreaderTokenId + (nextAchooTokenId - ACHOO_TOKEN_SUPERSPREADER_MAX_SUPPLY);
    }

    function getAchooSuperspreaderTotalSupply() public view returns (uint256) {
        return nextAchooSuperspreaderTokenId;
    }

    function getAchooRegularTotalSupply() public view returns (uint256) {
        return nextAchooTokenId - ACHOO_TOKEN_SUPERSPREADER_MAX_SUPPLY;
    }

    // superspreader related logic
    function setSuperspreaderMintActive(bool _superspreaderMintActive) external onlyOwner {
        superspreaderMintActive = _superspreaderMintActive;
    }

    function setSuperspreaderAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _superspreaderAllowList[addresses[i]] = numAllowedToMint;
        }
    }

    function getSuperspreaderEligibility() public view returns (uint8) {
        return _superspreaderAllowList[msg.sender];
    }

    function mintSuperspreader(uint8 numberOfTokens, uint8 mintWithTokenID) external payable {
        require(superspreaderMintActive, "Superspreader mint not active");
        require(numberOfTokens <= _superspreaderAllowList[msg.sender], "Exceeded max eligibility to purchase or not whitelisted");
        require(nextAchooSuperspreaderTokenId + numberOfTokens <= ACHOO_TOKEN_SUPERSPREADER_MAX_SUPPLY, "Purchase would exceed max supply");

        if (mintWithTokenID == MINT_WITH_TOKEN_ETH_ID) { // ETH
            require(ACHOO_TOKEN_UNIT_PRICE * numberOfTokens <= msg.value, "Ether value sent is not enough");
        } else if (mintWithTokenID == MINT_WITH_TOKEN_APE_ID) { // APE
            IERC20(ERC20APEContract).safeTransferFrom(msg.sender, address(this), ACHOO_TOKEN_UNIT_PRICE_WITH_APE * numberOfTokens);
        } else if (mintWithTokenID == MINT_WITH_TOKEN_CIG_ID) { // CIG
            IERC20(ERC20CIGContract).safeTransferFrom(msg.sender, address(this), ACHOO_TOKEN_UNIT_PRICE_WITH_CIG * numberOfTokens);
        }

        _superspreaderAllowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintAchooSuperspreaderInternal(msg.sender);
        }
    }

    function mintSuperspreaderWithAVTK(uint8 tokenID) external {
        require(superspreaderMintActive, "Superspreader mint not active");
        require(1 <= _superspreaderAllowList[msg.sender], "Exceeded max eligibility to purchase or not whitelisted");
        require(nextAchooSuperspreaderTokenId + 1 <= ACHOO_TOKEN_SUPERSPREADER_MAX_SUPPLY, "Purchase would exceed max supply");

        ERC721Burnable(ERC721AVTKContract).burn(tokenID);
        _superspreaderAllowList[msg.sender] -= 1;
        _mintAchooSuperspreaderInternal(msg.sender);
    }

    // pandemic mint logic
    function mintWithSneeze(uint8 numberOfTokens, uint8 mintWithTokenID) external payable {
        require(nextAchooTokenId + numberOfTokens <= ACHOO_TOKEN_MAX_SUPPLY, "Purchase would exceed max supply");
        require(balanceOf(msg.sender, ACHOO_SNEEZE_TOKEN_ID) >= numberOfTokens, "Insufficient amount of sneezes");

        if (mintWithTokenID == MINT_WITH_TOKEN_ETH_ID) { // ETH
            require(ACHOO_TOKEN_UNIT_PRICE * numberOfTokens <= msg.value, "Ether value sent is not enough");
        } else if (mintWithTokenID == MINT_WITH_TOKEN_APE_ID) { // APE
            IERC20(ERC20APEContract).safeTransferFrom(msg.sender, address(this), ACHOO_TOKEN_UNIT_PRICE_WITH_APE * numberOfTokens);
        } else if (mintWithTokenID == MINT_WITH_TOKEN_CIG_ID) { // CIG
            IERC20(ERC20CIGContract).safeTransferFrom(msg.sender, address(this), ACHOO_TOKEN_UNIT_PRICE_WITH_CIG * numberOfTokens);
        }

        // burn sneezes from account
        _burn(msg.sender, ACHOO_SNEEZE_TOKEN_ID, numberOfTokens);

        // mint the NFTs
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintAchooInternal(msg.sender);
        }
    }

    function mintWithAVTK(uint8 tokenID) external {
        require(nextAchooTokenId + 1 <= ACHOO_TOKEN_MAX_SUPPLY, "Purchase would exceed max supply");
        require(balanceOf(msg.sender, ACHOO_SNEEZE_TOKEN_ID) >= 1, "Insufficient amount of sneezes");

        ERC721Burnable(ERC721AVTKContract).burn(tokenID);

        // burn sneezes from account
        _burn(msg.sender, ACHOO_SNEEZE_TOKEN_ID, 1);

        _mintAchooInternal(msg.sender);
    }

    function _mintAchooSuperspreaderInternal(address mintTo) internal {
        _mint(mintTo, nextAchooSuperspreaderTokenId, 1, "");
        _mintEligibleSneezes(mintTo, nextAchooSuperspreaderTokenId);
        _infectWallet(msg.sender);
        nextAchooSuperspreaderTokenId += 1;
    }

    function _mintAchooInternal(address mintTo) internal {
        _mint(mintTo, nextAchooTokenId, 1, "");
        _mintEligibleSneezes(mintTo, nextAchooTokenId);
        _infectWallet(msg.sender);
        nextAchooTokenId += 1;
    }

    function _mintEligibleSneezes(address mintTo, uint256 achooTokenId) internal {
        if (achooTokenId >= 0 && achooTokenId < ACHOO_TOKEN_SUPERSPREADER_MAX_SUPPLY) {
            _mint(mintTo, ACHOO_SNEEZE_TOKEN_ID, 10, "");
        }
        else if (achooTokenId >= ACHOO_TOKEN_SUPERSPREADER_MAX_SUPPLY && achooTokenId < 1000) {
            _mint(mintTo, ACHOO_SNEEZE_TOKEN_ID, 5, "");
        }
        else if (achooTokenId >= 1000 && achooTokenId < 3000) {
            _mint(mintTo, ACHOO_SNEEZE_TOKEN_ID, 3, "");
        }
        else if (achooTokenId >= 3000 && achooTokenId < 6000) {
            _mint(mintTo, ACHOO_SNEEZE_TOKEN_ID, 2, "");
        }
        else if (achooTokenId >= 6000 && achooTokenId < 10000) {
            _mint(mintTo, ACHOO_SNEEZE_TOKEN_ID, 1, "");
        }
    }

    // sneeze drop related
    function setSneezeDropAvailable(uint256 _sneezeDropAvailable) external onlyOwner {
        sneezeDropAvailable = _sneezeDropAvailable;
    }

    function mintSneezeDrop() external {
        require(sneezeDropAvailable > 0, "Sneeze drop not active yet");
        require(sneezeDropTokenCount < sneezeDropAvailable, "No available sneeze drop tokens at this time");

        _mint(msg.sender, ACHOO_SNEEZE_TOKEN_ID, 1, "");
        sneezeDropTokenCount += 1;
    }

    // infected wallets logic
    function _infectWallet(address wallet) internal {
        if (_infectedWallets[wallet] > 0) {
            return; // already infected
        }

        _infectedWallets[wallet] += 1;
        _numInfectedWalletsDistinct += 1;
    }

    function getNumInfectedWalletsDistinct() public view returns (uint16) {
        return _numInfectedWalletsDistinct;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        // withdraw ETH
        if(balance > 0) {
            payable(msg.sender).transfer(balance);
        }

        // withdraw APE
        balance = IERC20(ERC20APEContract).balanceOf(address(this));
        if(balance > 0) {
            IERC20(ERC20APEContract).safeTransfer(msg.sender, balance);
        }

        // withdraw CIG
        balance = IERC20(ERC20CIGContract).balanceOf(address(this));
        if(balance > 0) {
            IERC20(ERC20CIGContract).safeTransfer(msg.sender, balance);
        }
    }
}