// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

import "./ERC721A.sol";
import "./NFTEventsAndErrors.sol";
import "./Base64.sol";
import "./IERC2981.sol";
import "./IERC721.sol";
import "./Utils.sol";
import "./Constants.sol";
import "./ColorfulArt.sol";
import "./LibString.sol";
import "./AllowList.sol";

/// @title Together NFT
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice Together is an onchain NFT where the art of each token builds on the art of all previous tokens.
contract Together is ColorfulArt, ERC721A, NFTEventsAndErrors, Constants, AllowList {
  using LibString for uint256;

  bool public publicMintEnabled;
  uint16 internal immutable _allowListMintMaxTotal;
  uint8 internal immutable _allowListMintMaxPerWallet;
  mapping(address user => uint8 minted) internal _allowListMinted;

  address private _xxyyzzAddress;

  constructor(
    address xxyyzzAddress,
    bytes32 allowListMerkleRoot,
    uint16 allowListMintMaxTotalVal,
    uint8 allowListMintMaxPerWalletVal
  ) AllowList(allowListMerkleRoot) ERC721A("Together", "TGR") {
    _xxyyzzAddress = xxyyzzAddress;
    _allowListMintMaxTotal = allowListMintMaxTotalVal;
    _allowListMintMaxPerWallet = allowListMintMaxPerWalletVal;
  }

  // Commence

  /// @notice Update public mint enabled.
  function updatePublicMintEnabled(bool _publicMintEnabled) external onlyOwner {
    publicMintEnabled = _publicMintEnabled;
  }

  function commence() external onlyOwner {
    // Checks

    // Check if already commenced
    if (commenced) {
      revert AlreadyCommenced();
    }

    // Effects

    // Update commenced to be true
    commenced = true;

    // Mint initial tokens
    _coreMint(msg.sender, _MINT_AMOUNT_DURING_COMMENCE);
  }

  // Mint

  function _coreMint(address to, uint8 amount) internal {
    // Checks
    if (!commenced) {
      // Check mint has started
      revert MintNotStarted();
    }

    uint256 nextTokenIdToBeMinted = _nextTokenId();

    unchecked {
      if (MAX_POINTS_TOTAL + 1 < nextTokenIdToBeMinted + amount) {
        // Check max supply not exceeded
        revert MaxSupplyReached();
      }
    }

    // Effects

    // Set colors
    unchecked {
      for (uint256 i = nextTokenIdToBeMinted; i < nextTokenIdToBeMinted + amount; ) {
        tokenToColor[i] = Utils.getPackedRGBColor(keccak256(abi.encodePacked(block.prevrandao, i)));
        ++i;
      }
    }

    // Perform mint
    _mint(to, amount);
  }

  /// @notice Mint tokens for allowlist minters.
  /// @param proof proof
  /// @param amount amount of tokens to mint
  function mintAllowList(bytes32[] calldata proof, uint8 amount) external payable onlyAllowListed(proof) {
    // Checks

    unchecked {
      if (amount * PRICE != msg.value) {
        // Check payment by sender is correct
        revert IncorrectPayment();
      }

      if (_totalMinted() + amount > _allowListMintMaxTotal) {
        // Check allowlist mint total is not exceeding max allowed to be minted during allowlist phase
        revert AllowListMintCapExceeded();
      }

      if (_allowListMinted[msg.sender] + amount > _allowListMintMaxPerWallet) {
        // Check wallet is not exceeding max allowed during allowlist phase
        revert AllowListMintCapPerWalletExceeded();
      }
    }

    // Effects

    // Increase allowlist minted by amount
    unchecked {
      _allowListMinted[msg.sender] += amount;
    }

    // Perform mint
    _coreMint(msg.sender, amount);
  }

  /// @notice Mint tokens.
  /// @param amount amount of tokens to mint
  function mintPublic(uint8 amount) external payable {
    // Checks
    if (!publicMintEnabled) {
      // Check public mint enabled
      revert PublicMintNotEnabled();
    }

    if (amount > _MAX_PUBLIC_MINT_AMOUNT_PER_TRANSACTION) {
      revert PublicMintMaxPerTransactionExceeded();
    }

    unchecked {
      if (amount * PRICE != msg.value) {
        // Check payment by sender is correct
        revert IncorrectPayment();
      }
    }

    // Effects

    _coreMint(msg.sender, amount);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  // Withdraw

  /// @notice Withdraw all ETH from the contract to the vault.
  function withdraw() external {
    (bool success, ) = _VAULT_ADDRESS.call{ value: address(this).balance }("");
    require(success);
  }

  // Metadata

  /// @notice Set the background color of your token.
  /// @param tokenId Together token id
  /// @param xxyyzzTokenId XXYYZZ token id (this will be what your Together
  /// token's background color is set to)
  function colorBackground(uint256 tokenId, uint24 xxyyzzTokenId) external {
    // Checks
    if (ownerOf(tokenId) != msg.sender) {
      // Revert if msg.sender does not own this token
      revert MsgSenderNotTokenOwner();
    }
    if (
      // Background color can always be reset to black
      xxyyzzTokenId != 0 &&
      // For any other color, check if msg.sender owns that xxyyzz token
      IERC721(_xxyyzzAddress).ownerOf(xxyyzzTokenId) != msg.sender
    ) {
      // Revert if msg.sender is not owner of the input xxyyzz token
      revert MsgSenderDoesNotOwnXXYYZZToken();
    }

    // Effects
    // Update token background to xxyyzz token color
    tokenToBackgroundColor[tokenId] = xxyyzzTokenId;

    emit MetadataUpdate(tokenId);
  }

  function _getTraits(uint256 tokenId) internal view returns (string memory) {
    unchecked {
      uint256 innerShapePoints = tokenId % MAX_POINTS_PER_POLYGON;
      return
        string.concat(
          "[",
          Utils.getTrait("Total Points", tokenId.toString(), true, true),
          Utils.getTrait("Depth", (tokenId / MAX_POINTS_PER_POLYGON).toString(), true, true),
          Utils.getTrait(
            "Inner Shape Points",
            (innerShapePoints > 0 ? innerShapePoints : MAX_POINTS_PER_POLYGON).toString(),
            true,
            true
          ),
          Utils.getTrait("New Line Color", Utils.getRGBStr(tokenToColor[tokenId]), false, true),
          Utils.getTrait("Background Color", Utils.getRGBStr(tokenToBackgroundColor[tokenId]), false, false),
          "]"
        );
    }
  }

  /// @notice Get token uri for a particular token.
  /// @param tokenId token id
  /// @return tokenURI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) {
      revert URIQueryForNonexistentToken();
    }

    string memory artSvg = art(uint16(tokenId));

    return
      Utils.formatTokenURI(
        tokenId,
        Utils.svgToURI(artSvg),
        string.concat(
          "data:text/html;base64,",
          Utils.encodeBase64(
            bytes(
              string.concat(
                '<html style="overflow:hidden"><body style="margin:0">',
                artSvg,
                '<script>let a=!1,b=!1,o=Array.from(document.getElementsByTagName("line")).map(e=>e.style.stroke),s=e=>new Promise(t=>setTimeout(t,e)),c=()=>Math.floor(256*Math.random());document.body.addEventListener("click",async()=>{if(!a||b)return;b=!0;let e=document.getElementsByTagName("line");for(;a;){for(let t=0;t<e.length;t++)e[t].style.stroke=`rgb(${c()},${c()},${c()})`;await s(50)}for(let l=0;l<e.length;l++)e[l].style.stroke=o[l];b=!1},!0),document.body.addEventListener("click",async()=>{if(a)return;a=!0;let e=document.getElementsByTagName("line");for(let t=0;t<2*e.length;t++){let l=t<e.length?"0":"1",n=t<e.length?t:2*e.length-t-1;"m"!==e[n].id&&(e[n].style.strokeOpacity=l);let g=e.length%100;await s((t<e.length?t>=e.length-g:t>e.length&&t-e.length<=g)?20+(100-g)/100*75:10)}a=!1},!0);</script></body></html>'
              )
            )
          )
        ),
        _getTraits(tokenId)
      );
  }

  // Royalties

  function royaltyInfo(uint256, uint256 salePrice) external pure returns (address receiver, uint256 royaltyAmount) {
    unchecked {
      return (_VAULT_ADDRESS, (salePrice * 250) / 10_000);
    }
  }

  // IERC165

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }
}
